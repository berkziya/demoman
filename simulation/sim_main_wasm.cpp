#include "Vdemoman.h"
#include "verilated.h"
#include <SDL.h>
#include <algorithm>
#include <emscripten/emscripten.h>
#include <iostream>
#include <string>
#include <vector>

const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;
// const int TARGET_FPS = 60;

VerilatedContext* contextp_global = nullptr;
Vdemoman* dut_global = nullptr;

SDL_Window* main_window_global = nullptr;
SDL_Renderer* main_renderer_global = nullptr;
SDL_Texture* main_texture_global = nullptr;
std::vector<uint32_t> pixel_buffer_global;

const int H_TOTAL_CLOCKS_VGA = 800;
const int V_TOTAL_LINES_VGA = 525;
const int PIXEL_CLOCKS_PER_FRAME = H_TOTAL_CLOCKS_VGA * V_TOTAL_LINES_VGA;

int frame_log_counter = 0;

void tick_dut_clock()
{
    if (!dut_global || !contextp_global)
        return;
    dut_global->CLOCK_50 = 0;
    dut_global->eval();
    contextp_global->timeInc(1);
    dut_global->CLOCK_50 = 1;
    dut_global->eval();
    contextp_global->timeInc(1);
}

void main_loop_iteration()
{
    if (!dut_global || !contextp_global || !main_renderer_global || !main_texture_global) {
        EM_ASM(Module.printErr("WASM_ERROR: Critical global pointer is null in main_loop_iteration. Halting."));
        emscripten_cancel_main_loop();
        return;
    }

    SDL_Event e;
    while (SDL_PollEvent(&e) != 0) {
        if (e.type == SDL_QUIT) {
            EM_ASM(Module.print("WASM_INFO: SDL_QUIT received."));
            emscripten_cancel_main_loop();
            return;
        } else if (e.type == SDL_KEYDOWN) {
            if (e.key.repeat == 0) {
                switch (e.key.keysym.sym) {
                case SDLK_ESCAPE:
                    EM_ASM(Module.print("WASM_INFO: Escape pressed."));
                    emscripten_cancel_main_loop();
                    return;
                case SDLK_0:
                    dut_global->SW ^= (1 << 0);
                    break;
                case SDLK_1:
                    dut_global->SW ^= (1 << 9);
                    break;
                case SDLK_2:
                    dut_global->SW ^= (1 << 8);
                    break;
                case SDLK_3:
                    dut_global->SW ^= (1 << 7);
                    break;
                case SDLK_4:
                    dut_global->SW ^= (1 << 6);
                    break;
                case SDLK_5:
                    dut_global->SW ^= (1 << 5);
                    break;
                case SDLK_6:
                    dut_global->SW ^= (1 << 4);
                    break;
                case SDLK_7:
                    dut_global->SW ^= (1 << 3);
                    break;
                case SDLK_8:
                    dut_global->SW ^= (1 << 2);
                    break;
                case SDLK_9:
                    dut_global->SW ^= (1 << 1);
                    break;
                case SDLK_u:
                    dut_global->KEY &= ~(1 << 3);
                    break;
                case SDLK_i:
                    dut_global->KEY &= ~(1 << 2);
                    break;
                case SDLK_o:
                    dut_global->KEY &= ~(1 << 1);
                    break;
                case SDLK_p:
                    dut_global->KEY &= ~(1 << 0);
                    break;
                default:
                    break;
                }
            } else {
                switch (e.key.keysym.sym) {
                case SDLK_u:
                    dut_global->KEY &= ~(1 << 3);
                    break;
                case SDLK_i:
                    dut_global->KEY &= ~(1 << 2);
                    break;
                case SDLK_o:
                    dut_global->KEY &= ~(1 << 1);
                    break;
                case SDLK_p:
                    dut_global->KEY &= ~(1 << 0);
                    break;
                default:
                    break;
                }
            }
        } else if (e.type == SDL_KEYUP) {
            switch (e.key.keysym.sym) {
            case SDLK_u:
                dut_global->KEY |= (1 << 3);
                break;
            case SDLK_i:
                dut_global->KEY |= (1 << 2);
                break;
            case SDLK_o:
                dut_global->KEY |= (1 << 1);
                break;
            case SDLK_p:
                dut_global->KEY |= (1 << 0);
                break;
            default:
                break;
            }
        }
    }

    for (int vga_pixel_clk_cycle = 0; vga_pixel_clk_cycle < PIXEL_CLOCKS_PER_FRAME; ++vga_pixel_clk_cycle) {
        tick_dut_clock();
        tick_dut_clock();

        if (contextp_global->gotFinish()) {
            EM_ASM(Module.print("WASM_INFO: Verilator $finish called."));
            emscripten_cancel_main_loop();
            return;
        }

        bool active_display = (dut_global->VGA_BLANK_N == 1);

        if (active_display) {
            int x = dut_global->DEBUG_X;
            int y = dut_global->DEBUG_Y;
            if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
                uint8_t r8 = dut_global->VGA_R;
                uint8_t g8 = dut_global->VGA_G;
                uint8_t b8 = dut_global->VGA_B;
                size_t buffer_index = static_cast<size_t>(y) * SCREEN_WIDTH + x;
                if (buffer_index < pixel_buffer_global.size()) {
                    pixel_buffer_global[buffer_index] = (0xFFU << 24) | (static_cast<uint32_t>(r8) << 16) | (static_cast<uint32_t>(g8) << 8) | static_cast<uint32_t>(b8);
                }
            }
        }
    }

    if (SDL_UpdateTexture(main_texture_global, NULL, pixel_buffer_global.data(), SCREEN_WIDTH * sizeof(uint32_t)) != 0) {
        EM_ASM_({ Module.printErr("WASM_ERROR: SDL_UpdateTexture failed: " + UTF8ToString(SDL_GetError())); });
    }

    if (SDL_SetRenderDrawColor(main_renderer_global, 0, 0, 0, 255) != 0) {
        EM_ASM_({ Module.printErr("WASM_WARNING: SDL_SetRenderDrawColor failed: " + UTF8ToString(SDL_GetError())); });
    }
    if (SDL_RenderClear(main_renderer_global) != 0) {
        EM_ASM_({ Module.printErr("WASM_ERROR: SDL_RenderClear failed: " + UTF8ToString(SDL_GetError())); });
    }

    if (SDL_RenderCopy(main_renderer_global, main_texture_global, NULL, NULL) != 0) {
        EM_ASM_({ Module.printErr("WASM_ERROR: SDL_RenderCopy failed: " + UTF8ToString(SDL_GetError())); });
    }
    SDL_RenderPresent(main_renderer_global);
}

void at_exit_func()
{
    EM_ASM(Module.print('WASM_INFO: atexit_func called. Performing cleanup.'));
}

int main(int argc, char* argv[])
{
    atexit(at_exit_func);
    EM_ASM(Module.print("WASM_INFO: Starting main function..."));

    contextp_global = new VerilatedContext;
    contextp_global->commandArgs(argc, argv);
    dut_global = new Vdemoman { contextp_global };
    EM_ASM(Module.print("WASM_INFO: DUT and contextp created."));

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0) {
        EM_ASM_({ Module.printErr("WASM_ERROR: SDL_Init failed: " + UTF8ToString($0)); }, SDL_GetError());
        delete dut_global;
        delete contextp_global;
        return 1;
    }
    EM_ASM(Module.print("WASM_INFO: SDL_Init successful."));

    main_window_global = SDL_CreateWindow("Verilator VGA Sim",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    if (!main_window_global) {
        EM_ASM_({ Module.printErr("WASM_ERROR: Main Window creation failed: " + UTF8ToString($0)); }, SDL_GetError());
        SDL_Quit();
        delete dut_global;
        delete contextp_global;
        return 1;
    }
    EM_ASM(Module.print("WASM_INFO: Main Window created."));

    main_renderer_global = SDL_CreateRenderer(main_window_global, -1, SDL_RENDERER_ACCELERATED);
    if (!main_renderer_global) {
        EM_ASM_({ Module.printErr("WASM_ERROR: Main Renderer creation failed: " + UTF8ToString($0)); }, SDL_GetError());
        SDL_DestroyWindow(main_window_global);
        SDL_Quit();
        delete dut_global;
        delete contextp_global;
        return 1;
    }
    EM_ASM(Module.print("WASM_INFO: Main Renderer created."));

    main_texture_global = SDL_CreateTexture(main_renderer_global, SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
    if (!main_texture_global) {
        EM_ASM_({ Module.printErr("WASM_ERROR: Main Texture creation failed: " + UTF8ToString($0)); }, SDL_GetError());
        SDL_DestroyRenderer(main_renderer_global);
        SDL_DestroyWindow(main_window_global);
        SDL_Quit();
        delete dut_global;
        delete contextp_global;
        return 1;
    }
    EM_ASM(Module.print("WASM_INFO: Main Texture created."));

    pixel_buffer_global.resize(static_cast<size_t>(SCREEN_WIDTH) * SCREEN_HEIGHT, 0xFF000000);
    EM_ASM(Module.print("WASM_INFO: Pixel buffer resized and initialized."));

    dut_global->reset = 1;
    for (int i = 0; i < 20; ++i) {
        tick_dut_clock();
    }
    dut_global->reset = 0;
    dut_global->eval();
    EM_ASM(Module.print("WASM_INFO: DUT reset complete."));

    dut_global->KEY = 0x0F;
    dut_global->SW = 0x000;
    EM_ASM(Module.print("WASM_INFO: DUT inputs initialized."));

    EM_ASM_(Module.print("WASM_INFO: Starting Emscripten main loop"));
    emscripten_set_main_loop(main_loop_iteration, 0, 1);

    EM_ASM(Module.print("WASM_INFO: Emscripten main loop has exited. Performing cleanup."));

    if (main_texture_global)
        SDL_DestroyTexture(main_texture_global);
    main_texture_global = nullptr;
    if (main_renderer_global)
        SDL_DestroyRenderer(main_renderer_global);
    main_renderer_global = nullptr;
    if (main_window_global)
        SDL_DestroyWindow(main_window_global);
    main_window_global = nullptr;
    SDL_Quit();
    EM_ASM(Module.print("WASM_INFO: SDL resources cleaned up."));

    delete dut_global;
    dut_global = nullptr;
    delete contextp_global;
    contextp_global = nullptr;
    EM_ASM(Module.print("WASM_INFO: Verilator resources cleaned up."));

    EM_ASM(Module.print("WASM_INFO: Main function finished."));
    return 0;
}
