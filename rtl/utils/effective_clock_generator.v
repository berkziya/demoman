module effective_clock_generator (
    input SW, // Switches for clock selection
    input KEY, // Keys for control
    input [9:0] current_pixel_x, // Current pixel X coordinate
    input [9:0] current_pixel_y, // Current pixel Y coordinate
    output effective_clk // Output effective clock signal based on switch state
);
    wire clk_60hz; // 60Hz clock signal
    assign clk_60hz = current_pixel_y == 10'd479 && current_pixel_x == 10'd639;
    assign effective_clk = SW ? ~KEY: clk_60hz;
endmodule