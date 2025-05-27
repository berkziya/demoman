#include "InputHandler.h"
#include "DutController.h"

InputHandler::InputHandler()
    : m_quit_requested_by_event(false)
{
}

void InputHandler::process_sdl_event(const SDL_Event& event, DutController& dut_controller)
{
    if (event.type == SDL_QUIT) {
        m_quit_requested_by_event = true;
        return;
    }

    if (event.type == SDL_KEYDOWN) {
        // SWitches toggle (Kbd 1-9 for SW9-1, 0 for SW0)
        // Process toggles only on initial press (repeat == 0)
        if (event.key.repeat == 0) {
            switch (event.key.keysym.sym) {
            case SDLK_0:
                dut_controller.toggle_switch(0);
                break;
            case SDLK_1:
                dut_controller.toggle_switch(9);
                break; // SW9 mapped to 1
            case SDLK_2:
                dut_controller.toggle_switch(8);
                break; // SW8 mapped to 2
            case SDLK_3:
                dut_controller.toggle_switch(7);
                break;
            case SDLK_4:
                dut_controller.toggle_switch(6);
                break;
            case SDLK_5:
                dut_controller.toggle_switch(5);
                break;
            case SDLK_6:
                dut_controller.toggle_switch(4);
                break;
            case SDLK_7:
                dut_controller.toggle_switch(3);
                break;
            case SDLK_8:
                dut_controller.toggle_switch(2);
                break;
            case SDLK_9:
                dut_controller.toggle_switch(1);
                break; // SW1 mapped to 9
            default:
                break;
            }
        }

        // KEYs: Press makes bit LOW (0) (Kbd U,I,O,P for KEY3-0)
        // Allow auto-repeat for these (no check for event.key.repeat == 0)
        switch (event.key.keysym.sym) {
        case SDLK_ESCAPE:
            m_quit_requested_by_event = true; // ESC key signals quit
            break;
        case SDLK_u:
            dut_controller.set_key_state(3, true);
            break; // KEY3 LOW
        case SDLK_i:
            dut_controller.set_key_state(2, true);
            break; // KEY2 LOW
        case SDLK_o:
            dut_controller.set_key_state(1, true);
            break; // KEY1 LOW
        case SDLK_p:
            dut_controller.set_key_state(0, true);
            break; // KEY0 LOW
        default:
            break;
        }
    } else if (event.type == SDL_KEYUP) {
        // KEYs: Release makes bit HIGH (1)
        switch (event.key.keysym.sym) {
        case SDLK_u:
            dut_controller.set_key_state(3, false);
            break; // KEY3 HIGH
        case SDLK_i:
            dut_controller.set_key_state(2, false);
            break; // KEY2 HIGH
        case SDLK_o:
            dut_controller.set_key_state(1, false);
            break; // KEY1 HIGH
        case SDLK_p:
            dut_controller.set_key_state(0, false);
            break; // KEY0 HIGH
        default:
            break;
        }
    }
}

bool InputHandler::has_quit_been_requested_by_event() const
{
    return m_quit_requested_by_event;
}

void InputHandler::request_quit_externally()
{
    m_quit_requested_by_event = true; // Or a separate flag if distinction is needed
}