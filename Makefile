# --- Common Configuration ---
VERILOG_TOP_MODULE ?= demoman
# Adjust if your top Verilog module file is named differently or located elsewhere
VERILOG_TOP_MODULE_FILE ?= synthesis/$(VERILOG_TOP_MODULE).v

SIM_DIR            ?= simulation
RTL_DIR            ?= rtl

# Font file configuration
FONT_FILE          ?= $(SIM_DIR)/Roboto_Condensed-Regular.ttf
FONT_FILE_BASENAME ?= $(notdir $(FONT_FILE))

# Find all .v files in RTL_DIR and its subdirectories, and add the top module file
VERILOG_SOURCES    := $(wildcard $(RTL_DIR)/*.v $(RTL_DIR)/*/*.v $(RTL_DIR)/*/*/*.v) $(VERILOG_TOP_MODULE_FILE)

# Verilator (common path, specific flags per target)
VERILATOR          ?= verilator

# --- Attempt to find Verilator root and include files (used by Wasm and Native CXXFLAGS) ---
VERILATOR_ROOT_ENV := $(shell $(VERILATOR) --getenv VERILATOR_ROOT 2>/dev/null)

ifeq ($(VERILATOR_ROOT_ENV),)
    $(warning VERILATOR_ROOT not found via '$(VERILATOR) --getenv VERILATOR_ROOT' or it returned empty. Please ensure Verilator is in your PATH or set VERILATOR_ROOT_PATH manually.)
    $(warning Attempting to use common default include paths for verilated.h and verilated.cpp.)
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

ifeq ($(wildcard $(VERILATOR_INCLUDE_PATH)/verilated.h),)
    $(error Cannot find verilated.h. Looked in '$(VERILATOR_INCLUDE_PATH)'. Please check Verilator installation or set VERILATOR_INCLUDE_PATH manually.)
endif
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

VERILATOR_FLAGS_WASM ?= -Wall --cc --prefix V$(VERILOG_TOP_MODULE) --Mdir $(OBJ_DIR_VERILATED_WASM) -Wno-fatal --top-module $(VERILOG_TOP_MODULE) --debug

EMCC               ?= em++
EMCC_COMMON_FLAGS  ?= -O2 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s MINIFY_HTML=0 -s WARN_ON_UNDEFINED_SYMBOLS=0 -D'VL_CPU_RELAX()=' -std=c++17
EMCC_INCLUDE_FLAGS_WASM ?= -I$(VERILATOR_INCLUDE_PATH) -I$(OBJ_DIR_VERILATED_WASM)
EMCC_LINK_FLAGS_WASM ?= -s USE_SDL=2 -s USE_SDL_TTF=2 --shell-file $(HTML_SHELL_FILE)
ifeq ($(wildcard $(FONT_FILE)),)
    $(warning Font file '$(FONT_FILE)' not found. Wasm build might fail to preload it or app might fail to load it.)
else
    EMCC_LINK_FLAGS_WASM += --preload-file $(FONT_FILE)@$(FONT_FILE_BASENAME)
endif


TARGET_HTML        := $(BUILD_DIR_WASM)/index.html
TARGET_JS_WASM     := $(BUILD_DIR_WASM)/index.js
TARGET_WASM_FILE   := $(BUILD_DIR_WASM)/index.wasm

# --- Native Target Configuration ---
BUILD_DIR_NATIVE   ?= build_native
OBJ_DIR_NATIVE     := $(BUILD_DIR_NATIVE)/obj_dir_$(strip $(VERILOG_TOP_MODULE))
SIM_MAIN_NATIVE    := $(SIM_DIR)/sim_main_native.cpp
EXECUTABLE_NATIVE  := $(OBJ_DIR_NATIVE)/V$(strip $(VERILOG_TOP_MODULE))

CXX_NATIVE         ?= g++
SDL2_CFLAGS := $(shell sdl2-config --cflags)
SDL2_LIBS   := $(shell sdl2-config --libs)
SDL2_TTF_CFLAGS := $(shell pkg-config SDL2_ttf --cflags)
SDL2_TTF_LIBS   := $(shell pkg-config SDL2_ttf --libs)

ifeq ($(strip $(SDL2_TTF_CFLAGS)),)
    $(warning WARNING: 'pkg-config SDL2_ttf --cflags' returned empty for native build. Check SDL2_ttf installation and pkg-config setup.)
endif
ifeq ($(strip $(SDL2_TTF_LIBS)),)
    $(warning WARNING: 'pkg-config SDL2_ttf --libs' returned empty for native build. Check SDL2_ttf installation and pkg-config setup.)
endif

CXXFLAGS_NATIVE    ?= -std=c++17 $(SDL2_CFLAGS) $(SDL2_TTF_CFLAGS) -I$(VERILATOR_INCLUDE_PATH)
LDFLAGS_NATIVE     ?= $(SDL2_LIBS) $(SDL2_TTF_LIBS)

VERILATOR_FLAGS_NATIVE ?= --cc --exe --build -j 0 --timing --top-module $(strip $(VERILOG_TOP_MODULE))

# --- Targets ---
.PHONY: all wasm run_wasm clean_wasm verilate_wasm native run_native clean_native clean help test_vars test_wildcard

all: wasm native

# --- Wasm Targets ---
VERILATE_SENTINEL_WASM := $(OBJ_DIR_VERILATED_WASM)/.verilated_done

$(VERILATE_SENTINEL_WASM): $(VERILOG_SOURCES)
	@mkdir -p $(OBJ_DIR_VERILATED_WASM)
	@echo "Running Verilator for Wasm on $(VERILOG_TOP_MODULE)... (with VERILATOR_FLAGS_WASM = $(VERILATOR_FLAGS_WASM))"
	$(VERILATOR) $(VERILATOR_FLAGS_WASM) $(VERILOG_SOURCES)
	@touch $(VERILATE_SENTINEL_WASM)
	@echo "Wasm Verilation complete. C++ files generated in $(OBJ_DIR_VERILATED_WASM)"

verilate_wasm: $(VERILATE_SENTINEL_WASM)

$(TARGET_HTML): $(SIM_MAIN_WASM) $(VERILATE_SENTINEL_WASM) $(VERILATED_CPP_FILE) $(HTML_SHELL_FILE) $(FONT_FILE)
	@echo "--- Inside $(TARGET_HTML) rule ---"
	@echo "VERILATED_CPP_FILE (inside rule): '$(VERILATED_CPP_FILE)'"
	@echo "Wildcard result for VERILATED_CPP_FILE (inside rule): '$(wildcard $(VERILATED_CPP_FILE))'"
ifeq ($(wildcard $(VERILATED_CPP_FILE)),)
	$(error Rule Check: Cannot find verilated.cpp at '$(VERILATED_CPP_FILE)'. Required for Wasm build. Please set VERILATED_CPP_FILE or check Verilator installation.)
else
	@echo "Rule Check: Found verilated.cpp at '$(VERILATED_CPP_FILE)' for Emscripten compilation."
	@mkdir -p $(BUILD_DIR_WASM)

	@echo "Listing files in $(OBJ_DIR_VERILATED_WASM):"
	@ls -la $(OBJ_DIR_VERILATED_WASM)

	@echo "Verilated .cpp files to be compiled by emcc:"
	@echo "$(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE)__*.cpp) $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE).cpp"
	@echo "Other .cpp files for emcc: $(SIM_MAIN_WASM) $(VERILATED_CPP_FILE)"

	@echo "Compiling Wasm with Emscripten..."
	@echo "Full emcc command:"
	@echo "$(EMCC) $(EMCC_COMMON_FLAGS) $(EMCC_INCLUDE_FLAGS_WASM) \
		$(SIM_MAIN_WASM) \
		$(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE)__*.cpp) $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE).cpp \
		$(VERILATED_CPP_FILE) \
		$(EMCC_LINK_FLAGS_WASM) \
		-o $(TARGET_HTML)"
		
	$(EMCC) $(EMCC_COMMON_FLAGS) $(EMCC_INCLUDE_FLAGS_WASM) \
		$(SIM_MAIN_WASM) \
		$(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE)__*.cpp) \
		$(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE).cpp \
		$(VERILATED_CPP_FILE) \
		$(EMCC_LINK_FLAGS_WASM) \
		-o $(TARGET_HTML)

	@echo "WebAssembly build complete (emcc command finished)."
	@echo "Checking for output file: $(TARGET_HTML)"
	@ls -l $(TARGET_HTML) $(TARGET_JS_WASM) $(TARGET_WASM_FILE) 2>/dev/null || echo "Output files $(TARGET_HTML) / .js / .wasm NOT YET FOUND."
	@echo "Main HTML:   $(TARGET_HTML)"
	@echo "JS file:     $(TARGET_JS_WASM)"
	@echo "Wasm file:   $(TARGET_WASM_FILE)"
	$(if $(wildcard $(FONT_FILE)), \
		@echo "Font file '$(FONT_FILE)' preloaded as '$(FONT_FILE_BASENAME)'.", \
		@echo "Warning: Font file '$(FONT_FILE)' was not found during build. It may not be preloaded." \
	)
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
$(EXECUTABLE_NATIVE): $(VERILOG_SOURCES) $(SIM_MAIN_NATIVE) $(FONT_FILE)
	@mkdir -p $(OBJ_DIR_NATIVE)
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
ifeq ($(wildcard $(FONT_FILE)),)
	@echo "Warning: Font file '$(FONT_FILE)' not found. Cannot copy to output directory."
else
	@echo "Copying font file $(FONT_FILE) to $(OBJ_DIR_NATIVE)/$(FONT_FILE_BASENAME)..."
	@cp $(FONT_FILE) $(OBJ_DIR_NATIVE)/$(FONT_FILE_BASENAME)
endif
	chmod +x $(EXECUTABLE_NATIVE)

native: $(EXECUTABLE_NATIVE)

run_native: native
	@echo "Running native executable $(EXECUTABLE_NATIVE)..."
	./$(EXECUTABLE_NATIVE)

clean_native:
	@echo "Cleaning Native build artifacts..."
	rm -rf $(BUILD_DIR_NATIVE)
	@echo "Native clean complete."

# --- Common Targets ---
clean: clean_wasm clean_native
	@echo "All clean complete."

help:
	@echo "Unified Makefile for Verilator + Emscripten (Wasm) AND Native SDL Simulation"
	# ... (help text, ensure it's complete) ...
	@echo "Configuration Variables (can be overridden on the command line):"
	@echo "  VERILOG_TOP_MODULE      (default: $(VERILOG_TOP_MODULE))"
	# ... other help vars ...
	@echo "    VERILATOR_FLAGS_WASM    (current: $(VERILATOR_FLAGS_WASM))"
	# ...
	@echo ""
