#include "DutController.h"
#include "InputHandler.h"
#include "SdlVideo.h"
#include "SimConfig.h"

#include <emscripten/emscripten.h>
#include <iostream>
#include <vector>

DutController* g_dut_controller_wasm = nullptr;
SdlVideo* g_main_screen_wasm = nullptr;
std::vector<uint32_t>* g_pixel_buffer_wasm = nullptr;
InputHandler* g_input_handler_wasm = nullptr;

void main_loop_iteration_wasm()
{
    if (!g_dut_controller_wasm || !g_main_screen_wasm || !g_pixel_buffer_wasm || !g_input_handler_wasm) {
        EM_ASM(Module.printErr("WASM_ERROR: Critical global pointer is null in main_loop_iteration. Halting."));
        emscripten_cancel_main_loop();
        return;
    }

    // Check for quit request at the beginning of the loop
    if (g_input_handler_wasm->has_quit_been_requested_by_event()) {
        EM_ASM(Module.print("WASM_INFO: Quit requested by event. Cancelling main loop."));
        emscripten_cancel_main_loop();
        return;
    }

    SDL_Event e;
    while (SDL_PollEvent(&e) != 0) {
        g_input_handler_wasm->process_sdl_event(e, *g_dut_controller_wasm);
        // If process_sdl_event signals quit, it will be caught at the start of the next iteration
    }

    // If quit was signaled inside the SDL_PollEvent loop (e.g., ESC), check again
    if (g_input_handler_wasm->has_quit_been_requested_by_event()) {
        EM_ASM(Module.print("WASM_INFO: Quit requested during event polling. Cancelling main loop."));
        emscripten_cancel_main_loop();
        return;
    }

    for (int clk_cycle = 0; clk_cycle < CYCLES_PER_VGA_FRAME; ++clk_cycle) {
        g_dut_controller_wasm->tick_simulation_clock();
        if (g_dut_controller_wasm->has_finished()) {
            EM_ASM(Module.print("WASM_INFO: Verilator $finish called."));
            g_input_handler_wasm->request_quit_externally(); // Signal quit
            emscripten_cancel_main_loop(); // And cancel
            return;
        }

        int x, y;
        uint8_t r, g, b;
        bool active_display;
        if (g_dut_controller_wasm->get_vga_pixel_state(x, y, r, g, b, active_display)) {
            (*g_pixel_buffer_wasm)[static_cast<size_t>(y) * SCREEN_WIDTH + x] = (0xFFU << 24) | (static_cast<uint32_t>(r) << 16) | (static_cast<uint32_t>(g) << 8) | static_cast<uint32_t>(b);
        }
    }
    g_main_screen_wasm->update_frame(*g_pixel_buffer_wasm);
}

void cleanup_wasm_resources()
{
    EM_ASM(Module.print("WASM_INFO: Performing cleanup_wasm_resources."));
    delete g_pixel_buffer_wasm;
    g_pixel_buffer_wasm = nullptr;
    delete g_main_screen_wasm;
    g_main_screen_wasm = nullptr;
    delete g_dut_controller_wasm;
    g_dut_controller_wasm = nullptr;
    delete g_input_handler_wasm;
    g_input_handler_wasm = nullptr; // Clean up InputHandler
    SDL_Quit();
    EM_ASM(Module.print("WASM_INFO: Cleanup complete."));
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
    g_input_handler_wasm = new InputHandler(); // Initialize InputHandler

    if (!g_main_screen_wasm->initialize(true)) {
        EM_ASM(Module.printErr("WASM_ERROR: SdlVideo initialization failed."));
        // No need to delete g_input_handler_wasm here as it's simple, but for complex objects you might
        delete g_main_screen_wasm;
        delete g_dut_controller_wasm;
        delete g_input_handler_wasm;
        SDL_Quit();
        return 1;
    }

    g_pixel_buffer_wasm = new std::vector<uint32_t>(static_cast<size_t>(SCREEN_WIDTH) * SCREEN_HEIGHT, 0xFF000000);
    g_dut_controller_wasm->reset_dut();

    EM_ASM(Module.print("WASM_INFO: Resources initialized. Starting Emscripten main loop..."));
    emscripten_set_main_loop(main_loop_iteration_wasm, 0, 1);

    cleanup_wasm_resources(); // This runs after the loop is explicitly cancelled
    EM_ASM(Module.print("WASM_INFO: Main function after loop exit."));
    return 0;
}
