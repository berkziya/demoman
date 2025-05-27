#include "Vdemoman.h" // Should match your top-level Verilog module name
#include "verilated.h"
#include <SDL.h>
#include <SDL_ttf.h>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

// Screen dimensions (assuming these are defined elsewhere or keep as is)
const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;
const int SCREEN_FPS = 60;
const int SCREEN_TICKS_PER_FRAME = 1000 / SCREEN_FPS;

// Status window dimensions
const int STATUS_WINDOW_WIDTH = 500; // Adjusted for horizontal layout
const int STATUS_WINDOW_HEIGHT = 300; // Adjusted for new layout, added a bit more height for Key kbd hints

// Helper function to render text (assuming this exists from previous code)
void renderText(SDL_Renderer* renderer, TTF_Font* font, const std::string& text, int x, int y, SDL_Color color)
{
    if (!font)
        return;
    SDL_Surface* surface = TTF_RenderText_Blended(font, text.c_str(), color);
    if (!surface) {
        std::cerr << "Unable to render text surface! SDL_ttf Error: " << TTF_GetError() << std::endl;
        return;
    }
    SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
    if (!texture) {
        std::cerr << "Unable to create texture from rendered text! SDL Error: " << SDL_GetError() << std::endl;
        SDL_FreeSurface(surface);
        return;
    }
    SDL_Rect dstRect = { x, y, surface->w, surface->h };
    SDL_RenderCopy(renderer, texture, NULL, &dstRect);
    SDL_FreeSurface(surface);
    SDL_DestroyTexture(texture);
}

// Function to render the status of DUT inputs
void renderStatusWindow(SDL_Renderer* renderer, TTF_Font* font, Vdemoman* dut)
{
    SDL_SetRenderDrawColor(renderer, 0x33, 0x33, 0x33, 0xFF); // Dark grey background
    SDL_RenderClear(renderer);

    SDL_Color textColor = { 0xFF, 0xFF, 0xFF, 0xFF }; // White
    SDL_Color keyLowColor = { 0xFF, 0x00, 0x00, 0xFF }; // Red for KEY LOW
    SDL_Color keyHighColor = { 0x00, 0xFF, 0x00, 0xFF }; // Green for KEY HIGH
    SDL_Color swOnColor = { 0x00, 0xFF, 0x00, 0xFF }; // Green for SW ON
    SDL_Color swOffColor = { 0xFF, 0x00, 0x00, 0xFF }; // Red for SW OFF

    int y_offset = 10;
    const int line_height = 20;
    const int item_padding_y = 5;
    const int section_spacing_y = line_height + 10; // Increased spacing between sections
    const int text_x_start = 15;

    renderText(renderer, font, "Inputs Status:", text_x_start, y_offset, textColor);
    y_offset += line_height + section_spacing_y;

    // --- Switches Section (Horizontal) ---
    renderText(renderer, font, "Switches (Kbd: 1-9 for SW9-1, 0 for SW0 - Toggle):", text_x_start, y_offset, textColor);
    y_offset += line_height + item_padding_y;

    int current_x = text_x_start;
    const int switch_block_width = 48;

    // Row 1: Keyboard Key Hint for Switches
    int kbd_hint_y_sw = y_offset;
    for (int i = 9; i >= 0; --i) {
        char kbd_char = (i == 0) ? '0' : ('0' + (10 - i));
        renderText(renderer, font, std::string(1, kbd_char), current_x + (switch_block_width / 2) - 9, kbd_hint_y_sw, textColor);
        current_x += switch_block_width;
    }
    y_offset += line_height + item_padding_y;
    current_x = text_x_start;

    // Row 2: SWX Label
    int sw_label_y = y_offset;
    for (int i = 9; i >= 0; --i) {
        std::string sw_label_str = "SW" + std::to_string(i);
        renderText(renderer, font, sw_label_str, current_x + 2, sw_label_y, textColor);
        current_x += switch_block_width;
    }
    y_offset += line_height + item_padding_y;
    current_x = text_x_start;

    // Row 3: SWX Status (ON/OFF)
    int sw_status_y = y_offset;
    for (int i = 9; i >= 0; --i) {
        bool swIsActive = (dut->SW >> i) & 1;
        std::string status_text = swIsActive ? "ON" : "OFF";
        int text_width_approx = status_text.length() * 7;
        renderText(renderer, font, status_text,
            current_x + (switch_block_width / 2) - (text_width_approx / 2) - 9, sw_status_y, swIsActive ? swOnColor : swOffColor);
        current_x += switch_block_width;
    }
    y_offset += line_height + section_spacing_y;

    // --- Keys Section (Horizontal) ---
    renderText(renderer, font, "Keys (Kbd: U,I,O,P for KEY3-0 - Press/Release):", text_x_start, y_offset, textColor);
    y_offset += line_height + item_padding_y;
    current_x = text_x_start;
    const int key_block_width = 75;

    // Row 1: Keyboard Key Hint for Keys
    int kbd_hint_y_key = y_offset;
    char key_kbd_map[] = { 'U', 'I', 'O', 'P' }; // For KEY3, KEY2, KEY1, KEY0
    for (int i = 3; i >= 0; --i) {
        renderText(renderer, font, std::string(1, key_kbd_map[3 - i]), current_x + (key_block_width / 2) - 22, kbd_hint_y_key, textColor);
        current_x += key_block_width;
    }
    y_offset += line_height + item_padding_y;
    current_x = text_x_start;

    // Row 2: KEYX Label
    int key_label_y = y_offset;
    for (int i = 3; i >= 0; --i) { // KEY3 down to KEY0
        std::string key_label_str = "KEY" + std::to_string(i);
        renderText(renderer, font, key_label_str, current_x + 2, key_label_y, textColor);
        current_x += key_block_width;
    }
    y_offset += line_height + item_padding_y;
    current_x = text_x_start;

    // Row 3: KEYX Status (HIGH/LOW)
    int key_status_y = y_offset;
    for (int i = 3; i >= 0; --i) {
        bool isLow = (~(dut->KEY >> i) & 1);
        std::string status_text = isLow ? "LOW" : "HIGH";
        int text_width_approx = status_text.length() * 7;
        renderText(renderer, font, status_text,
            current_x + (key_block_width / 2) - (text_width_approx / 2) - 22, key_status_y, isLow ? keyLowColor : keyHighColor);
        current_x += key_block_width;
    }

    SDL_RenderPresent(renderer);
}

// tick function (assuming this exists from previous code)
void tick(Vdemoman* dut, VerilatedContext* contextp)
{
    dut->CLOCK_50 = 0;
    dut->eval();
    contextp->timeInc(1);
    dut->CLOCK_50 = 1;
    dut->eval();
    contextp->timeInc(1);
}

int main(int argc, char* argv[])
{
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vdemoman* dut = new Vdemoman { contextp };

    // SDL and TTF Initialization
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL_Init Error: " << SDL_GetError() << std::endl;
        return 1;
    }
    if (TTF_Init() == -1) {
        std::cerr << "TTF_Init Error: " << TTF_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    TTF_Font* font = TTF_OpenFont("Roboto_Condensed-Regular.ttf", 18);
    if (!font) {
        std::cerr << "Failed to load font! SDL_ttf Error: " << TTF_GetError() << std::endl;
    }

    // Main Simulation Window & Renderer
    std::string main_window_title = "Verilator VGA Sim - demoman";
    SDL_Window* main_window = SDL_CreateWindow(main_window_title.c_str(), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (!main_window) {
        std::cerr << "SDL_CreateWindow (Main) Error: " << SDL_GetError() << std::endl;
        if (font)
            TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }
    SDL_Renderer* main_renderer = SDL_CreateRenderer(main_window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!main_renderer) {
        std::cerr << "SDL_CreateRenderer (Main) Error: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(main_window);
        if (font)
            TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }
    SDL_Texture* main_texture = SDL_CreateTexture(main_renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
    if (!main_texture) {
        std::cerr << "SDL_CreateTexture (Main) Error: " << SDL_GetError() << std::endl;
        SDL_DestroyRenderer(main_renderer);
        SDL_DestroyWindow(main_window);
        if (font)
            TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    // Status Window & Renderer
    SDL_Window* status_window = SDL_CreateWindow("Verilog Inputs Status", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, STATUS_WINDOW_WIDTH, STATUS_WINDOW_HEIGHT, SDL_WINDOW_SHOWN);
    if (!status_window) {
        std::cerr << "SDL_CreateWindow (Status) Error: " << SDL_GetError() << std::endl;
        SDL_DestroyTexture(main_texture);
        SDL_DestroyRenderer(main_renderer);
        SDL_DestroyWindow(main_window);
        if (font)
            TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }
    SDL_Renderer* status_renderer = SDL_CreateRenderer(status_window, -1, SDL_RENDERER_ACCELERATED);
    if (!status_renderer) {
        std::cerr << "SDL_CreateRenderer (Status) Error: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(status_window);
        SDL_DestroyTexture(main_texture);
        SDL_DestroyRenderer(main_renderer);
        SDL_DestroyWindow(main_window);
        if (font)
            TTF_CloseFont(font);
        TTF_Quit();
        SDL_Quit();
        return 1;
    }

    std::vector<uint32_t> pixel_buffer(SCREEN_WIDTH * SCREEN_HEIGHT, 0xFF000000);

    // Reset the DUT
    dut->reset = 1;
    for (int i = 0; i < 20; ++i)
        tick(dut, contextp);
    dut->reset = 0;
    dut->eval();

    // Initialize DUT inputs
    // KEYs are active LOW, initialized to HIGH (released)
    dut->KEY = 0x0F; // For 4 KEY inputs (binary 1111)
    // SWitches are active HIGH (1 for ON), initialized to OFF, will be toggled
    dut->SW = 0x000; // For 10 SW inputs (binary 0000000000)

    bool running = true;
    SDL_Event e;
    bool last_vsync = dut->VGA_VS;

    const int H_TOTAL_CLOCKS = 800;
    const int V_TOTAL_LINES = 525;
    const int cycles_per_vga_frame = H_TOTAL_CLOCKS * V_TOTAL_LINES;

    Uint32 frame_start_time;
    Uint32 fps_timer_start = SDL_GetTicks();
    int frame_count = 0;
    double current_fps = 0.0;
    const int FPS_UPDATE_INTERVAL_MS = 1000;

    // Main simulation loop
    while (running && !contextp->gotFinish()) {
        frame_start_time = SDL_GetTicks();

        // Handle SDL events
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                running = false;
            } else if (e.type == SDL_WINDOWEVENT && e.window.event == SDL_WINDOWEVENT_CLOSE) {
                Uint32 windowID = e.window.windowID;
                if (main_window && windowID == SDL_GetWindowID(main_window)) {
                    running = false;
                } else if (status_window && windowID == SDL_GetWindowID(status_window)) {
                    SDL_HideWindow(status_window);
                }
            } else if (e.type == SDL_KEYDOWN) {
                // Process keydown events only if it's not an auto-repeat
                if (e.key.repeat == 0) {
                    switch (e.key.keysym.sym) {
                    case SDLK_ESCAPE:
                        running = false;
                        break;

                    // SWitches toggle (Kbd 1-9 for SW9-1, 0 for SW0)
                    case SDLK_0:
                        dut->SW ^= (1 << 0);
                        break;
                    case SDLK_1:
                        dut->SW ^= (1 << 9);
                        break;
                    case SDLK_2:
                        dut->SW ^= (1 << 8);
                        break;
                    case SDLK_3:
                        dut->SW ^= (1 << 7);
                        break;
                    case SDLK_4:
                        dut->SW ^= (1 << 6);
                        break;
                    case SDLK_5:
                        dut->SW ^= (1 << 5);
                        break;
                    case SDLK_6:
                        dut->SW ^= (1 << 4);
                        break;
                    case SDLK_7:
                        dut->SW ^= (1 << 3);
                        break;
                    case SDLK_8:
                        dut->SW ^= (1 << 2);
                        break;
                    case SDLK_9:
                        dut->SW ^= (1 << 1);
                        break;

                    // KEYs: Press makes bit LOW (0) (Kbd U,I,O,P for KEY3-0)
                    case SDLK_u:
                        dut->KEY &= ~(1 << 3);
                        break; // KEY3 LOW
                    case SDLK_i:
                        dut->KEY &= ~(1 << 2);
                        break; // KEY2 LOW
                    case SDLK_o:
                        dut->KEY &= ~(1 << 1);
                        break; // KEY1 LOW
                    case SDLK_p:
                        dut->KEY &= ~(1 << 0);
                        break; // KEY0 LOW
                    default:
                        break;
                    }
                }
            } else if (e.type == SDL_KEYUP) {
                // SWitches are toggled on KEYDOWN, no action here.
                // KEYs: Release makes bit HIGH (1)
                switch (e.key.keysym.sym) {
                case SDLK_u:
                    dut->KEY |= (1 << 3);
                    break; // KEY3 HIGH
                case SDLK_i:
                    dut->KEY |= (1 << 2);
                    break; // KEY2 HIGH
                case SDLK_o:
                    dut->KEY |= (1 << 1);
                    break; // KEY1 HIGH
                case SDLK_p:
                    dut->KEY |= (1 << 0);
                    break; // KEY0 HIGH
                default:
                    break;
                }
            }
        }

        // VGA simulation and rendering logic
        bool frame_rendered_this_loop = false;
        for (int vga_clk_cycle = 0; vga_clk_cycle < cycles_per_vga_frame && running; ++vga_clk_cycle) {
            tick(dut, contextp);

            bool active_display = (dut->VGA_BLANK_N == 1);
            if (active_display && dut->DEBUG_X >= 0 && dut->DEBUG_X < SCREEN_WIDTH && dut->DEBUG_Y >= 0 && dut->DEBUG_Y < SCREEN_HEIGHT) {
                pixel_buffer[dut->DEBUG_Y * SCREEN_WIDTH + dut->DEBUG_X] = (0xFFU << 24) | (dut->VGA_R << 16) | (dut->VGA_G << 8) | dut->VGA_B;
            }

            bool current_vsync = dut->VGA_VS;
            if (last_vsync && !current_vsync) {
                if (main_renderer && main_texture) {
                    SDL_UpdateTexture(main_texture, NULL, pixel_buffer.data(), SCREEN_WIDTH * sizeof(uint32_t));
                    SDL_RenderClear(main_renderer);
                    SDL_RenderCopy(main_renderer, main_texture, NULL, NULL);
                    SDL_RenderPresent(main_renderer);
                }
                frame_rendered_this_loop = true;
                frame_count++;
            }
            last_vsync = current_vsync;

            if (contextp->gotFinish()) {
                running = false;
                break;
            }
        }
        if (!frame_rendered_this_loop && running && main_renderer && main_texture) {
            SDL_UpdateTexture(main_texture, NULL, pixel_buffer.data(), SCREEN_WIDTH * sizeof(uint32_t));
            SDL_RenderClear(main_renderer);
            SDL_RenderCopy(main_renderer, main_texture, NULL, NULL);
            SDL_RenderPresent(main_renderer);
            frame_count++;
        }

        // Render the status window
        if (status_renderer && status_window && SDL_GetWindowFlags(status_window) & SDL_WINDOW_SHOWN && font) {
            renderStatusWindow(status_renderer, font, dut);
        }

        // FPS calculation and title update
        Uint32 current_time_fps = SDL_GetTicks();
        if (current_time_fps - fps_timer_start >= FPS_UPDATE_INTERVAL_MS) {
            current_fps = frame_count / ((current_time_fps - fps_timer_start) / 1000.0);
            frame_count = 0;
            fps_timer_start = current_time_fps;
            if (main_window) {
                std::stringstream ss;
                ss << main_window_title << " - FPS: " << std::fixed << std::setprecision(1) << current_fps;
                SDL_SetWindowTitle(main_window, ss.str().c_str());
            }
        }

        // Frame rate capping
        Uint32 frame_processing_time = SDL_GetTicks() - frame_start_time;
        if (frame_processing_time < SCREEN_TICKS_PER_FRAME) {
            SDL_Delay(SCREEN_TICKS_PER_FRAME - frame_processing_time);
        }
    }

    // Cleanup
    dut->final();
    delete dut;
    delete contextp;

    if (font)
        TTF_CloseFont(font);
    if (main_texture)
        SDL_DestroyTexture(main_texture);
    if (main_renderer)
        SDL_DestroyRenderer(main_renderer);
    if (main_window)
        SDL_DestroyWindow(main_window);
    if (status_renderer)
        SDL_DestroyRenderer(status_renderer);
    if (status_window)
        SDL_DestroyWindow(status_window);
    TTF_Quit();
    SDL_Quit();

    return 0;
}
