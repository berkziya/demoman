module rom #(parameter HEX_FILE = "rom_data.hex") (
    input clk,
    input rst,
    input [9:0] current_pixel_x, // Current pixel X position
    input [9:0] current_pixel_y, // Current pixel Y position
    input [9:0] posx, // Player's X position
    input [9:0] posy, // Player's Y position
    input [9:0] sprite_height, // Height of the sprite
    input [9:0] sprite_width, // Width of the sprite
    output reg visible_flag, // Flag to indicate if the sprite is visible
    output reg [15:0] data
);
    // ROM data initialization
    reg [15:0] rom_sprite [0:23999]; // enough for 150*157 sprites (23549 entries)
    wire [9:0] relative_x = current_pixel_x - posx;
    wire [9:0] relative_y = current_pixel_y - posy;
    wire [15:0] addr;

    localparam [15:0] TRANSPARENT_COLOR = 16'hFFFF;
    
    wire inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width) &&
                         (current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
    assign addr = (relative_y * sprite_width) + relative_x; // Calculate address in ROM
    

    initial begin
        $readmemh(HEX_FILE, rom_sprite); // Load ROM data from a hex file
    end

    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 16'h0000; // Reset output data
            visible_flag <= 1'b0; // Reset visibility flag
        end else if (inside_sprite && addr < 24000) begin
            // Ensure the address is within bounds of the ROM
            data <= rom_sprite[addr]; // Read data from ROM at the specified address
            visible_flag <= (rom_sprite[addr] != TRANSPARENT_COLOR); // Set visibility flag based on color
        end else begin
            data <= 16'h0000; // Default value if outside sprite bounds or address out of range
            visible_flag <= 1'b0; // Not visible if outside sprite bounds
        end
    end

endmodule