#pragma once
#include <SDL_events.h> // For SDL_Event

class DutController;

class InputHandler {
public:
    InputHandler();

    // Processes an SDL event and updates the DUT or internal quit state.
    void process_sdl_event(const SDL_Event& event, DutController& dut_controller);

    // Returns true if a quit condition (e.g., SDL_QUIT, ESCAPE) has been signaled
    // by an event processed by this handler.
    bool has_quit_been_requested_by_event() const;

    // Allows external logic (like window close handlers) to signal a quit.
    void request_quit_externally();

private:
    bool m_quit_requested_by_event; // True if an event handled here (SDL_QUIT, ESC) requests quit
};