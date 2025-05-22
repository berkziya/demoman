# Makefile

# Verilator settings
VERILATOR = verilator
VERILATOR_FLAGS = --cc --exe --build -j 0 --timing
VERILATOR_TRACE_FLAGS = --trace # Add this if you want VCD tracing (slower)

# C++ Compiler settings
CXX = g++
CXXFLAGS = -std=c++17 `sdl2-config --cflags`
LDFLAGS = `sdl2-config --libs`

# Project files
VERILOG_TOP_MODULE = demoman
VERILOG_SOURCES = $(wildcard rtl/*.v rtl/*/*.v rtl/*/*/*.v synthesis/demoman.v)
CPP_MAIN = simulation/sim_main.cpp

# Output directory for Verilator
OBJ_DIR = obj_dir
EXECUTABLE = $(OBJ_DIR)/V$(VERILOG_TOP_MODULE)

# Default target
all: $(EXECUTABLE)

# Verilate and compile
$(EXECUTABLE): $(VERILOG_SOURCES) $(CPP_MAIN)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILOG_SOURCES) --top-module $(VERILOG_TOP_MODULE) --exe $(CPP_MAIN) -CFLAGS "$(CXXFLAGS)" -LDFLAGS "$(LDFLAGS)"

# Run the simulation
run: $(EXECUTABLE)
	./$(EXECUTABLE)

# Clean up
clean:
	rm -rf $(OBJ_DIR) *.vcd

.PHONY: all run clean
