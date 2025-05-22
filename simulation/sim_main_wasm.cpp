#include <utility>
#include "Vdemoman.h"
#include "verilated.h"
#include <SDL.h>
#include <iostream>
#include <vector>

// Include Emscripten header for the main loop
#include <emscripten/emscripten.h>

// Screen dimensions
const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;
// const int SCREEN_FPS = 60; // FPS will be controlled by browser's requestAnimationFrame

// Global variables needed for the main loop function
VerilatedContext* contextp = nullptr;
Vdemoman* dut = nullptr;
SDL_Renderer* renderer = nullptr;
SDL_Texture* texture = nullptr;
std::vector<uint32_t> pixel_buffer;
bool last_vsync = false; // Initialize appropriately

// VGA timing parameters
const int H_TOTAL_CLOCKS = 800;
const int V_TOTAL_LINES = 525;
const int cycles_per_vga_frame = H_TOTAL_CLOCKS * V_TOTAL_LINES;

// Tick function (drives CLOCK_50)
void tick_dut_clock() {
    if (!dut || !contextp) return;
    dut->CLOCK_50 = 0;
    dut->eval();
    contextp->timeInc(1);
    dut->CLOCK_50 = 1;
    dut->eval();
    contextp->timeInc(1);
}

// This function will be called repeatedly by the browser
void main_loop_iteration() {
    if (!dut || !contextp || !renderer || !texture) return;

    SDL_Event e;
    while (SDL_PollEvent(&e) != 0) {
        if (e.type == SDL_QUIT) {
            // In a real app, you might want to clean up and stop the loop
            // For simplicity here, we just log it. Emscripten might handle quit differently.
            std::cout << "SDL_QUIT event received" << std::endl;
            // emscripten_cancel_main_loop(); // To stop the loop
            // running = false; // If you had a global running flag
            return; // Exit this iteration
        } else if (e.type == SDL_KEYDOWN) {
            switch (e.key.keysym.sym) {
                // case SDLK_ESCAPE: emscripten_cancel_main_loop(); break;
                case SDLK_0: dut->KEY |= (1 << 0); break;
                case SDLK_1: dut->KEY |= (1 << 1); break;
                // ... other key handling ...
            }
        } else if (e.type == SDL_KEYUP) {
            // ... key up handling ...
        }
    }

    bool frame_rendered_this_loop = false;
    for (int vga_clk_cycle = 0; vga_clk_cycle < cycles_per_vga_frame; ++vga_clk_cycle) {
        tick_dut_clock(); // Tick CLOCK_50 once (which is half a 25MHz cycle)
        tick_dut_clock(); // Tick CLOCK_50 again (completes one 25MHz cycle)

        bool active_display = (dut->VGA_BLANK_N == 0);
        if (active_display) {
            int x = dut->DEBUG_X;
            int y = dut->DEBUG_Y;
            if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
                uint32_t r_val = dut->VGA_R;
                uint32_t g_val = dut->VGA_G;
                uint32_t b_val = dut->VGA_B;
                if ((y * SCREEN_WIDTH + x) < pixel_buffer.size()) {
                     pixel_buffer[y * SCREEN_WIDTH + x] = (0xFFU << 24) | (r_val << 16) | (g_val << 8) | b_val;
                }
            }
        }

        bool current_vsync = dut->VGA_VS;
        if (last_vsync && !current_vsync) { // Falling edge of VSync
            SDL_UpdateTexture(texture, NULL, pixel_buffer.data(), SCREEN_WIDTH * sizeof(uint32_t));
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, NULL, NULL);
            SDL_RenderPresent(renderer);
            frame_rendered_this_loop = true;
            // For smoother browser animation, we usually don't break here but let the outer loop control FPS
        }
        last_vsync = current_vsync;

        if (contextp->gotFinish()) {
            std::cout << "Verilator $finish called." << std::endl;
            emscripten_cancel_main_loop(); // Stop the Emscripten main loop
            return;
        }
    }
    // Fallback rendering if VSync wasn't hit
    if (!frame_rendered_this_loop) {
        SDL_UpdateTexture(texture, NULL, pixel_buffer.data(), SCREEN_WIDTH * sizeof(uint32_t));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }
}

int main(int argc, char* argv[]) {
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    dut = new Vdemoman{contextp};

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }

    // Note: Emscripten often creates the canvas. We target it.
    // SDL_CreateWindowAndRenderer is often preferred with Emscripten.
    SDL_Window* window = SDL_CreateWindow("Verilator VGA Sim - Wasm",
                                          SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                          SCREEN_WIDTH, SCREEN_HEIGHT, 0); // Flag 0 for Emscripten often works

    if (!window) {
        std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_Quit(); return 1;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (!renderer) {
        std::cerr << "Renderer could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_DestroyWindow(window); SDL_Quit(); return 1;
    }

    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                SDL_TEXTUREACCESS_STREAMING,
                                SCREEN_WIDTH, SCREEN_HEIGHT);
    if (!texture) {
        std::cerr << "Texture could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_DestroyRenderer(renderer); SDL_DestroyWindow(window); SDL_Quit(); return 1;
    }

    pixel_buffer.resize(SCREEN_WIDTH * SCREEN_HEIGHT, 0xFF000000);

    // Reset the DUT
    dut->reset = 1;
    for (int i = 0; i < 20; ++i) {
        tick_dut_clock();
    }
    dut->reset = 0;
    dut->eval();

    dut->KEY = 0xF;
    dut->SW = 0x0;
    last_vsync = dut->VGA_VS; // Initialize after reset

    // Set the main loop function
    // The "0" means use browser's requestAnimationFrame for timing (recommended)
    // The "1" means simulate infinite loop
    emscripten_set_main_loop(main_loop_iteration, 0, 1);

    // Execution will not reach here in a typical Emscripten application
    // because emscripten_set_main_loop takes control.
    // Cleanup will happen when the browser page is closed or emscripten_cancel_main_loop is called.
    // However, for good practice, you might register an exit handler if complex cleanup is needed.
    // emscripten_set_exit_callback(my_cleanup_function);

    // SDL_Quit(); // Usually not called here for Emscripten
    // delete dut;
    // delete contextp;
    return 0; // This return is often not reached
}
