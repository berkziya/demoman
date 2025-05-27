#pragma once

#include <SDL.h>
#include <cstdint> // For uint32_t
#include <string>
#include <vector>

class SdlVideo {
public:
    SdlVideo(const std::string& title, int width, int height, bool use_vsync_if_native_target);
    ~SdlVideo();

    bool initialize(bool is_wasm_target); // Pass target to conditionally use VSYNC
    void update_frame(const std::vector<uint32_t>& pixel_buffer);
    void clear_screen_with_color(uint8_t r, uint8_t g, uint8_t b);

    SDL_Renderer* get_renderer();
    SDL_Window* get_window();
    bool is_initialized() const;

private:
    SDL_Window* m_window;
    SDL_Renderer* m_renderer;
    SDL_Texture* m_texture;
    std::string m_window_title;
    int m_width;
    int m_height;
    bool m_use_vsync_if_native;
    bool m_initialized_successfully;
};