#include "Vdemoman.h" // Should match your top-level Verilog module name
#include "verilated.h"
#include <SDL.h>
#include <iostream>
#include <vector>

// Screen dimensions
const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;
const int SCREEN_FPS = 60;
const int SCREEN_TICKS_PER_FRAME = 1000 / SCREEN_FPS;

void tick(Vdemoman *dut, VerilatedContext *contextp) {
  dut->CLOCK_50 = 0; // Drive the actual clock input
  dut->eval();
  contextp->timeInc(1);

  dut->CLOCK_50 = 1;
  dut->eval();
  contextp->timeInc(1);
}

int main(int argc, char *argv[]) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vdemoman *dut = new Vdemoman{contextp};

  // SDL Initialization
  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
    delete dut;
    delete contextp;
    return 1;
  }

  SDL_Window *window = SDL_CreateWindow("Verilator VGA Sim - demoman",
                                        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                        SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
  if (!window) {
    std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
    SDL_Quit();
    delete dut;
    delete contextp;
    return 1;
  }

  SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
  if (!renderer) {
    std::cerr << "Renderer could not be created! SDL_Error: " << SDL_GetError() << std::endl;
    SDL_DestroyWindow(window);
    SDL_Quit();
    delete dut;
    delete contextp;
    return 1;
  }

  SDL_Texture *texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                           SDL_TEXTUREACCESS_STREAMING,
                                           SCREEN_WIDTH, SCREEN_HEIGHT);
  if (!texture) {
    std::cerr << "Texture could not be created! SDL_Error: " << SDL_GetError() << std::endl;
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    delete dut;
    delete contextp;
    return 1;
  }

  std::vector<uint32_t> pixel_buffer(SCREEN_WIDTH * SCREEN_HEIGHT, 0xFF000000); // Opaque Black

  // Reset the DUT
  dut->reset = 1; // Assert reset
  // Important: Provide clock ticks during reset for synchronous resets to propagate
  for (int i = 0; i < 20; ++i) {
    tick(dut, contextp);
  }
  dut->reset = 0; // De-assert reset
  dut->eval();    // Evaluate once after reset is low

  // Initialize other DUT inputs if necessary
  dut->KEY = 0xF; // Example: All keys up (if active low) or 0x0 (if active high)
  dut->SW = 0x0;  // Example: All switches off

  bool running = true;
  SDL_Event e;
  bool last_vsync = dut->VGA_VS;

  // VGA timing parameters (used to determine cycles per frame)
  // Standard 640x480 @ 60Hz (total 800 horizontal clocks, 525 vertical lines)
  // These values should match the parameters in your vga_driver.v
  const int H_TOTAL_CLOCKS = 800; // H_ACTIVE + H_FRONT + H_PULSE + H_BACK
  const int V_TOTAL_LINES = 525;  // V_ACTIVE + V_FRONT + V_PULSE + V_BACK
  const int cycles_per_vga_frame = H_TOTAL_CLOCKS * V_TOTAL_LINES; // Cycles of the VGA pixel clock (25MHz)

  Uint32 frame_start_time;

  // Main simulation loop
  while (running && !contextp->gotFinish()) {
    frame_start_time = SDL_GetTicks();

    // Handle SDL events
    while (SDL_PollEvent(&e) != 0) {
      if (e.type == SDL_QUIT) {
        running = false;
      } else if (e.type == SDL_KEYDOWN) {
        switch (e.key.keysym.sym) {
          case SDLK_ESCAPE: running = false; break;
          // Assuming active HIGH for Verilog inputs for simplicity
          case SDLK_0: dut->KEY |= (1 << 0); break;
          case SDLK_1: dut->KEY |= (1 << 1); break;
          case SDLK_2: dut->KEY |= (1 << 2); break;
          case SDLK_3: dut->KEY |= (1 << 3); break;
          case SDLK_a: dut->SW |= (1 << 0); break;
          case SDLK_s: dut->SW |= (1 << 1); break;
          case SDLK_d: dut->SW |= (1 << 2); break;
          // ...
          case SDLK_SEMICOLON: dut->SW |= (1 << 9); break;
        }
      } else if (e.type == SDL_KEYUP) {
        switch (e.key.keysym.sym) {
          case SDLK_0: dut->KEY &= ~(1 << 0); break;
          case SDLK_1: dut->KEY &= ~(1 << 1); break;
          case SDLK_2: dut->KEY &= ~(1 << 2); break;
          case SDLK_3: dut->KEY &= ~(1 << 3); break;
          case SDLK_a: dut->SW &= ~(1 << 0); break;
          case SDLK_s: dut->SW &= ~(1 << 1); break;
          case SDLK_d: dut->SW &= ~(1 << 2); break;
          // ...
          case SDLK_SEMICOLON: dut->SW &= ~(1 << 9); break;
        }
      }
    }

    bool frame_rendered_this_loop = false;
    for (int vga_clk_cycle = 0; vga_clk_cycle < cycles_per_vga_frame && running; ++vga_clk_cycle) {
      tick(dut, contextp);

      // Read VGA outputs (these are based on the 25MHz clock domain)
      bool active_display = (dut->VGA_BLANK_N == 0); // Active low blanking

      if (active_display) {
        int x = dut->DEBUG_X;
        int y = dut->DEBUG_Y;
        if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
          uint32_t r_val = dut->VGA_R;
          uint32_t g_val = dut->VGA_G;
          uint32_t b_val = dut->VGA_B;
          pixel_buffer[y * SCREEN_WIDTH + x] = (0xFFU << 24) | (r_val << 16) | (g_val << 8) | b_val;
        }
      }

      // VSync detection for rendering the frame to SDL
      bool current_vsync = dut->VGA_VS;
      if (last_vsync && !current_vsync) { // Falling edge of VSync
        SDL_UpdateTexture(texture, NULL, pixel_buffer.data(), SCREEN_WIDTH * sizeof(uint32_t));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
        frame_rendered_this_loop = true;
        // break; // Optional: Render strictly once per VSync falling edge
      }
      last_vsync = current_vsync;

      if (contextp->gotFinish()) {
        running = false;
        break;
      }
    }

    // Fallback rendering if VSync wasn't hit (e.g., loop finished by cycle count)
    if (!frame_rendered_this_loop && running) {
      SDL_UpdateTexture(texture, NULL, pixel_buffer.data(), SCREEN_WIDTH * sizeof(uint32_t));
      SDL_RenderClear(renderer);
      SDL_RenderCopy(renderer, texture, NULL, NULL);
      SDL_RenderPresent(renderer);
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

  SDL_DestroyTexture(texture);
  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();

  return 0;
}
