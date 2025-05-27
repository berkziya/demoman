#include "SdlVideo.h"
#include <iostream> // For error messages

SdlVideo::SdlVideo(const std::string& title, int width, int height, bool use_vsync_if_native_target)
    : m_window(nullptr)
    , m_renderer(nullptr)
    , m_texture(nullptr)
    , m_window_title(title)
    , m_width(width)
    , m_height(height)
    , m_use_vsync_if_native(use_vsync_if_native_target)
    , m_initialized_successfully(false)
{
}

SdlVideo::~SdlVideo()
{
    if (m_texture)
        SDL_DestroyTexture(m_texture);
    if (m_renderer)
        SDL_DestroyRenderer(m_renderer);
    if (m_window)
        SDL_DestroyWindow(m_window);
    // SDL_Quit is usually called globally once in main
}

bool SdlVideo::initialize(bool is_wasm_target)
{
    m_window = SDL_CreateWindow(m_window_title.c_str(),
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        m_width, m_height, SDL_WINDOW_SHOWN);
    if (!m_window) {
        std::cerr << "SdlVideo Error: Failed to create window: " << SDL_GetError() << std::endl;
        return false;
    }

    Uint32 renderer_flags = SDL_RENDERER_ACCELERATED;
    if (!is_wasm_target && m_use_vsync_if_native) {
        renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
    }

    m_renderer = SDL_CreateRenderer(m_window, -1, renderer_flags);
    if (!m_renderer) {
        std::cerr << "SdlVideo Error: Failed to create renderer: " << SDL_GetError() << std::endl;
        // m_window will be destroyed by destructor if we return false
        return false;
    }

    m_texture = SDL_CreateTexture(m_renderer, SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING, m_width, m_height);
    if (!m_texture) {
        std::cerr << "SdlVideo Error: Failed to create texture: " << SDL_GetError() << std::endl;
        return false;
    }
    m_initialized_successfully = true;
    return true;
}

void SdlVideo::update_frame(const std::vector<uint32_t>& pixel_buffer)
{
    if (!m_initialized_successfully || pixel_buffer.size() != static_cast<size_t>(m_width * m_height)) {
        // std::cerr << "SdlVideo Warning: Not initialized or buffer size mismatch." << std::endl;
        return;
    }

    if (SDL_UpdateTexture(m_texture, nullptr, pixel_buffer.data(), m_width * sizeof(uint32_t)) != 0) {
        std::cerr << "SdlVideo Error: SDL_UpdateTexture failed: " << SDL_GetError() << std::endl;
        return;
    }
    if (SDL_RenderClear(m_renderer) != 0) { // Clear with draw color (usually black by default after creation)
        std::cerr << "SdlVideo Warning: SDL_RenderClear failed: " << SDL_GetError() << std::endl;
    }
    if (SDL_RenderCopy(m_renderer, m_texture, nullptr, nullptr) != 0) {
        std::cerr << "SdlVideo Error: SDL_RenderCopy failed: " << SDL_GetError() << std::endl;
        return;
    }
    SDL_RenderPresent(m_renderer);
}

void SdlVideo::clear_screen_with_color(uint8_t r, uint8_t g, uint8_t b)
{
    if (!m_initialized_successfully)
        return;
    SDL_SetRenderDrawColor(m_renderer, r, g, b, 255);
    SDL_RenderClear(m_renderer);
    SDL_RenderPresent(m_renderer);
}

SDL_Renderer* SdlVideo::get_renderer()
{
    return m_renderer;
}

SDL_Window* SdlVideo::get_window()
{
    return m_window;
}

bool SdlVideo::is_initialized() const
{
    return m_initialized_successfully;
}
