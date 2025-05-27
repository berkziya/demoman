#pragma once

#include "Vdemoman.h" // Replace Vdemoman with your actual Verilated top module header
#include "verilated.h"
#include <cstdint> // For uint8_t, uint16_t

class DutController {
public:
    DutController(int argc, char* argv[]);
    ~DutController();

    void reset_dut();
    void tick_simulation_clock();
    bool has_finished() const;

    // Input setters
    void set_switches_value(uint16_t value);
    void toggle_switch(int bit_index); // SW0 to SW9

    void set_keys_value(uint8_t value);
    void set_key_state(int bit_index, bool pressed_is_low); // KEY0 to KEY3

    // Output getters for VGA
    // Returns true if coordinates are valid and display is active
    bool get_vga_pixel_state(int& x, int& y, uint8_t& r, uint8_t& g, uint8_t& b, bool& active_display) const;
    bool is_vsync_active() const;

    Vdemoman* get_dut_instance(); // For direct access if needed (e.g., status window)

private:
    VerilatedContext* m_contextp;
    Vdemoman* m_dut;
};
