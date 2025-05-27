#include "DutController.h"
#include "InputHandler.h" // Include the new InputHandler
#include "SdlVideo.h"
#include "SimConfig.h"

#include <SDL_ttf.h>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

TTF_Font* g_status_font_native = nullptr;
SdlVideo* g_status_window_native = nullptr;

// Helper function to render text (specific to native status window)
void renderTextNative(SDL_Renderer* renderer, TTF_Font* font, const std::string& text, int x, int y, SDL_Color color)
{
    if (!font || !renderer)
        return;
    SDL_Surface* surface = TTF_RenderText_Blended(font, text.c_str(), color);
    if (!surface) {
        std::cerr << "Native Status: Unable to render text surface! SDL_ttf Error: " << TTF_GetError() << std::endl;
        return;
    }
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (!texture) {
        std::cerr << "Native Status: Unable to create texture from rendered text! SDL Error: " << SDL_GetError() << std::endl;
        SDL_FreeSurface(surface);
        return;
    }
    SDL_Rect dstRect = { x, y, surface->w, surface->h };
    SDL_RenderCopy(renderer, texture, nullptr, &dstRect);
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
}

// Function to render the status of DUT inputs (specific to native)
void renderDutStatusNative(SdlVideo* status_display, TTF_Font* font, DutController& dut_ctrl)
{
    if (!status_display || !status_display->is_initialized() || !font)
        return;

    SDL_Renderer* renderer = status_display->get_renderer();
    SDL_SetRenderDrawColor(renderer, 0x33, 0x33, 0x33, 0xFF); // Dark grey background
    SDL_RenderClear(renderer);

    SDL_Color textColor = { 0xFF, 0xFF, 0xFF, 0xFF }; // White
    SDL_Color keyLowColor = { 0xFF, 0x00, 0x00, 0xFF }; // Red for KEY LOW
    SDL_Color keyHighColor = { 0x00, 0xFF, 0x00, 0xFF }; // Green for KEY HIGH
    SDL_Color swOnColor = { 0x00, 0xFF, 0x00, 0xFF }; // Green for SW ON
    SDL_Color swOffColor = { 0xFF, 0x00, 0x00, 0xFF }; // Red for SW OFF

    Vdemoman* dut_instance = dut_ctrl.get_dut_instance();
    if (!dut_instance)
        return;

    int y_offset = 10;
    const int line_height = FONT_SIZE + 2; // Adjust based on font size
    const int item_padding_y = 5;
    const int section_spacing_y = line_height + 10;
    const int text_x_start = 15;

    renderTextNative(renderer, font, "Inputs Status:", text_x_start, y_offset, textColor);
    y_offset += line_height + section_spacing_y;

    renderTextNative(renderer, font, "Switches (Kbd: 1-9 for SW9-1, 0 for SW0 - Toggle):", text_x_start, y_offset, textColor);
    y_offset += line_height + item_padding_y;

    int current_x = text_x_start;
    const int switch_block_width = 48;

    for (int i = 9; i >= 0; --i) { // Render SW9 down to SW0
        char kbd_char = (i == 0) ? '0' : ('0' + (10 - i));
        renderTextNative(renderer, font, std::string(1, kbd_char), current_x + (switch_block_width / 2) - (FONT_SIZE / 3), y_offset, textColor);
        // Move current_x for the next character
        current_x += switch_block_width;
    }
    y_offset += line_height; // Move to next line for "SWx" labels

    current_x = text_x_start; // Reset x for "SWx" labels
    for (int i = 9; i >= 0; --i) {
        std::string sw_label_str = "SW" + std::to_string(i);
        renderTextNative(renderer, font, sw_label_str, current_x + 2, y_offset, textColor);
        current_x += switch_block_width;
    }
    y_offset += line_height; // Move to next line for "ON/OFF" status

    current_x = text_x_start; // Reset x for "ON/OFF" status
    for (int i = 9; i >= 0; --i) {
        bool swIsActive = (dut_instance->SW >> i) & 1;
        std::string status_text = swIsActive ? "ON" : "OFF";
        // Approximate centering
        int text_width_approx = status_text.length() * FONT_SIZE / 2; // Rough estimate
        renderTextNative(renderer, font, status_text, current_x + (switch_block_width / 2) - (text_width_approx / 2), y_offset, swIsActive ? swOnColor : swOffColor);
        current_x += switch_block_width;
    }
    y_offset += line_height + section_spacing_y; // Move to next section

    renderTextNative(renderer, font, "Keys (Kbd: U,I,O,P for KEY3-0 - Press/Release):", text_x_start, y_offset, textColor);
    y_offset += line_height + item_padding_y;
    current_x = text_x_start; // Reset x for KEY section
    const int key_block_width = 75;
    char key_kbd_map[] = { 'U', 'I', 'O', 'P' }; // For KEY3, KEY2, KEY1, KEY0

    for (int i = 3; i >= 0; --i) { // KEY3 down to KEY0
        renderTextNative(renderer, font, std::string(1, key_kbd_map[3 - i]), current_x + (key_block_width / 2) - (FONT_SIZE / 3), y_offset, textColor);
        // Move current_x for the next character
        current_x += key_block_width;
    }
    y_offset += line_height; // Move to next line for "KEYx" labels

    current_x = text_x_start; // Reset x for "KEYx" labels
    for (int i = 3; i >= 0; --i) {
        std::string key_label_str = "KEY" + std::to_string(i);
        renderTextNative(renderer, font, key_label_str, current_x + 2, y_offset, textColor);
        current_x += key_block_width;
    }
    y_offset += line_height; // Move to next line for "LOW/HIGH" status

    current_x = text_x_start; // Reset x for "LOW/HIGH" status
    for (int i = 3; i >= 0; --i) {
        bool isLow = (~(dut_instance->KEY >> i) & 1); // KEYs are active low
        std::string status_text = isLow ? "LOW" : "HIGH";
        // Approximate centering
        int text_width_approx = status_text.length() * FONT_SIZE / 2; // Rough estimate
        renderTextNative(renderer, font, status_text, current_x + (key_block_width / 2) - (text_width_approx / 2), y_offset, isLow ? keyLowColor : keyHighColor);
        current_x += key_block_width;
    }
    SDL_RenderPresent(renderer);
}

int main(int argc, char* argv[])
{
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL_Init failed: " << SDL_GetError() << std::endl;
        return 1;
    }
    if (TTF_Init() == -1) {
        std::cerr << "TTF_Init failed: " << TTF_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    // Use FONT_PATH and FONT_SIZE from SimConfig.h
    g_status_font_native = TTF_OpenFont(FONT_PATH, FONT_SIZE);
    if (!g_status_font_native) {
        std::cerr << "Failed to load font '" << FONT_PATH << "': " << TTF_GetError() << std::endl;
    }

    DutController dut_controller(argc, argv);
    SdlVideo main_screen("Native Verilator VGA Sim", SCREEN_WIDTH, SCREEN_HEIGHT, true);
    InputHandler input_handler; // Create InputHandler instance

    if (!main_screen.initialize(false)) {
        if (g_status_font_native)
            TTF_CloseFont(g_status_font_native);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    g_status_window_native = new SdlVideo("Verilog Inputs Status", STATUS_WINDOW_WIDTH, STATUS_WINDOW_HEIGHT, false);
    if (g_status_font_native && !g_status_window_native->initialize(false)) {
        std::cerr << "Failed to initialize status window. Continuing without it." << std::endl;
        delete g_status_window_native;
        g_status_window_native = nullptr;
    }

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

            // Handle specific window events separately
            if (e.type == SDL_WINDOWEVENT) {
                if (main_screen.get_window() && e.window.windowID == SDL_GetWindowID(main_screen.get_window()) && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                    running = false; // Main window closed
                } else if (g_status_window_native && g_status_window_native->get_window() && e.window.windowID == SDL_GetWindowID(g_status_window_native->get_window()) && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                    SDL_HideWindow(g_status_window_native->get_window()); // Just hide status window
                }
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
                pixel_buffer[static_cast<size_t>(y) * SCREEN_WIDTH + x] = (0xFFU << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b);
            }

            bool current_vsync = dut_controller.is_vsync_active();
            if (last_vsync_state && !current_vsync) {
                main_screen.update_frame(pixel_buffer);
                frame_rendered_on_vsync = true;
                frame_counter++;
            }
            last_vsync_state = current_vsync;
        }

        if (!running)
            break;

        if (!frame_rendered_on_vsync) {
            main_screen.update_frame(pixel_buffer);
            frame_counter++;
        }

        if (g_status_window_native && g_status_window_native->is_initialized() && g_status_font_native && (SDL_GetWindowFlags(g_status_window_native->get_window()) & SDL_WINDOW_SHOWN)) {
            renderDutStatusNative(g_status_window_native, g_status_font_native, dut_controller);
        }

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
    if (g_status_font_native)
        TTF_CloseFont(g_status_font_native);
    delete g_status_window_native;
    TTF_Quit();
    SDL_Quit();
    return 0;
}
