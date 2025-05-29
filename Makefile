# --- Common Configuration ---
VERILOG_TOP_MODULE ?= demoman
VERILOG_TOP_MODULE_FILE ?= synthesis/$(strip $(VERILOG_TOP_MODULE)).v

SIM_DIR            ?= simulation
RTL_DIR            ?= rtl
BUILD_DIR          ?= build

# --- C++ Source Files (Modular) ---
SIM_CONFIG_HEADER       := $(SIM_DIR)/SimConfig.h
DUT_CONTROLLER_CPP      := $(SIM_DIR)/DutController.cpp
DUT_CONTROLLER_HEADER   := $(SIM_DIR)/DutController.h
SDL_VIDEO_CPP           := $(SIM_DIR)/SdlVideo.cpp
SDL_VIDEO_HEADER        := $(SIM_DIR)/SdlVideo.h
INPUT_HANDLER_CPP       := $(SIM_DIR)/InputHandler.cpp
INPUT_HANDLER_HEADER    := $(SIM_DIR)/InputHandler.h

# All custom C++ source files (application logic)
APP_CPP_SOURCES  := $(DUT_CONTROLLER_CPP) $(SDL_VIDEO_CPP) $(INPUT_HANDLER_CPP)
APP_HEADERS      := $(SIM_CONFIG_HEADER) $(DUT_CONTROLLER_HEADER) $(SDL_VIDEO_HEADER) $(INPUT_HANDLER_HEADER)

SIM_MAIN_NATIVE  := $(SIM_DIR)/sim_main_native.cpp
SIM_MAIN_WASM    := $(SIM_DIR)/sim_main_wasm.cpp

# Find all .v files in RTL_DIR and its subdirectories, and add the top module file
VERILOG_SOURCES    := $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*/*.v $(RTL_DIR)/*/*/*.v) $(VERILOG_TOP_MODULE_FILE)

# --- Verilator Configuration ---
VERILATOR          ?= verilator
VERILATOR_ROOT     := $(shell $(VERILATOR) --getenv VERILATOR_ROOT 2>/dev/null)

ifeq ($(strip $(VERILATOR_ROOT)),)
    $(error VERILATOR_ROOT not found. Please ensure Verilator is in your PATH or set VERILATOR_ROOT manually.)
endif

VERILATOR_INCLUDE_PATH := $(VERILATOR_ROOT)/include
VERILATED_CPP_FILE     := $(VERILATOR_INCLUDE_PATH)/verilated.cpp
VERILATED_OPT_FAST_CPP := $(VERILATOR_INCLUDE_PATH)/verilated_opt_fast.cpp
VERILATED_TRACED_CPP   := $(VERILATOR_INCLUDE_PATH)/verilated_vcd_c.cpp
VERILATED_COVERAGE_CPP := $(VERILATOR_INCLUDE_PATH)/verilated_cov.cpp

# Check for essential Verilator include files
ifeq ($(wildcard $(VERILATOR_INCLUDE_PATH)/verilated.h),)
    $(error Cannot find verilated.h in '$(VERILATOR_INCLUDE_PATH)'. Please check Verilator installation.)
endif
ifeq ($(wildcard $(VERILATED_CPP_FILE)),)
    $(error Cannot find verilated.cpp in '$(VERILATOR_INCLUDE_PATH)'. Required for Wasm build. Check Verilator installation.)
endif
$(info Found Verilator include path: $(VERILATOR_INCLUDE_PATH))

# Common Verilator flags
VERILATOR_FLAGS_COMMON  ?= -Wall --top-module $(strip $(VERILOG_TOP_MODULE)) -Wno-fatal

# --- WebAssembly (Wasm) Target Configuration ---
BUILD_DIR_WASM          := $(BUILD_DIR)/wasm
OBJ_DIR_VERILATED_WASM  := $(BUILD_DIR_WASM)/obj_verilated_$(strip $(VERILOG_TOP_MODULE))
HTML_SHELL_FILE         ?= $(SIM_DIR)/index.html

VERILATOR_FLAGS_WASM    := $(VERILATOR_FLAGS_COMMON) --cc --prefix V$(strip $(VERILOG_TOP_MODULE)) --Mdir $(OBJ_DIR_VERILATED_WASM)

EMCC                    ?= em++
EMCC_COMMON_FLAGS       ?= -std=c++17 -O3 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s WARN_ON_UNDEFINED_SYMBOLS=0 \
							-DVL_TIME_CONTEXT -DVL_TIME_CONTEXT_INACTION_NOTHING \
							-sASYNCIFY -sUSE_SDL=2 -DVL_CPU_RELAX\(\)=
EMCC_INCLUDE_FLAGS_WASM ?= -I$(VERILATOR_INCLUDE_PATH) -I$(OBJ_DIR_VERILATED_WASM) -I$(SIM_DIR)
EMCC_LINK_FLAGS_WASM    := # Specific link flags can be added here

# Add shell file if it exists
EMCC_SHELL_FILE_FLAG := $(if $(wildcard $(HTML_SHELL_FILE)),--shell-file $(HTML_SHELL_FILE),)

TARGET_HTML        := $(BUILD_DIR_WASM)/index.html

# --- Native Target Configuration ---
BUILD_DIR_NATIVE   := $(BUILD_DIR)/native
OBJ_DIR_NATIVE     := $(BUILD_DIR_NATIVE)/obj_dir_$(strip $(VERILOG_TOP_MODULE))
EXECUTABLE_NATIVE  := $(OBJ_DIR_NATIVE)/V$(strip $(VERILOG_TOP_MODULE)) # Verilator default executable name

CXX_NATIVE         ?= g++ # Or clang++
SDL2_CFLAGS        := $(shell sdl2-config --cflags)
SDL2_LIBS          := $(shell sdl2-config --libs)

CXXFLAGS_NATIVE    ?= -std=c++17 -O3 $(SDL2_CFLAGS) -I$(VERILATOR_INCLUDE_PATH) -I$(SIM_DIR)
LDFLAGS_NATIVE     ?= $(SDL2_LIBS)

VERILATOR_FLAGS_NATIVE := $(VERILATOR_FLAGS_COMMON) --cc --build --exe --Mdir $(OBJ_DIR_NATIVE) --prefix V$(strip $(VERILOG_TOP_MODULE)) -j 0 -O3 --x-assign fast --x-initial fast --noassert

# --- Targets ---
.PHONY: all wasm run_wasm clean_wasm verilate_wasm native run_native clean_native clean help test_vars

all: native wasm

# --- Wasm Targets ---
VERILATE_SENTINEL_WASM := $(OBJ_DIR_VERILATED_WASM)/.verilated_done_wasm

# Rule to run Verilator for Wasm (generates C++ from Verilog but doesn't compile with Emscripten)
$(VERILATE_SENTINEL_WASM): $(VERILOG_SOURCES)
	@mkdir -p $(OBJ_DIR_VERILATED_WASM)
	@echo "🚀 Running Verilator for Wasm on $(VERILOG_TOP_MODULE)..."
	$(VERILATOR) $(VERILATOR_FLAGS_WASM) $(VERILOG_SOURCES)
	@touch $@
	@echo "✅ Wasm Verilation complete. C++ files in $(OBJ_DIR_VERILATED_WASM)"

verilate_wasm: $(VERILATE_SENTINEL_WASM)

# Rule to compile all C++ sources into Wasm using Emscripten
$(TARGET_HTML): $(SIM_MAIN_WASM) $(APP_CPP_SOURCES) $(APP_HEADERS) $(VERILATE_SENTINEL_WASM) $(VERILATED_CPP_FILE) $(HTML_SHELL_FILE)
	@mkdir -p $(BUILD_DIR_WASM)
	@echo "📦 Building Wasm target: $(TARGET_HTML)..."
	$(EMCC) $(EMCC_COMMON_FLAGS) $(EMCC_INCLUDE_FLAGS_WASM) \
		$(SIM_MAIN_WASM) $(APP_CPP_SOURCES) \
		$(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(strip $(VERILOG_TOP_MODULE))__*.cpp) \
		$(OBJ_DIR_VERILATED_WASM)/V$(strip $(VERILOG_TOP_MODULE)).cpp \
		$(VERILATED_CPP_FILE) \
		$(EMCC_LINK_FLAGS_WASM) $(EMCC_SHELL_FILE_FLAG) \
		-o $@
	@echo "🎉 WebAssembly build complete: $(TARGET_HTML)"
	$(if $(EMCC_SHELL_FILE_FLAG),,@echo "ℹ️ Note: Default Emscripten HTML shell was used.")

wasm: $(TARGET_HTML)

run_wasm: wasm
	@echo "📡 Starting web server for Wasm target in $(BUILD_DIR_WASM)..."
	@echo "👉 Open http://localhost:8000/$(notdir $(TARGET_HTML)) in your browser."
	@cd $(BUILD_DIR_WASM) && python3 -m http.server 8000 || \
	(echo "Python 3 http.server failed, trying Python 2 SimpleHTTPServer..." && \
	cd $(BUILD_DIR_WASM) && python -m SimpleHTTPServer 8000)

clean_wasm:
	@echo "🧹 Cleaning Wasm build artifacts..."
	rm -rf $(BUILD_DIR_WASM) $(OBJ_DIR_VERILATED_WASM)
	@echo "✨ Wasm clean complete."

# --- Native Targets ---
# Verilator's --build --exe handles compilation and linking of all C++ sources.
$(EXECUTABLE_NATIVE): $(VERILOG_SOURCES) $(SIM_MAIN_NATIVE) $(APP_CPP_SOURCES) $(APP_HEADERS)
	@mkdir -p $(OBJ_DIR_NATIVE) # Ensure Mdir exists
	@echo "🚀 Running Verilator and compiling Native executable for $(VERILOG_TOP_MODULE)..."
	$(VERILATOR) $(VERILATOR_FLAGS_NATIVE) \
		$(VERILOG_SOURCES) \
		$(SIM_MAIN_NATIVE) $(APP_CPP_SOURCES) \
		-CFLAGS "$(CXXFLAGS_NATIVE)" \
		-LDFLAGS "$(LDFLAGS_NATIVE)"
	@echo "✅ Native executable built: $@"

native: $(EXECUTABLE_NATIVE)

run_native: native
	@echo "👟 Running native executable $(EXECUTABLE_NATIVE)..."
	$(EXECUTABLE_NATIVE)

clean_native:
	@echo "🧹 Cleaning Native build artifacts..."
	rm -rf $(BUILD_DIR_NATIVE) $(OBJ_DIR_NATIVE) # Verilator creates obj_dir inside Mdir
	@echo "✨ Native clean complete."

# --- Common Targets ---
clean: clean_wasm clean_native
	@echo "🧼 All build artifacts cleaned."

help:
	@echo "Makefile for Verilator Simulation (Native & Wasm)"
	@echo "--------------------------------------------------"
	@echo "Usage: make [target]"
	@echo ""
	@echo "Main Targets:"
	@echo "  all             Build both Native and Wasm targets."
	@echo "  native          Build the Native executable."
	@echo "  wasm            Build the WebAssembly target."
	@echo ""
	@echo "Run Targets:"
	@echo "  run_native      Build (if needed) and run the Native executable."
	@echo "  run_wasm        Build (if needed) and run the Wasm target (starts a local web server)."
	@echo ""
	@echo "Clean Targets:"
	@echo "  clean           Clean all build artifacts for both Native and Wasm."
	@echo "  clean_native    Clean Native build artifacts."
	@echo "  clean_wasm      Clean Wasm build artifacts."
	@echo ""
	@echo "Development Targets:"
	@echo "  verilate_wasm   Only run Verilator for Wasm (generates C++ from Verilog)."
	@echo "  help            Show this help message."
	@echo "  test_vars       Show values of some key Makefile variables for debugging."
	@echo ""
	@echo "Configuration Variables (can be overridden on the command line, e.g., make VERILOG_TOP_MODULE=my_top):"
	@echo "  VERILOG_TOP_MODULE      (current: $(VERILOG_TOP_MODULE))"
	@echo "  VERILATOR_ROOT          (current: $(VERILATOR_ROOT))"
	@echo "  SIM_DIR                 (current: $(SIM_DIR))"
	@echo "  RTL_DIR                 (current: $(RTL_DIR))"
	@echo "  BUILD_DIR               (current: $(BUILD_DIR))"
	@echo "  CXX_NATIVE              (current: $(CXX_NATIVE))"
	@echo "  EMCC                    (current: $(EMCC))"

test_vars:
	@echo "--- Makefile Variable Test ---"
	@echo "VERILOG_TOP_MODULE:       $(VERILOG_TOP_MODULE)"
	@echo "VERILOG_SOURCES:          $(VERILOG_SOURCES)"
	@echo "APP_CPP_SOURCES:          $(APP_CPP_SOURCES)"
	@echo "VERILATOR_ROOT:           $(VERILATOR_ROOT)"
	@echo "VERILATOR_INCLUDE_PATH:   $(VERILATOR_INCLUDE_PATH)"
	@echo "VERILATED_CPP_FILE:       $(VERILATED_CPP_FILE)"
	@echo "CXXFLAGS_NATIVE:          $(CXXFLAGS_NATIVE)"
	@echo "LDFLAGS_NATIVE:           $(LDFLAGS_NATIVE)"
	@echo "EMCC_COMMON_FLAGS:        $(EMCC_COMMON_FLAGS)"
	@echo "EMCC_INCLUDE_FLAGS_WASM:  $(EMCC_INCLUDE_FLAGS_WASM)"
	@echo "EXECUTABLE_NATIVE:        $(EXECUTABLE_NATIVE)"
	@echo "TARGET_HTML:              $(TARGET_HTML)"