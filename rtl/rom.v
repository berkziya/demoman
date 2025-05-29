module rom #(parameter MIF_FILE = ".hex") (
    input clk,
    input rst,
    input [9:0] current_pixel_x, // Current pixel X position
    input [9:0] current_pixel_y, // Current pixel Y position
    input [9:0] posx, // Player's X position
    input [9:0] posy, // Player's Y position
    input [9:0] sprite_height, // Height of the sprite
    input [9:0] sprite_width, // Width of the sprite
    output reg visible_flag, // Flag to indicate if the sprite is visible
    output reg [7:0] data
);
    // ROM data initialization
    localparam image_size = 150 * 157; // Size of the sprite in pixels
	wire [7:0] rom_sprite;
    wire [9:0] relative_x = current_pixel_x - posx;
    wire [9:0] relative_y = current_pixel_y - posy;
    wire [15:0] addr;

    localparam [7:0] TRANSPARENT_COLOR = 8'b11100011; // Transparent color value
    
    wire inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width) &&
                         (current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
    assign addr = (relative_y * 150) + relative_x; // Calculate address in ROM
    
    rom_demo rom_demo_inst (
        .address(addr),
        .clock(clk),
        .q(rom_sprite)
    );


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 8'b00000000; // Reset output data
            visible_flag <= 1'b0; // Reset visibility flag
        end else if (inside_sprite && addr > 0 && addr < image_size) begin
            // Ensure the address is within bounds of the ROM
            data <= rom_sprite; // Read data from ROM at the specified address
            visible_flag <= (rom_sprite != TRANSPARENT_COLOR); // Set visibility flag based on color
        end else begin
            data <= 8'b00000000; // Default value if outside sprite bounds or address out of range
            visible_flag <= 1'b0; // Not visible if outside sprite bounds
        end
    end

endmodule
