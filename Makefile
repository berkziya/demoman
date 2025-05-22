# --- Common Configuration ---
VERILOG_TOP_MODULE ?= demoman
# Adjust if your top Verilog module file is named differently or located elsewhere
VERILOG_TOP_MODULE_FILE ?= synthesis/$(VERILOG_TOP_MODULE).v

SIM_DIR            ?= simulation
RTL_DIR            ?= rtl

# Find all .v files in RTL_DIR and its subdirectories, and add the top module file
VERILOG_SOURCES    := $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*/*.v $(RTL_DIR)/*/*/*.v) $(VERILOG_TOP_MODULE_FILE)

# Verilator (common path, specific flags per target)
VERILATOR          ?= verilator

# --- Attempt to find Verilator root and include files (used by Wasm and Native CXXFLAGS) ---
VERILATOR_ROOT_ENV := $(shell $(VERILATOR) --getenv VERILATOR_ROOT 2>/dev/null)

ifeq ($(VERILATOR_ROOT_ENV),)
    $(warning VERILATOR_ROOT not found via '$(VERILATOR) --getenv VERILATOR_ROOT' or it returned empty. Please ensure Verilator is in your PATH or set VERILATOR_ROOT_PATH manually.)
    $(warning Attempting to use common default include paths for verilated.h and verilated.cpp.)
    # Try to set VERILATOR_INCLUDE_PATH if VERILATOR_ROOT_ENV is empty
    # Check common Homebrew path first
    _TRY_INCLUDE_PATH := /opt/homebrew/share/verilator/include
    ifeq ($(wildcard $(_TRY_INCLUDE_PATH)/verilated.h),)
        _TRY_INCLUDE_PATH := /usr/local/share/verilator/include
    endif
    ifeq ($(wildcard $(_TRY_INCLUDE_PATH)/verilated.h),)
        _TRY_INCLUDE_PATH := /usr/share/verilator/include
    endif
    VERILATOR_INCLUDE_PATH ?= $(_TRY_INCLUDE_PATH)
    VERILATED_CPP_FILE     ?= $(VERILATOR_INCLUDE_PATH)/verilated.cpp
else
    VERILATOR_INCLUDE_PATH := $(VERILATOR_ROOT_ENV)/include
    VERILATED_CPP_FILE     := $(VERILATOR_ROOT_ENV)/include/verilated.cpp
endif

# Check if critical Verilator files exist
ifeq ($(wildcard $(VERILATOR_INCLUDE_PATH)/verilated.h),)
    $(error Cannot find verilated.h. Looked in '$(VERILATOR_INCLUDE_PATH)'. Please check Verilator installation or set VERILATOR_INCLUDE_PATH manually.)
endif
# This warning helps confirm if verilated.cpp is found at the global parsing stage
ifeq ($(wildcard $(VERILATED_CPP_FILE)),)
    $(warning Initial Check: Cannot find verilated.cpp. Looked in '$(VERILATED_CPP_FILE)'. This is okay for native builds if Verilator manages it, but required for Wasm. Set VERILATED_CPP_FILE if needed for Wasm.)
else
    $(info Initial Check: Found verilated.cpp at '$(VERILATED_CPP_FILE)')
endif


# --- WebAssembly (Wasm) Target Configuration ---
BUILD_DIR_WASM     ?= build_wasm
OBJ_DIR_VERILATED_WASM := $(BUILD_DIR_WASM)/obj_verilated_wasm
SIM_MAIN_WASM      := $(SIM_DIR)/sim_main_wasm.cpp
HTML_SHELL_FILE    := $(SIM_DIR)/index.html
VERILATOR_EMSCRIPTEN_FIXES_H := $(SIM_DIR)/verilator_emscripten_fixes.h

VERILATOR_FLAGS_WASM ?= -Wall --cc --prefix V$(VERILOG_TOP_MODULE) --Mdir $(OBJ_DIR_VERILATED_WASM) -Wno-fatal --top-module $(VERILOG_TOP_MODULE)

EMCC               ?= em++
EMCC_COMMON_FLAGS  ?= -O2 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s MINIFY_HTML=0 -s WARN_ON_UNDEFINED_SYMBOLS=0 -D'VL_CPU_RELAX()=' -std=c++17
# Include the fixes header if it exists
ifeq ($(wildcard $(VERILATOR_EMSCRIPTEN_FIXES_H)),)
    $(warning $(VERILATOR_EMSCRIPTEN_FIXES_H) not found. If needed, create it.)
else
    EMCC_COMMON_FLAGS += -include $(VERILATOR_EMSCRIPTEN_FIXES_H)
endif
EMCC_INCLUDE_FLAGS_WASM ?= -I$(VERILATOR_INCLUDE_PATH) -I$(OBJ_DIR_VERILATED_WASM)
EMCC_LINK_FLAGS_WASM ?= -s USE_SDL=2 --shell-file $(HTML_SHELL_FILE)

TARGET_HTML        := $(BUILD_DIR_WASM)/index.html
TARGET_JS_WASM     := $(BUILD_DIR_WASM)/index.js
TARGET_WASM_FILE   := $(BUILD_DIR_WASM)/index.wasm

# --- Native Target Configuration ---
BUILD_DIR_NATIVE   ?= build_native
OBJ_DIR_NATIVE     := $(BUILD_DIR_NATIVE)/obj_dir_$(strip $(VERILOG_TOP_MODULE))
SIM_MAIN_NATIVE    := $(SIM_DIR)/sim_main_native.cpp
EXECUTABLE_NATIVE  := $(OBJ_DIR_NATIVE)/V$(strip $(VERILOG_TOP_MODULE))

CXX_NATIVE         ?= g++
CXXFLAGS_NATIVE    ?= -std=c++17 `sdl2-config --cflags` -I$(VERILATOR_INCLUDE_PATH)
LDFLAGS_NATIVE     ?= `sdl2-config --libs`

VERILATOR_FLAGS_NATIVE ?= --cc --exe --build -j 0 --timing --top-module $(strip $(VERILOG_TOP_MODULE))

# --- Targets ---
.PHONY: all wasm run_wasm clean_wasm verilate_wasm native run_native clean_native clean help test_vars test_wildcard

all: wasm native # Default: build both Wasm and Native targets

# --- Wasm Targets ---
VERILATE_SENTINEL_WASM := $(OBJ_DIR_VERILATED_WASM)/.verilated_done

$(VERILATE_SENTINEL_WASM): $(VERILOG_SOURCES)
	@mkdir -p $(OBJ_DIR_VERILATED_WASM)
	@echo "Running Verilator for Wasm on $(VERILOG_TOP_MODULE)..."
	$(VERILATOR) $(VERILATOR_FLAGS_WASM) $(VERILOG_SOURCES)
	@touch $(VERILATE_SENTINEL_WASM)
	@echo "Wasm Verilation complete. C++ files generated in $(OBJ_DIR_VERILATED_WASM)"

verilate_wasm: $(VERILATE_SENTINEL_WASM)

$(TARGET_HTML): $(SIM_MAIN_WASM) $(VERILATE_SENTINEL_WASM) $(VERILATED_CPP_FILE) $(HTML_SHELL_FILE) $(VERILATOR_EMSCRIPTEN_FIXES_H)
	@echo "--- Inside $(TARGET_HTML) rule ---"
	@echo "VERILATED_CPP_FILE (inside rule): '$(VERILATED_CPP_FILE)'"
	@echo "Wildcard result for VERILATED_CPP_FILE (inside rule): '$(wildcard $(VERILATED_CPP_FILE))'"
ifeq ($(wildcard $(VERILATED_CPP_FILE)),)
    $(error Rule Check: Cannot find verilated.cpp at '$(VERILATED_CPP_FILE)'. Required for Wasm build. Please set VERILATED_CPP_FILE or check Verilator installation.)
else
	@echo "Rule Check: Found verilated.cpp at '$(VERILATED_CPP_FILE)' for Emscripten compilation."
	@mkdir -p $(BUILD_DIR_WASM)
	@echo "Compiling Wasm with Emscripten..."
	$(EMCC) $(EMCC_COMMON_FLAGS) $(EMCC_INCLUDE_FLAGS_WASM) \
		$(SIM_MAIN_WASM) \
		$(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE)__*.cpp) \
		$(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE).cpp \
		$(VERILATED_CPP_FILE) \
		$(EMCC_LINK_FLAGS_WASM) \
		-o $(TARGET_HTML)
	@echo "WebAssembly build complete."
	@echo "Main HTML:   $(TARGET_HTML)"
	@echo "JS file:     $(TARGET_JS_WASM)"
	@echo "Wasm file:   $(TARGET_WASM_FILE)"
	@echo "To run, use 'make run_wasm' or open $(TARGET_HTML) via a local web server from the '$(BUILD_DIR_WASM)' directory."
endif
	@echo "--- Exiting $(TARGET_HTML) rule ---"

wasm: $(TARGET_HTML)

run_wasm: wasm
	@echo "Starting web server in $(BUILD_DIR_WASM)..."
	@echo "Open http://localhost:8000 in your browser (usually from the root of your project, and navigate to $(BUILD_DIR_WASM)/index.html)."
	@echo "Or, more reliably: cd $(BUILD_DIR_WASM) && python3 -m http.server 8000"
	cd $(BUILD_DIR_WASM) && python3 -m http.server 8000 || (cd $(BUILD_DIR_WASM) && python -m SimpleHTTPServer 8000)

clean_wasm:
	@echo "Cleaning Wasm build artifacts..."
	rm -rf $(BUILD_DIR_WASM)
	@echo "Wasm clean complete."

# --- Native Targets ---
$(EXECUTABLE_NATIVE): $(VERILOG_SOURCES) $(SIM_MAIN_NATIVE)
	@mkdir -p $(OBJ_DIR_NATIVE) # Verilator needs Mdir to exist
	@echo "Running Verilator and compiling Native executable for $(VERILOG_TOP_MODULE)..."
	$(VERILATOR) \
		$(VERILATOR_FLAGS_NATIVE) \
		--Mdir $(OBJ_DIR_NATIVE) \
		--prefix V$(strip $(VERILOG_TOP_MODULE)) \
		$(VERILOG_SOURCES) \
		--exe $(SIM_MAIN_NATIVE) \
		-CFLAGS "$(CXXFLAGS_NATIVE)" \
		-LDFLAGS "$(LDFLAGS_NATIVE)"
	@echo "Native executable built: $(EXECUTABLE_NATIVE)"
	# Ensure the executable has execute permissions
	chmod +x $(EXECUTABLE_NATIVE)

native: $(EXECUTABLE_NATIVE)

run_native: native
	@echo "Running native executable $(EXECUTABLE_NATIVE)..."
	./$(EXECUTABLE_NATIVE)

clean_native:
	@echo "Cleaning Native build artifacts..."
	rm -rf $(BUILD_DIR_NATIVE) # OBJ_DIR_NATIVE is inside BUILD_DIR_NATIVE
	@echo "Native clean complete."

# --- Common Targets ---
clean: clean_wasm clean_native
	@echo "All clean complete."

help:
	@echo "Unified Makefile for Verilator + Emscripten (Wasm) AND Native SDL Simulation"
	# ... (rest of help message remains the same) ...
	@echo ""
	@echo "Configuration Variables (can be overridden on the command line):"
	@echo "  VERILOG_TOP_MODULE      (default: $(VERILOG_TOP_MODULE))"
	@echo "  VERILOG_TOP_MODULE_FILE (default: $(VERILOG_TOP_MODULE_FILE))"
	@echo "  SIM_DIR                 (default: $(SIM_DIR))"
	@echo "  RTL_DIR                 (default: $(RTL_DIR))"
	@echo "  VERILATOR               (default: $(VERILATOR))"
	@echo ""
	@echo "  Wasm Specific:"
	@echo "    BUILD_DIR_WASM          (default: $(BUILD_DIR_WASM))"
	@echo "    SIM_MAIN_WASM           (default: $(SIM_MAIN_WASM))"
	@echo "    EMCC                    (default: $(EMCC))"
	@echo ""
	@echo "  Native Specific:"
	@echo "    BUILD_DIR_NATIVE        (default: $(BUILD_DIR_NATIVE))"
	@echo "    SIM_MAIN_NATIVE         (default: $(SIM_MAIN_NATIVE))"
	@echo "    EXECUTABLE_NATIVE       (current: '$(EXECUTABLE_NATIVE)')"
	@echo "    CXX_NATIVE              (default: $(CXX_NATIVE))"
	@echo ""
	@echo "  Verilator Paths (auto-detected, can be overridden if detection fails):"
	@echo "    VERILATOR_ROOT_ENV      (raw from shell: '$(VERILATOR_ROOT_ENV)')"
	@echo "    VERILATOR_INCLUDE_PATH  (used: '$(VERILATOR_INCLUDE_PATH)')"
	@echo "    VERILATED_CPP_FILE      (used: '$(VERILATED_CPP_FILE)') (Required for Wasm build)"
	@echo ""
