CWD=$(shell pwd)

SIM ?= icarus
TOPLEVEL_LANG ?=verilog

VERILOG_SOURCES = $(wildcard ../../rtl/utils/clock_divider.v ../../rtl/utils/counter.v)

TOPLEVEL = clock_divider
MODULE := clock_divider_test
COCOTB_HDL_TIMEUNIT=1us
COCOTB_HDL_TIMEPRECISION=1us

# Include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
