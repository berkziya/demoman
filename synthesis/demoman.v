module demoman(
  /////////// CLOCK ///////////
  input CLOCK2_50,
  input CLOCK3_50,
  input CLOCK4_50,
  input CLOCK_50,

  /////////// SDRAM ///////////
  output [12:0] DRAM_ADDR,
  output  [1:0] DRAM_BA,
  output        DRAM_CAS_N,
  output        DRAM_CKE,
  output        DRAM_CLK,
  output        DRAM_CS_N,
  inout  [15:0] DRAM_DQ,
  output        DRAM_LDQM,
  output        DRAM_RAS_N,
  output        DRAM_UDQM,
  output        DRAM_WE_N,

  /////////// SEG7 ///////////
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,

  /////////// KEY ///////////
  input [3:0] KEY,

  /////////// LED ///////////
  output [9:0] LEDR,

  /////////// SW ///////////
  input [9:0] SW,

  /////////// VGA ///////////
  output       VGA_BLANK_N,
  output [7:0] VGA_B,
  output       VGA_CLK,
  output [7:0] VGA_G,
  output       VGA_HS,
  output [7:0] VGA_R,
  output       VGA_SYNC_N,
  output       VGA_VS,

  //////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
  inout [35:0] GPIO,

  /////////// SIM ///////////
  output [9:0] DEBUG_X,
  output [9:0] DEBUG_Y,
  input        reset
);

//=======================================================
//  REG/WIRE declarations
//=======================================================

wire left, right, attack;


wire effective_clk;
wire [9:0] posx; // Player's X position
wire [9:0] posy; // Player's Y position

reg  [7:0] color_to_vga_driver; // Input color to VGA driver (RRRGGGBB)
wire [9:0] current_pixel_x;     // X-coordinate from vga_driver
wire [9:0] current_pixel_y;     // Y-coordinate from vga_driver
wire       clk_25mhz;
wire       clk_60hz;

wire [15:0] pixel_data, pixel_data_idle, pixel_data_move, pixel_data_attack_start, pixel_data_attack_end, pixel_data_attack_pull;
wire [15:0] sprite_height, sprite_width;
wire [15:0] sprite_height_idle, sprite_width_idle;
wire [15:0] sprite_height_move, sprite_width_move;
wire [15:0] sprite_height_attack_start, sprite_width_attack_start;
wire [15:0] sprite_height_attack_end, sprite_width_attack_end;
wire [15:0] sprite_height_attack_pull, sprite_width_attack_pull;

//=======================================================
//  Structural coding
//=======================================================
assign left = ~KEY[3];   // Left key pressed
assign right = ~KEY[2];  // Right key pressed
assign attack = ~KEY[1]; // Attack key pressed


assign DEBUG_X = current_pixel_x;
assign DEBUG_Y = current_pixel_y;

clock_divider #(
  .DIV(2)
) clk_vga_inst (
  .clk(CLOCK_50),
  .rst(reset),
  .clk_o(clk_25mhz)
);

clock_divider #(
  .DIV(83333) // 50 MHz to 60 Hz
) clk_60hz_inst (
  .clk(CLOCK_50),
  .rst(reset),
  .clk_o(clk_60hz)
);

// Instantiate the VGA driver
vga_driver vga_inst (
  .clock(clk_25mhz),
  .reset(reset),
  .color_in(color_to_vga_driver), // Color data for the current pixel
  .next_x(current_pixel_x),       // Output: X-coordinate of the pixel being drawn
  .next_y(current_pixel_y),       // Output: Y-coordinate of the pixel being drawn
  .hsync(VGA_HS),                 // Output: Horizontal sync
  .vsync(VGA_VS),                 // Output: Vertical sync
  .red(VGA_R),                    // Output: Red component
  .green(VGA_G),                  // Output: Green component
  .blue(VGA_B),                   // Output: Blue component
  .sync(),                        // vga_driver's composite sync output (can be left unconnected)
  .clk(VGA_CLK),                  // vga_driver passes its clock input to this VGA connector pin
  .blank(VGA_BLANK_N)             // Output: High during active display period
);

// assign clk_60hz = current_pixel_y == 10'd479;

assign effective_clk = SW[1] ? clk_60hz : ~KEY[0];

wire [3:0] currentstate;

player #(1'b0) Player1 (
  .clk(effective_clk),
  .rst(1'b0),
  .left(left),
  .right(right),
  .attack(attack),
  .posx(posx),
  .posy(posy),
  .current_state(currentstate)
);

always @(*) begin
  color_to_vga_driver = 8'h00; // Background color (dark gray)
  if (current_pixel_x >= posx && current_pixel_x < posx + 100 &&
      current_pixel_y >= posy && current_pixel_y < posy + 100) begin
    color_to_vga_driver =  currentstate == 4'd0 ? 8'b11100000 : // Idle state color (red)
                           currentstate == 4'd1 ? 8'b00001111 : // Move forward (blue)
                           currentstate == 4'd2 ? 8'b11110000 : // Move backward (yellow)
                           currentstate == 4'd3 ? 8'b00011111 : // Attack start (cyan)
                           currentstate == 4'd4 ? 8'b11111100 : // Attack end (light green)
                           currentstate == 4'd5 ? 8'b11111111 : // Attack pull (white)
                           8'h00; // Default color
  end
end


rom #(HEX_FILE("rom_data_idle.hex")) rom_inst (
  .clk(effective_clk),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height_idle), // Height of the sprite
  .sprite_width(sprite_width_idle), // Width of the sprite
  .data(pixel_data_idle)
);

rom #(HEX_FILE("rom_data_move.hex")) rom_move_inst (
  .clk(effective_clk),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height_move), // Height of the sprite
  .sprite_width(sprite_width_move), // Width of the sprite
  .data(pixel_data_move)
);

rom #(HEX_FILE("rom_data_attack_start.hex")) rom_attack_start_inst (
  .clk(effective_clk),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height_attack_start), // Height of the sprite
  .sprite_width(sprite_width_attack_start), // Width of the sprite
  .data(pixel_data_attack_start)
);

rom #(HEX_FILE("rom_data_attack_end.hex")) rom_attack_end_inst (
  .clk(effective_clk),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height_attack_end), // Height of the sprite
  .sprite_width(sprite_width_attack_end), // Width of the sprite
  .data(pixel_data_attack_end)
);
rom #(HEX_FILE("rom_data_attack_pull.hex")) rom_attack_pull_inst (
  .clk(effective_clk),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height_attack_pull), // Height of the sprite
  .sprite_width(sprite_width_attack_pull), // Width of the sprite
  .data(pixel_data_attack_pull)
);

always @(*) begin
  case (currentstate)
    4'd0: begin pixel_data = pixel_data_idle; sprite_height = sprite_height_idle; sprite_width = sprite_width_idle; end // Idle state
    4'd1 | 4'd2: begin pixel_data = pixel_data_move; sprite_height = sprite_height_move; sprite_width = sprite_width_move; end // Move forward/backward
    4'd3: begin pixel_data = pixel_data_attack_start; sprite_height = sprite_height_attack_start; sprite_width = sprite_width_attack_start; end // Attack start
    4'd4: begin pixel_data = pixel_data_attack_end; sprite_height = sprite_height_attack_end; sprite_width = sprite_width_attack_end; end // Attack end
    4'd5: begin pixel_data = pixel_data_attack_pull; sprite_height = sprite_height_attack_pull; sprite_width = sprite_width_attack_pull; end // Attack pull
    default: pixel_data = 16'h0000_1111_1111; // Default color (black)
  endcase
end


assign inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width &&
                          current_pixel_y >= posy && current_pixel_y < posy + sprite_height);

assign color_to_vga_driver = inside_sprite ? {
  pixel_data[15:11], // Red component
  pixel_data[10:5],  // Green component
  pixel_data[4:0]    // Blue component
} : 8'h00; // Background color (dark gray)

endmodule
