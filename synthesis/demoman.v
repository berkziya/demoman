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
  inout [35:0] GPIO
);

localparam reset = 1'b0;

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire [3:0] currentstate;

wire effective_clk;
wire [9:0] posx; // Player's X position
wire [9:0] posy; // Player's Y position

reg  [7:0] color_to_vga_driver; // Input color to VGA driver (RRRGGGBB)
wire [9:0] current_pixel_x;     // X-coordinate from vga_driver
wire [9:0] current_pixel_y;     // Y-coordinate from vga_driver
wire       clk_25mhz;
wire       clk_60hz;

reg [7:0] pixel_data;
wire [7:0] pixel_data_idle, pixel_data_move_forward, pixel_data_move_backward, pixel_data_attack_start, pixel_data_attack_end, pixel_data_attack_pull;
reg pixel_visible_flag;
wire pixel_visible_flag_idle, pixel_visible_flag_move_forward, pixel_visible_flag_move_backward, pixel_visible_flag_attack_start, pixel_visible_flag_attack_end, pixel_visible_flag_attack_pull;
wire [9:0] sprite_height = 10'd157; // Height of the sprite
wire [9:0] sprite_width = 10'd150;  // Width of the sprite
wire [9:0] hithurt_x1, hithurt_x2, hithurt_y1, hithurt_y2; // Basic hit hurtbox coordinates
wire [9:0] hurt_x1, hurt_x2, hurt_y1, hurt_y2; // Main hurtbox coordinates
wire inside_sprite; // Flag to check if the current pixel is inside the sprite
wire on_hithurt_border;
wire on_hurt_border;

//=======================================================
//  Structural coding
//=======================================================

clock_divider #(
  .DIV(2)
) clk_vga_inst (
  .clk(CLOCK_50),
  .clk_o(clk_25mhz)
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

assign clk_60hz = current_pixel_y == 10'd479 && current_pixel_x == 10'd639;

assign effective_clk = SW[1] ? ~KEY[0]: clk_60hz;

player #(1'b0) Player1 (
  .clk(effective_clk),
  .rst(reset),
  .left(~KEY[3]),
  .right(~KEY[2]),
  .attack(~KEY[1]),
  .posx(posx),
  .posy(posy),
  .current_state(currentstate),
  .basic_hithurtbox_x1(hithurt_x1),
  .basic_hithurtbox_x2(hithurt_x2),
  .basic_hithurtbox_y1(hithurt_y1),
  .basic_hithurtbox_y2(hithurt_y2),
  .main_hurtbox_x1(hurt_x1),
  .main_hurtbox_x2(hurt_x2),
  .main_hurtbox_y1(hurt_y1),
  .main_hurtbox_y2(hurt_y2)
);

// always @(*) begin
//   color_to_vga_driver = 8'b00100101; // Default color (pink)
//   if (current_pixel_x >= posx && current_pixel_x < posx + 100 &&
//       current_pixel_y >= posy && current_pixel_y < posy + 100) begin
//     color_to_vga_driver =  currentstate == 4'd0 ? 8'b11100000 : // Idle state color (red)
//                            currentstate == 4'd1 ? 8'b00001111 : // Move forward (blue)
//                            currentstate == 4'd2 ? 8'b11110000 : // Move backward (yellow)
//                            currentstate == 4'd3 ? 8'b00011111 : // Attack start (cyan)
//                            currentstate == 4'd4 ? 8'b11111100 : // Attack end (light green)
//                            currentstate == 4'd5 ? 8'b11111111 : // Attack pull (white)
//                            8'b11111111; // Default color
//   end
// end

rom #(.MIF_FILE("../sprites/aaa8.mif")) rom_move_forward_inst (
  // ROM for move forward state
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .visible_flag(pixel_visible_flag_move_forward), // Visibility flag for move forward state
  .data(pixel_data_move_forward)
);

rom #(.MIF_FILE("../sprites/aaa7.mif")) rom_idle_inst (
  // ROM for idle state
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .visible_flag(pixel_visible_flag_idle), // Visibility flag for idle state
  .data(pixel_data_idle)
);

rom #(.MIF_FILE("../sprites/aaa9.mif")) rom_move_backward_inst (
  // ROM for move backward state
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .visible_flag(pixel_visible_flag_move_backward), // Visibility flag for move backward state
  .data(pixel_data_move_backward)
);

rom #(.MIF_FILE("../sprites/aaa10.mif")) rom_attack_start_inst (
  // ROM for attack start state
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .visible_flag(pixel_visible_flag_attack_start), // Visibility flag for attack start state
  .data(pixel_data_attack_start)
);

rom #(.MIF_FILE("../sprites/aaa11.mif")) rom_attack_end_inst (
  // ROM for attack end state
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .visible_flag(pixel_visible_flag_attack_end), // Visibility flag for attack end state
  .data(pixel_data_attack_end)
);

rom #(.MIF_FILE("../sprites/aaa12.mif")) rom_attack_pull_inst (
  // ROM for attack pull state
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .visible_flag(pixel_visible_flag_attack_pull), // Visibility flag for attack pull state
  .data(pixel_data_attack_pull)
);

always @(*) begin
  case (currentstate)
    4'd0: begin
      pixel_data = pixel_data_idle;
      pixel_visible_flag = pixel_visible_flag_idle; end // Idle state
    4'd1: begin
      pixel_data = pixel_data_move_forward;
      pixel_visible_flag = pixel_visible_flag_move_forward; end // Move forward state
    4'd2: begin
      pixel_data = pixel_data_move_backward;
      pixel_visible_flag = pixel_visible_flag_move_backward; end // Move backward state
    4'd3: begin
      pixel_data = pixel_data_attack_start;
      pixel_visible_flag = pixel_visible_flag_attack_start; end // Attack start state
    4'd4: begin
      pixel_data = pixel_data_attack_end;
      pixel_visible_flag = pixel_visible_flag_attack_end; end // Attack end state
    4'd5: begin
      pixel_data = pixel_data_attack_pull;
      pixel_visible_flag = pixel_visible_flag_attack_pull; end // Attack pull state
    default: begin
      pixel_data = 8'hFF; // Default color (white) sprite
      pixel_visible_flag = 1'b1; end // Visible
  endcase
end

assign inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width &&
                        current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
assign on_hithurt_border = (((current_pixel_x == hithurt_x1 || current_pixel_x == hithurt_x2) &&
                             (current_pixel_y >= hithurt_y1 && current_pixel_y <= hithurt_y2)) ||
                            ((current_pixel_y == hithurt_y1 || current_pixel_y == hithurt_y2) &&
                             (current_pixel_x >= hithurt_x1 && current_pixel_x <= hithurt_x2)));
assign on_hurt_border = (((current_pixel_x == hurt_x1 || current_pixel_x == hurt_x2) &&
                          (current_pixel_y >= hurt_y1 && current_pixel_y <= hurt_y2)) ||
                         ((current_pixel_y == hurt_y1 || current_pixel_y == hurt_y2) &&
                          (current_pixel_x >= hurt_x1 && current_pixel_x <= hurt_x2)));

always @(*) begin
  if (current_state == 4'd4) begin // If the current state is attack end
    if (on_hithurt_border) // If the current pixel is on the basic hit hurtbox border
      color_to_vga_driver = 8'11100000; // Red color for basic hit hurtbox border
  end else if (current_state == 4'd5) begin // If the current state is attack pull
    if (on_hithurt_border) // If the current pixel is on the basic hit hurtbox border
      color_to_vga_driver = 8'b11111100; // Yellow color for basic hit hurtbox border
  end else if (on_hurt_border) begin // If the current pixel is on the main hurtbox border
    color_to_vga_driver = 8'b11111100; // Yellow color for main hurtbox border
  end else if (inside_sprite && pixel_visible_flag) begin // If the current pixel is inside the sprite and visible
    color_to_vga_driver = pixel_data;
  end else begin
    color_to_vga_driver = 8'b00100101; // Default color (purple) for background
  end
end

endmodule
