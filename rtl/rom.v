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
	wire [7:0] rom_sprite,
               rom_sprite_idle, 
               rom_sprite_forward, 
               rom_sprite_backward, 
               rom_sprite_attack_start, 
               rom_sprite_attack_end, 
               rom_sprite_attack_pull;
    wire [9:0] relative_x = current_pixel_x - posx;
    wire [9:0] relative_y = current_pixel_y - posy;
    wire [14:0] addr;

    localparam [7:0] TRANSPARENT_COLOR = 8'b11100011; // Transparent color value
    
    wire inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width) &&
                         (current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
    assign addr = (relative_y * 15'd150) + relative_x; // Calculate address in ROM
    
    rom_demo_idle rom_demo_inst_idle (
        .address(addr),
        .clock(clk),
        .q(rom_sprite_idle)
    );
    rom_demo_forward rom_demo_forward_inst (
        .address(addr),
        .clock(clk),
        .q(rom_sprite_forward)
    );
    rom_demo_backward rom_demo_backward_inst (
        .address(addr),
        .clock(clk),
        .q(rom_sprite_backward)
    );
    rom_demo_attack_start rom_demo_attack_start_inst (
        .address(addr),
        .clock(clk),
        .q(rom_sprite_attack_start)
    );
    rom_demo_start_end rom_attack_end_inst (
        .address(addr),
        .clock(clk),
        .q(rom_sprite_attack_end)
    );
    rom_demo_start_pull rom_attack_pull_inst (
        .address(addr),
        .clock(clk),
        .q(rom_sprite_attack_pull)
    );

always @(*) begin
  case (currentstate)
    4'd0: rom_sprite = rom_sprite_idle; // Idle state
    4'd1: rom_sprite = rom_sprite_forward; // Move forward state
    4'd2: rom_sprite = rom_sprite_backward; // Move backward state
    4'd3: rom_sprite = rom_sprite_attack_start; // Attack start state
    4'd4: rom_sprite = rom_sprite_attack_end; // Attack end state
    4'd5: rom_sprite = rom_sprite_attack_pull; // Attack pull state
    default: rom_sprite = 8'b00100101; // Default color (white) sprite
  endcase
end

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
