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
assign left = ~KEY[3];   // Left key pressed
assign right = ~KEY[2];  // Right key pressed
assign attack = ~KEY[1]; // Attack key pressed

wire effective_clk;
wire [9:0] posx; // Player's X position
wire [9:0] posy; // Player's Y position

reg  [7:0] color_to_vga_driver; // Input color to VGA driver (RRRGGGBB)
wire [9:0] current_pixel_x;     // X-coordinate from vga_driver
wire [9:0] current_pixel_y;     // Y-coordinate from vga_driver
wire       clk_25mhz;
wire       clk_60hz;

//=======================================================
//  Structural coding
//=======================================================

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

endmodule
