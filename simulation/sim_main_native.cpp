#include "DutController.h"
#include "InputHandler.h"
#include "SdlVideo.h"
#include "SimConfig.h" // For SCREEN_WIDTH, SCREEN_HEIGHT, CYCLES_PER_VGA_FRAME etc.

#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

int main(int argc, char* argv[])
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }

    DutController dut_controller(argc, argv);
    SdlVideo main_screen("Native Verilator VGA Sim", SCREEN_WIDTH, SCREEN_HEIGHT, true);
    InputHandler input_handler;

    if (!main_screen.initialize(false)) {
        SDL_Quit();
        return 1;
    }

    std::vector<uint32_t> pixel_buffer(static_cast<size_t>(SCREEN_WIDTH) * SCREEN_HEIGHT, 0xFF000000);
    bool running = true;

    dut_controller.reset_dut();

    // Variables for simulated clock speed calculation
    Uint32 speed_calc_timer_start_ms = SDL_GetTicks();
    long long dut_clk_tick_counter = 0; // Counts DUT clock ticks
    const int SPEED_UPDATE_INTERVAL_MS = 1000;

    std::string base_window_title = "Native Verilator VGA Sim";

    std::cout << "Starting native simulation loop (uncapped)..." << std::endl;

    while (running) {

        SDL_Event e;
        while (SDL_PollEvent(&e) != 0) {
            input_handler.process_sdl_event(e, dut_controller);

            if (input_handler.has_quit_been_requested_by_event()) {
                running = false;
            }

            if (e.type == SDL_WINDOWEVENT) {
                if (main_screen.get_window() && e.window.windowID == SDL_GetWindowID(main_screen.get_window()) && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                    running = false;
                }
            }
        }
        if (!running) {
            break;
        }

        for (int clk_cycle = 0; clk_cycle < CYCLES_PER_VGA_FRAME; ++clk_cycle) {
            dut_controller.tick_simulation_clock();
            dut_clk_tick_counter++; // Increment for each DUT clock tick

            if (dut_controller.has_finished()) {
                running = false;
                break;
            }

            int x, y;
            uint8_t r, g, b;
            bool active_display;
            if (dut_controller.get_vga_pixel_state(x, y, r, g, b, active_display)) {
                if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
                    pixel_buffer[static_cast<size_t>(y) * SCREEN_WIDTH + x] = (0xFFU << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b);
                }
            }
        }

        if (!running) {
            break;
        }

        main_screen.update_frame(pixel_buffer);

        // Simulated clock speed calculation and window title update
        Uint32 current_time_ms = SDL_GetTicks();
        if (current_time_ms - speed_calc_timer_start_ms >= SPEED_UPDATE_INTERVAL_MS) {
            double elapsed_seconds = (current_time_ms - speed_calc_timer_start_ms) / 1000.0;
            double current_sim_speed_hz = 0.0;
            if (elapsed_seconds > 0) {
                current_sim_speed_hz = static_cast<double>(dut_clk_tick_counter) / elapsed_seconds;
            }

            dut_clk_tick_counter = 0;
            speed_calc_timer_start_ms = current_time_ms;

            if (main_screen.get_window()) {
                std::stringstream ss;
                ss << base_window_title << " - Sim Speed: ";
                if (current_sim_speed_hz >= 1e6) { // MegaHertz
                    ss << std::fixed << std::setprecision(2) << (current_sim_speed_hz / 1e6) << " MHz";
                } else if (current_sim_speed_hz >= 1e3) { // KiloHertz
                    ss << std::fixed << std::setprecision(2) << (current_sim_speed_hz / 1e3) << " kHz";
                } else { // Hertz
                    ss << std::fixed << std::setprecision(0) << current_sim_speed_hz << " Hz";
                }
                SDL_SetWindowTitle(main_screen.get_window(), ss.str().c_str());
            }
        }
    }

    std::cout << "Native simulation loop finished. Cleaning up..." << std::endl;
    SDL_Quit();
    return 0;
}
