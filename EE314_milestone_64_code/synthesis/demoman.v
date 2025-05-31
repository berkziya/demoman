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

wire  [7:0] color_to_vga_driver; // Input color to VGA driver (RRRGGGBB)
wire [9:0] current_pixel_x;     // X-coordinate from vga_driver
wire [9:0] current_pixel_y;     // Y-coordinate from vga_driver
wire       clk_25mhz;

wire [7:0] pixel_data;
wire pixel_visible_flag;
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

effective_clock_generator effective_clk_inst(
  .SW(SW[1]), // Switches for clock selection
  .KEY(KEY[0]), // Keys for control
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .effective_clk(effective_clk) // Output effective clock signal based on switch state
);

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

rom rom_inst (
  .clk(CLOCK_50),
  .rst(1'b0),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player's X position
  .posy(posy), // Player's Y position
  .sprite_height(sprite_height), // Height of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .currentstate(currentstate),
  .visible_flag(pixel_visible_flag), // Visibility flag for move forward state
  .data(pixel_data)
);

color_decider color_decider_inst(
  .current_pixel_x(current_pixel_x), // Current pixel X coordinate
  .current_pixel_y(current_pixel_y), // Current pixel Y coordinate
  .posx(posx), // X position of the sprite
  .posy(posy), // Y position of the sprite
  .sprite_width(sprite_width), // Width of the sprite
  .sprite_height(sprite_height), // Height of the sprite
  .hithurt_x1(hithurt_x1), // X coordinate of the first corner of the basic hit hurtbox
  .hithurt_x2(hithurt_x2), // X coordinate of the second corner of the basic hit hurtbox
  .hithurt_y1(hithurt_y1), // Y coordinate of the first corner of the basic hit hurtbox
  .hithurt_y2(hithurt_y2), // Y coordinate of the second corner of the basic hit hurtbox
  .hurt_x1(hurt_x1), // X coordinate of the first corner of the main hurtbox
  .hurt_x2(hurt_x2), // X coordinate of the second corner of the main hurtbox
  .hurt_y1(hurt_y1), // Y coordinate of the first corner of the main hurtbox
  .hurt_y2(hurt_y2), // Y coordinate of the second corner of the main hurtbox
  .currentstate(currentstate), // Current state of the sprite
  .pixel_data(pixel_data), // Pixel data for the sprite
  .pixel_visible_flag(pixel_visible_flag), // Flag indicating if the pixel is visible
  .color_to_vga_driver(color_to_vga_driver) // Color to be sent to the VGA driver
);



endmodule
