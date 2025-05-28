#include "DutController.h"
#include "InputHandler.h"
#include "SdlVideo.h"
#include "SimConfig.h" // For SCREEN_WIDTH, SCREEN_HEIGHT, CYCLES_PER_VGA_FRAME etc.

#include <emscripten/emscripten.h>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

DutController* g_dut_controller_wasm = nullptr;
SdlVideo* g_main_screen_wasm = nullptr;
std::vector<uint32_t>* g_pixel_buffer_wasm = nullptr;
InputHandler* g_input_handler_wasm = nullptr;

// Globals for simulated clock speed calculation
long long g_dut_clk_tick_counter_wasm = 0;
double g_speed_calc_timer_start_ms_wasm = 0;
const int SPEED_UPDATE_INTERVAL_MS_WASM = 1000; // Update speed display every 1 second

void main_loop_iteration_wasm()
{
    if (!g_dut_controller_wasm || !g_main_screen_wasm || !g_pixel_buffer_wasm || !g_input_handler_wasm) {
        EM_ASM(Module.printErr("WASM_ERROR: Critical global pointer is null in main_loop_iteration. Halting."));
        emscripten_cancel_main_loop();
        return;
    }

    if (g_input_handler_wasm->has_quit_been_requested_by_event()) {
        EM_ASM(Module.print("WASM_INFO: Quit requested. Cancelling main loop."));
        emscripten_cancel_main_loop();
        return;
    }

    SDL_Event e;
    while (SDL_PollEvent(&e) != 0) {
        g_input_handler_wasm->process_sdl_event(e, *g_dut_controller_wasm);
    }

    // Check again if quit was signaled during event polling
    if (g_input_handler_wasm->has_quit_been_requested_by_event()) {
        EM_ASM(Module.print("WASM_INFO: Quit requested during event polling. Cancelling main loop."));
        emscripten_cancel_main_loop();
        return;
    }

    for (int clk_cycle = 0; clk_cycle < CYCLES_PER_VGA_FRAME; ++clk_cycle) {
        g_dut_controller_wasm->tick_simulation_clock();
        g_dut_clk_tick_counter_wasm++; // Count DUT clock ticks

        if (g_dut_controller_wasm->has_finished()) {
            EM_ASM(Module.print("WASM_INFO: Verilator $finish called."));
            g_input_handler_wasm->request_quit_externally(); // Request quit externally
            emscripten_cancel_main_loop();
            return;
        }

        int x, y;
        uint8_t r, g, b;
        bool active_display;
        if (g_dut_controller_wasm->get_vga_pixel_state(x, y, r, g, b, active_display)) {
            if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) { // Bounds check
                (*g_pixel_buffer_wasm)[static_cast<size_t>(y) * SCREEN_WIDTH + x] = (0xFFU << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b);
            }
        }
    }
    g_main_screen_wasm->update_frame(*g_pixel_buffer_wasm);

    // Calculate and display simulated clock speed
    double current_time_ms = emscripten_get_now(); // More precise timer for Wasm
    if (current_time_ms - g_speed_calc_timer_start_ms_wasm >= SPEED_UPDATE_INTERVAL_MS_WASM) {
        double elapsed_seconds = (current_time_ms - g_speed_calc_timer_start_ms_wasm) / 1000.0;
        double current_sim_speed_hz = 0.0;
        if (elapsed_seconds > 0) {
            current_sim_speed_hz = static_cast<double>(g_dut_clk_tick_counter_wasm) / elapsed_seconds;
        }

        g_dut_clk_tick_counter_wasm = 0; // Reset counter
        g_speed_calc_timer_start_ms_wasm = current_time_ms; // Reset timer

        std::stringstream ss;
        ss << "Sim Speed: ";
        if (current_sim_speed_hz >= 1e6) { // MegaHertz
            ss << std::fixed << std::setprecision(2) << (current_sim_speed_hz / 1e6) << " MHz";
        } else if (current_sim_speed_hz >= 1e3) { // KiloHertz
            ss << std::fixed << std::setprecision(2) << (current_sim_speed_hz / 1e3) << " kHz";
        } else { // Hertz
            ss << std::fixed << std::setprecision(0) << current_sim_speed_hz << " Hz";
        }
        EM_ASM_({
            var displayElement = document.getElementById('simSpeedDisplay');
            if (displayElement) displayElement.textContent = UTF8ToString($0); }, ss.str().c_str());
    }
}

void cleanup_wasm_resources()
{
    EM_ASM(Module.print("WASM_INFO: Performing cleanup_wasm_resources."));
    delete g_pixel_buffer_wasm;
    g_pixel_buffer_wasm = nullptr;
    if (g_main_screen_wasm) {
        delete g_main_screen_wasm;
        g_main_screen_wasm = nullptr;
    }
    delete g_dut_controller_wasm;
    g_dut_controller_wasm = nullptr;
    delete g_input_handler_wasm;
    g_input_handler_wasm = nullptr;

    EM_ASM(Module.print("WASM_INFO: Resource cleanup attempted."));
}

int main(int argc, char* argv[])
{
    EM_ASM(Module.print("WASM_INFO: Starting main function..."));

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0) {
        EM_ASM_({ Module.printErr("WASM_ERROR: SDL_Init failed: " + UTF8ToString(SDL_GetError())); });
        return 1;
    }
    EM_ASM(Module.print("WASM_INFO: SDL_Init successful."));

    g_dut_controller_wasm = new DutController(argc, argv);
    g_main_screen_wasm = new SdlVideo("WASM Verilator VGA Sim", SCREEN_WIDTH, SCREEN_HEIGHT, false);
    g_input_handler_wasm = new InputHandler();

    if (!g_main_screen_wasm->initialize(true)) { // 'true' for Wasm context in initialize
        EM_ASM(Module.printErr("WASM_ERROR: SdlVideo initialization failed."));
        // Perform partial cleanup before exiting
        delete g_input_handler_wasm;
        delete g_main_screen_wasm;
        delete g_dut_controller_wasm;
        SDL_Quit();
        return 1;
    }

    g_pixel_buffer_wasm = new std::vector<uint32_t>(static_cast<size_t>(SCREEN_WIDTH) * SCREEN_HEIGHT, 0xFF000000);
    if (!g_pixel_buffer_wasm) {
        EM_ASM(Module.printErr("WASM_ERROR: Pixel buffer allocation failed."));
        cleanup_wasm_resources(); // Attempt to clean up what was allocated
        SDL_Quit(); // Ensure SDL is quit if other cleanups fail
        return 1;
    }

    g_dut_controller_wasm->reset_dut();
    g_speed_calc_timer_start_ms_wasm = emscripten_get_now(); // Initialize speed timer

    EM_ASM(Module.print("WASM_INFO: Resources initialized. Starting Emscripten main loop..."));
    emscripten_set_main_loop(main_loop_iteration_wasm, 0, 1);

    cleanup_wasm_resources();
    SDL_Quit();
    EM_ASM(Module.print("WASM_INFO: Main function has exited."));
    return 0;
}
