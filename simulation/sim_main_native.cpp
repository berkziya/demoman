#include "DutController.h"
#include "InputHandler.h" // Include the new InputHandler
#include "SdlVideo.h"
#include "SimConfig.h" // Still needed for SCREEN_WIDTH, SCREEN_HEIGHT, CYCLES_PER_VGA_FRAME etc.

// TTF includes are no longer needed if the status window was the only user
// #include <SDL_ttf.h>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

// Removed global variables for the status window and its font
// TTF_Font* g_status_font_native = nullptr;
// SdlVideo* g_status_window_native = nullptr;

// Removed helper function renderTextNative as it was specific to the status window
// void renderTextNative(...) { ... }

// Removed function to render the status of DUT inputs as it's for the status window
// void renderDutStatusNative(...) { ... }

int main(int argc, char* argv[])
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }
    // TTF_Init is no longer needed if it was only for the status window
    // if (TTF_Init() == -1) {
    //     std::cerr << "TTF_Init failed: " << TTF_GetError() << std::endl;
    //     SDL_Quit();
    //     return 1;
    // }

    // Removed font loading for the status window
    // g_status_font_native = TTF_OpenFont(FONT_PATH, FONT_SIZE);
    // if (!g_status_font_native) {
    //     std::cerr << "Failed to load font '" << FONT_PATH << "': " << TTF_GetError() << std::endl;
    // }

    DutController dut_controller(argc, argv);
    SdlVideo main_screen("Native Verilator VGA Sim", SCREEN_WIDTH, SCREEN_HEIGHT, true);
    InputHandler input_handler; // Create InputHandler instance

    if (!main_screen.initialize(false)) {
        // Removed font cleanup here as font is not loaded
        // if (g_status_font_native) TTF_CloseFont(g_status_font_native);
        // TTF_Quit(); // Remove if TTF is not used elsewhere
        SDL_Quit();
        return 1;
    }

    // Removed creation and initialization of the status window
    // g_status_window_native = new SdlVideo("Verilog Inputs Status", STATUS_WINDOW_WIDTH, STATUS_WINDOW_HEIGHT, false);
    // if (g_status_font_native && !g_status_window_native->initialize(false)) {
    //     std::cerr << "Failed to initialize status window. Continuing without it." << std::endl;
    //     delete g_status_window_native;
    //     g_status_window_native = nullptr;
    // }

    std::vector<uint32_t> pixel_buffer(static_cast<size_t>(SCREEN_WIDTH) * SCREEN_HEIGHT, 0xFF000000);
    bool running = true;

    dut_controller.reset_dut();
    bool last_vsync_state = dut_controller.is_vsync_active();

    Uint32 frame_start_time_ms = 0;
    Uint32 fps_timer_start_ms = SDL_GetTicks();
    int frame_counter = 0;
    const int FPS_UPDATE_INTERVAL_MS = 1000;
    const int TARGET_FPS = 60;
    const int SCREEN_TICKS_PER_FRAME_TARGET = 1000 / TARGET_FPS;
    std::string base_window_title = "Native Verilator VGA Sim";

    std::cout << "Starting native simulation loop..." << std::endl;

    while (running) {
        frame_start_time_ms = SDL_GetTicks();

        SDL_Event e;
        while (SDL_PollEvent(&e) != 0) {
            input_handler.process_sdl_event(e, dut_controller); // Process general events

            if (input_handler.has_quit_been_requested_by_event()) {
                running = false; // Quit signaled by InputHandler (SDL_QUIT, ESC)
            }

            // Handle specific window events
            if (e.type == SDL_WINDOWEVENT) {
                if (main_screen.get_window() && e.window.windowID == SDL_GetWindowID(main_screen.get_window()) && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                    running = false; // Main window closed
                }
                // Removed event handling for the status window closure
                // else if (g_status_window_native && g_status_window_native->get_window() && e.window.windowID == SDL_GetWindowID(g_status_window_native->get_window()) && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                //     SDL_HideWindow(g_status_window_native->get_window()); // Just hide status window
                // }
            }
        }
        if (!running)
            break; // Exit main loop if quit requested

        // ... (VGA simulation and rendering logic remains the same) ...
        bool frame_rendered_on_vsync = false;
        for (int clk_cycle = 0; clk_cycle < CYCLES_PER_VGA_FRAME; ++clk_cycle) {
            dut_controller.tick_simulation_clock();
            if (dut_controller.has_finished()) {
                running = false;
                break;
            }

            int x, y;
            uint8_t r, g, b;
            bool active_display;
            if (dut_controller.get_vga_pixel_state(x, y, r, g, b, active_display)) {
                if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) { // Bounds check
                    pixel_buffer[static_cast<size_t>(y) * SCREEN_WIDTH + x] = (0xFFU << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b);
                }
            }

            bool current_vsync = dut_controller.is_vsync_active();
            if (last_vsync_state && !current_vsync) { // Falling edge of VSYNC
                main_screen.update_frame(pixel_buffer);
                frame_rendered_on_vsync = true;
                frame_counter++;
            }
            last_vsync_state = current_vsync;
        }

        if (!running)
            break;

        // If the frame wasn't rendered due to VSYNC timing (e.g., simulation ended mid-frame)
        // still update to show the last state.
        if (!frame_rendered_on_vsync) {
            main_screen.update_frame(pixel_buffer);
            frame_counter++;
        }

        // Removed rendering call for the status window
        // if (g_status_window_native && g_status_window_native->is_initialized() && g_status_font_native && (SDL_GetWindowFlags(g_status_window_native->get_window()) & SDL_WINDOW_SHOWN)) {
        //     renderDutStatusNative(g_status_window_native, g_status_font_native, dut_controller);
        // }

        Uint32 current_time_ms = SDL_GetTicks();
        if (current_time_ms - fps_timer_start_ms >= FPS_UPDATE_INTERVAL_MS) {
            double current_fps = frame_counter / ((current_time_ms - fps_timer_start_ms) / 1000.0);
            frame_counter = 0;
            fps_timer_start_ms = current_time_ms;
            if (main_screen.get_window()) {
                std::stringstream ss;
                ss << base_window_title << " - FPS: " << std::fixed << std::setprecision(1) << current_fps;
                SDL_SetWindowTitle(main_screen.get_window(), ss.str().c_str());
            }
        }

        Uint32 frame_processing_time_ms = SDL_GetTicks() - frame_start_time_ms;
        if (frame_processing_time_ms < SCREEN_TICKS_PER_FRAME_TARGET) {
            SDL_Delay(SCREEN_TICKS_PER_FRAME_TARGET - frame_processing_time_ms);
        }
    }

    std::cout << "Native simulation loop finished. Cleaning up..." << std::endl;
    // Removed cleanup for status window font and object
    // if (g_status_font_native) TTF_CloseFont(g_status_font_native);
    // delete g_status_window_native;

    // TTF_Quit is no longer needed if it was only for the status window
    // TTF_Quit();
    SDL_Quit();
    return 0;
}
