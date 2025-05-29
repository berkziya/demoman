module rom #(parameter HEX_FILE = "rom_data.hex") (
    input clk,
    input rst,
    input [9:0] current_pixel_x, // Current pixel X position
    input [9:0] current_pixel_y, // Current pixel Y position
    input [9:0] posx, // Player's X position
    input [9:0] posy, // Player's Y position
    input [9:0] sprite_height, // Height of the sprite
    input [9:0] sprite_width, // Width of the sprite
    output reg [15:0] data
);
    // ROM data initialization
    reg [15:0] rom_sprite [0:23999]; // 24000 entries for a sprite of 100x240 pixels (16 bits per pixel)
    wire [9:0] relative_x = current_pixel_x - posx;
    wire [9:0] relative_y = current_pixel_y - posy;
    wire [15:0] addr;
    wire inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width) &&
                         (current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
    assign addr = (relative_y * sprite_width) + relative_x; // Calculate address in ROM
    

    initial begin
        $readmemh(HEX_FILE, rom_sprite); // Load ROM data from a hex file
    end

    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 16'h0000; // Reset output data
        end else if (inside_sprite && addr < 24000) begin
            // Ensure the address is within bounds of the ROM
            data <= rom_sprite[addr]; // Read data from ROM at the specified address
        end else begin
            data <= 16'h0000; // Default value if outside sprite bounds or address out of range
        end
    end

endmodule