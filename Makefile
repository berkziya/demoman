# --- Common Configuration ---
VERILOG_TOP_MODULE ?= demoman
# Adjust if your top Verilog module file is named differently or located elsewhere
VERILOG_TOP_MODULE_FILE ?= synthesis/$(VERILOG_TOP_MODULE).v

SIM_DIR            ?= simulation
RTL_DIR            ?= rtl

# --- New Modular C++ Files ---
SIM_CONFIG_HEADER       := $(SIM_DIR)/SimConfig.h
DUT_CONTROLLER_CPP      := $(SIM_DIR)/DutController.cpp
DUT_CONTROLLER_HEADER   := $(SIM_DIR)/DutController.h
SDL_VIDEO_CPP           := $(SIM_DIR)/SdlVideo.cpp
SDL_VIDEO_HEADER        := $(SIM_DIR)/SdlVideo.h
INPUT_HANDLER_CPP       := $(SIM_DIR)/InputHandler.cpp
INPUT_HANDLER_HEADER    := $(SIM_DIR)/InputHandler.h

# All custom C++ source files (excluding Verilator-generated ones)
SIM_CPP_SOURCES_NATIVE  := $(SIM_DIR)/sim_main_native.cpp $(DUT_CONTROLLER_CPP) $(SDL_VIDEO_CPP) $(INPUT_HANDLER_CPP)
SIM_CPP_SOURCES_WASM    := $(SIM_DIR)/sim_main_wasm.cpp $(DUT_CONTROLLER_CPP) $(SDL_VIDEO_CPP) $(INPUT_HANDLER_CPP)
SIM_HEADERS             := $(SIM_CONFIG_HEADER) $(DUT_CONTROLLER_HEADER) $(SDL_VIDEO_HEADER) $(INPUT_HANDLER_HEADER)

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
BUILD_DIR_WASM          ?= build_wasm
OBJ_DIR_VERILATED_WASM  := $(BUILD_DIR_WASM)/obj_verilated_wasm
HTML_SHELL_FILE         ?= $(SIM_DIR)/index.html

VERILATOR_FLAGS_WASM    ?= -Wall --cc --prefix V$(VERILOG_TOP_MODULE) --Mdir $(OBJ_DIR_VERILATED_WASM) -Wno-fatal --top-module $(VERILOG_TOP_MODULE)

EMCC                    ?= em++
EMCC_COMMON_FLAGS       ?= -std=c++17 -O2 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -s WARN_ON_UNDEFINED_SYMBOLS=0 -DVL_IGNORE_UNKNOWN_ARCH -DVL_CPU_RELAX\(\)= -sASYNCIFY
EMCC_INCLUDE_FLAGS_WASM ?= -I$(VERILATOR_INCLUDE_PATH) -I$(OBJ_DIR_VERILATED_WASM) -I$(SIM_DIR)
EMCC_LINK_FLAGS_WASM    ?= -s USE_SDL=2
ifeq ($(wildcard $(FONT_FILE)),)
    $(warning Font file '$(FONT_FILE)' not found. Wasm build might fail to preload it or app might fail to load it if WASM part needed it.)
endif
ifeq ($(wildcard $(HTML_SHELL_FILE)),)
    $(warning HTML Shell file '$(HTML_SHELL_FILE)' not found. Emscripten will use a default shell.)
else
    EMCC_LINK_FLAGS_WASM += --shell-file $(HTML_SHELL_FILE)
endif


TARGET_HTML        := $(BUILD_DIR_WASM)/index.html
TARGET_JS_WASM     := $(BUILD_DIR_WASM)/index.js
TARGET_WASM_FILE   := $(BUILD_DIR_WASM)/index.wasm

# --- Native Target Configuration ---
BUILD_DIR_NATIVE   ?= build_native
OBJ_DIR_NATIVE     := $(BUILD_DIR_NATIVE)/obj_dir_$(strip $(VERILOG_TOP_MODULE))
EXECUTABLE_NATIVE  := $(OBJ_DIR_NATIVE)/V$(strip $(VERILOG_TOP_MODULE)) # Verilator default executable name

CXX_NATIVE         ?= g++
SDL2_CFLAGS        := $(shell sdl2-config --cflags)
SDL2_LIBS          := $(shell sdl2-config --libs)
SDL2_TTF_CFLAGS    := $(shell pkg-config SDL2_ttf --cflags)
SDL2_TTF_LIBS      := $(shell pkg-config SDL2_ttf --libs)

ifeq ($(strip $(SDL2_TTF_CFLAGS)),)
    $(warning WARNING: 'pkg-config SDL2_ttf --cflags' returned empty for native build. Check SDL2_ttf installation and pkg-config setup.)
endif
ifeq ($(strip $(SDL2_TTF_LIBS)),)
    $(warning WARNING: 'pkg-config SDL2_ttf --libs' returned empty for native build. Check SDL2_ttf installation and pkg-config setup.)
endif

CXXFLAGS_NATIVE    ?= -std=c++17 $(SDL2_CFLAGS) $(SDL2_TTF_CFLAGS) -I$(VERILATOR_INCLUDE_PATH) -I$(SIM_DIR)
LDFLAGS_NATIVE     ?= $(SDL2_LIBS) $(SDL2_TTF_LIBS)

# Verilator flags for native: --exe will compile and link.
# We pass our custom C++ sources directly to Verilator here.
VERILATOR_FLAGS_NATIVE_BASE ?= --cc --timing --top-module $(strip $(VERILOG_TOP_MODULE))

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

# Wasm target: compile all C++ sources (sim_main_wasm, DutController, SdlVideo, Verilator-generated, verilated.cpp) with emcc
$(TARGET_HTML): $(SIM_CPP_SOURCES_WASM) $(SIM_HEADERS) $(VERILATE_SENTINEL_WASM) $(VERILATED_CPP_FILE) $(HTML_SHELL_FILE) $(FONT_FILE)
	@echo "--- Building Wasm target: $(TARGET_HTML) ---"
	@echo "VERILATED_CPP_FILE (inside rule): '$(VERILATED_CPP_FILE)'"
ifeq ($(wildcard $(VERILATED_CPP_FILE)),)
    $(error Rule Check: Cannot find verilated.cpp at '$(VERILATED_CPP_FILE)'. Required for Wasm build. Please set VERILATED_CPP_FILE or check Verilator installation.)
else
	@echo "Rule Check: Found verilated.cpp at '$(VERILATED_CPP_FILE)' for Emscripten compilation."
	@mkdir -p $(BUILD_DIR_WASM)

	@echo "Compiling Wasm with Emscripten..."
	@echo "EMCC Sources: $(SIM_CPP_SOURCES_WASM) $(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE)__*.cpp) $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE).cpp $(VERILATED_CPP_FILE)"
	$(EMCC) $(EMCC_COMMON_FLAGS) $(EMCC_INCLUDE_FLAGS_WASM) \
		$(SIM_CPP_SOURCES_WASM) \
		$(wildcard $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE)__*.cpp) $(OBJ_DIR_VERILATED_WASM)/V$(VERILOG_TOP_MODULE).cpp \
		$(VERILATED_CPP_FILE) \
		$(EMCC_LINK_FLAGS_WASM) \
		-o $(TARGET_HTML)

	@echo "WebAssembly build complete."
	@echo "Main HTML:   $(TARGET_HTML)"
	@echo "JS file:     $(TARGET_JS_WASM)"
	@echo "Wasm file:   $(TARGET_WASM_FILE)"
	$(if $(wildcard $(HTML_SHELL_FILE)), , @echo "Note: Default Emscripten HTML shell was used.")
	$(if $(filter %--preload-file%,$(EMCC_LINK_FLAGS_WASM)), \
		@echo "Font file '$(FONT_FILE)' was specified for preloading.", \
	)
	@echo "To run, use 'make run_wasm' or open $(TARGET_HTML) via a local web server."
endif
	@echo "--- Exiting $(TARGET_HTML) rule ---"

wasm: $(TARGET_HTML)

run_wasm: wasm
	@echo "Starting web server in $(BUILD_DIR_WASM)..."
	@echo "Open http://localhost:8000/$(notdir $(TARGET_HTML)) in your browser."
	cd $(BUILD_DIR_WASM) && python3 -m http.server 8000 || (cd $(BUILD_DIR_WASM) && python -m SimpleHTTPServer 8000)

clean_wasm:
	@echo "Cleaning Wasm build artifacts..."
	rm -rf $(BUILD_DIR_WASM)
	@echo "Wasm clean complete."

# --- Native Targets ---
# Native target: Verilator's --exe flag handles compilation of all C++ sources.
$(EXECUTABLE_NATIVE): $(VERILOG_SOURCES) $(SIM_CPP_SOURCES_NATIVE) $(SIM_HEADERS) $(FONT_FILE)
	@mkdir -p $(OBJ_DIR_NATIVE) # Ensure obj_dir exists before Verilator writes to it
	@echo "Running Verilator and compiling Native executable for $(VERILOG_TOP_MODULE)..."
	$(VERILATOR) \
		$(VERILATOR_FLAGS_NATIVE_BASE) \
		--build --exe \
		--Mdir $(OBJ_DIR_NATIVE) \
		--prefix V$(strip $(VERILOG_TOP_MODULE)) \
		$(VERILOG_SOURCES) \
		$(SIM_CPP_SOURCES_NATIVE) \
		-CFLAGS "$(CXXFLAGS_NATIVE)" \
		-LDFLAGS "$(LDFLAGS_NATIVE)"
	@echo "Native executable built: $(EXECUTABLE_NATIVE)"
ifeq ($(wildcard $(FONT_FILE)),)
	@echo "Warning: Font file '$(FONT_FILE)' not found. Cannot copy to output directory."
else
	@echo "Copying font file $(FONT_FILE) to $(OBJ_DIR_NATIVE)/$(FONT_FILE_BASENAME)..."
	@cp $(FONT_FILE) $(OBJ_DIR_NATIVE)/$(FONT_FILE_BASENAME)
endif
	@ # Verilator --build might not set executable bit on the final link if it's just V$(VERILOG_TOP_MODULE)
	@ # chmod +x $(EXECUTABLE_NATIVE) # Usually not needed as make from Verilator does this.

native: $(EXECUTABLE_NATIVE)

run_native: native
	@echo "Running native executable $(EXECUTABLE_NATIVE)..."
	cd $(OBJ_DIR_NATIVE) && ./V$(strip $(VERILOG_TOP_MODULE)) # Run from obj_dir where font is copied

clean_native:
	@echo "Cleaning Native build artifacts..."
	rm -rf $(BUILD_DIR_NATIVE) # This will remove obj_dir_...
	@echo "Native clean complete."

# --- Common Targets ---
clean: clean_wasm clean_native
	@echo "All clean complete."

help:
	@echo "Makefile Targets:"
	@echo "  all             - Build both Wasm and Native targets."
	@echo "  wasm            - Build the WebAssembly target."
	@echo "  run_wasm        - Build and run the Wasm target (starts a local web server)."
	@echo "  clean_wasm      - Clean Wasm build artifacts."
	@echo "  verilate_wasm   - Only run Verilator for Wasm (generates C++ from Verilog)."
	@echo "  native          - Build the Native executable."
	@echo "  run_native      - Build and run the Native executable."
	@echo "  clean_native    - Clean Native build artifacts."
	@echo "  clean           - Clean all build artifacts."
	@echo "  help            - Show this help message."
	@echo "  test_vars       - (Example) Show some Makefile variable values."

test_vars:
	@echo "VERILOG_TOP_MODULE: $(VERILOG_TOP_MODULE)"
	@echo "VERILOG_SOURCES: $(VERILOG_SOURCES)"
	@echo "SIM_DIR: $(SIM_DIR)"
	@echo "SIM_CPP_SOURCES_NATIVE: $(SIM_CPP_SOURCES_NATIVE)"
	@echo "SIM_CPP_SOURCES_WASM: $(SIM_CPP_SOURCES_WASM)"
	@echo "SIM_HEADERS: $(SIM_HEADERS)"
	@echo "VERILATOR_INCLUDE_PATH: $(VERILATOR_INCLUDE_PATH)"
	@echo "VERILATED_CPP_FILE: $(VERILATED_CPP_FILE)"
	@echo "CXXFLAGS_NATIVE: $(CXXFLAGS_NATIVE)"
	@echo "EMCC_INCLUDE_FLAGS_WASM: $(EMCC_INCLUDE_FLAGS_WASM)"

test_wildcard:
	@echo "Wildcard for VERILATED_CPP_FILE: $(wildcard $(VERILATED_CPP_FILE))"
	@echo "Wildcard for FONT_FILE: $(wildcard $(FONT_FILE))"
	@echo "Wildcard for HTML_SHELL_FILE: $(wildcard $(HTML_SHELL_FILE))"
