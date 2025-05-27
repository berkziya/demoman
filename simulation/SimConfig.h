#pragma once

// Screen dimensions
const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;

// VGA Timing (example, adjust to your design if different)
const int H_TOTAL_CLOCKS = 800;
const int V_TOTAL_LINES = 525;
const int CYCLES_PER_VGA_FRAME = H_TOTAL_CLOCKS * V_TOTAL_LINES;

// Font for native status window
inline const char* FONT_PATH = "Roboto_Condensed-Regular.ttf"; // Make sure this font is accessible
const int FONT_SIZE = 18;

// Status window dimensions (native only)
const int STATUS_WINDOW_WIDTH = 500;
const int STATUS_WINDOW_HEIGHT = 300;