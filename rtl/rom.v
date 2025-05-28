module rom #( parameter HEX_FILE = "rom_data.hex") (
    input clk,
    input rst,
    input [9:0] current_pixel_x, // Current pixel X position
    input [9:0] current_pixel_y, // Current pixel Y position
    input [9:0] posx, // Player's X position
    input [9:0] posy, // Player's Y position
    output [15:0] sprite_height,
    output [15:0] sprite_width,
    output reg [15:0] data
);
    // ROM data initialization
    reg [15:0] rom_sprite [0:1023]; // 1024 entries of 16-bit data
    wire [9:0] addr; // Address for ROM

    initial begin
        $readmemh("rom_data.hex", rom_sprite); // Load ROM data from a hex file
    end

    assign sprite_width = rom_sprite[0][15:0]; // Assuming the first entry contains width
    assign sprite_height = rom_sprite[1][15:0]; // Assuming the second entry contains height
    
    addr = (current_pixel_y - posy) * sprite_width + (current_pixel_x - posx); // Calculate address based on pixel position


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 16'h0000; // Reset output data
        end else begin
            data <= rom_sprite[addr]; // Read data from ROM at the specified address
        end
    end

endmodule