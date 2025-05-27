import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def clock_divider_test(dut):
    """
    Test the clock divider module.
    """
    cocotb.log.info("Starting clock divider test")

    DIV = int(dut.DIV.value)
    clock = Clock(dut.clk, 10, units="us")

    cocotb.start_soon(clock.start(start_high=False))

    dut.rst_i.value = 0
    await Timer(1, units="us")
    dut.rst_i.value = 1
    await Timer(1, units="us")
    dut.rst_i.value = 0

    for i in range(1, DIV * 10):
        await RisingEdge(dut.clk)
        await Timer(1, units="us")
        # cocotb.log.info(f"step: {i} clk: {dut.clk} clk_o: {dut.clk_o} Expected {(i // DIV) % 2} dut.count: {dut.count}")
        assert dut.clk_o.value == (i // DIV) % 2, (f"Output clock value mismatch at step {i}. Expected {(i // DIV) % 2}, got {dut.clk_o.value}")

    cocotb.log.info(f"Clock divider test completed successfully with DIV={DIV}")
