module rom #( parameter HEX_FILE = "rom_data.hex",
            parameter SPRITE_HEIGHT = 32,
            parameter SPRITE_WIDTH = 32) (
    input clk,
    input rst,
    input [9:0] current_pixel_x, // Current pixel X position
    input [9:0] current_pixel_y, // Current pixel Y position
    input [9:0] posx, // Player's X position
    input [9:0] posy, // Player's Y position
    output reg [15:0] data
);
    // ROM data initialization
    reg [15:0] rom_sprite [0:1023]; // 1024 entries of 16-bit data
    wire [9:0] relative_x = current_pixel_x - posx;
    wire [9:0] relative_y = current_pixel_y - posy;
    wire [15:0] addr;

    assign sprite_height = SPRITE_HEIGHT; // Assign sprite height
    assign sprite_width = SPRITE_WIDTH; // Assign sprite width
    assign addr = (relative_y * sprite_width) + relative_x; // Calculate address in ROM


    initial begin
        $readmemh(HEX_FILE, rom_sprite); // Load ROM data from a hex file
    end

    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 16'h0000; // Reset output data
        end else begin
            data <= rom_sprite[addr]; // Read data from ROM at the specified address
        end
    end

endmodule