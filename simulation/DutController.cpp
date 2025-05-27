#include "DutController.h"
#include "SimConfig.h" // For SCREEN_WIDTH, SCREEN_HEIGHT for validating DEBUG_X/Y
#include <iostream> // For potential debug messages

DutController::DutController(int argc, char* argv[])
{
    m_contextp = new VerilatedContext;
    m_contextp->commandArgs(argc, argv);
    m_dut = new Vdemoman { m_contextp };

    // Initialize DUT inputs to a default state
    m_dut->KEY = 0x0F; // All keys released (active low, so 1111)
    m_dut->SW = 0x000; // All switches off
    m_dut->reset = 0; // Initialize reset signal
    m_dut->eval(); // Evaluate initial state
}

DutController::~DutController()
{
    if (m_dut) {
        m_dut->final();
        delete m_dut;
    }
    if (m_contextp) {
        delete m_contextp;
    }
}

void DutController::reset_dut()
{
    if (!m_dut)
        return;
    m_dut->reset = 1;
    for (int i = 0; i < 20; ++i) { // Hold reset for a few cycles
        tick_simulation_clock();
    }
    m_dut->reset = 0;
    m_dut->eval();
}

void DutController::tick_simulation_clock()
{
    if (!m_dut || !m_contextp)
        return;
    m_dut->CLOCK_50 = 0;
    m_dut->eval();
    m_contextp->timeInc(1); // Advance simulation time

    m_dut->CLOCK_50 = 1;
    m_dut->eval();
    m_contextp->timeInc(1); // Advance simulation time
}

bool DutController::has_finished() const
{
    if (!m_contextp)
        return true; // Should not happen if initialized
    return m_contextp->gotFinish();
}

void DutController::set_switches_value(uint16_t value)
{
    if (!m_dut)
        return;
    m_dut->SW = value & 0x3FF; // Assuming 10 switches (mask to 10 bits)
}

void DutController::toggle_switch(int bit_index)
{
    if (!m_dut || bit_index < 0 || bit_index > 9)
        return;
    m_dut->SW ^= (1 << bit_index);
}

void DutController::set_keys_value(uint8_t value)
{
    if (!m_dut)
        return;
    m_dut->KEY = value & 0x0F; // Assuming 4 keys (mask to 4 bits)
}

void DutController::set_key_state(int bit_index, bool pressed_is_low)
{
    if (!m_dut || bit_index < 0 || bit_index > 3)
        return;
    if (pressed_is_low) {
        m_dut->KEY &= ~(1 << bit_index); // Active low: press sets bit to 0
    } else {
        m_dut->KEY |= (1 << bit_index); // Active low: release sets bit to 1
    }
}

bool DutController::get_vga_pixel_state(int& x, int& y, uint8_t& r, uint8_t& g, uint8_t& b, bool& active_display) const
{
    if (!m_dut) {
        active_display = false;
        return false;
    }
    active_display = (m_dut->VGA_BLANK_N == 1);
    x = m_dut->DEBUG_X; // Assuming these are direct outputs from your Verilog
    y = m_dut->DEBUG_Y;
    r = m_dut->VGA_R;
    g = m_dut->VGA_G;
    b = m_dut->VGA_B;

    if (active_display && x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        return true; // Valid pixel data within screen bounds
    }
    return false; // Data is outside bounds or display is blanked
}

bool DutController::is_vsync_active() const
{
    if (!m_dut)
        return false;
    return (m_dut->VGA_VS == 1); // Assuming VGA_VS is 1 during VSYNC pulse
}

Vdemoman* DutController::get_dut_instance()
{
    return m_dut;
}
