module rom_but_only_digits (
  input clk,
  input [9:0] relative_x,
  input [9:0] relative_y,
  input [6:0] game_duration,

  output reg [7:0] pixel_data
);
  // --- Basic Colors ---
  localparam COUNTER_COLOR     = 8'b00000000; // Color for the digits
  localparam TRANSPARENT_COLOR = 8'b11100011; // Color for transparency

  // --- Sprite & ROM Configuration ---
  // Source ROM dimensions (the actual 1x sprite data)
  localparam ROM_WIDTH         = 10;
  localparam ROM_HEIGHT        = 13;
  localparam ROM_PIXELS        = ROM_WIDTH * ROM_HEIGHT;
  localparam ROM_DEPTH_WORDS   = 17;
  localparam ROM_ADDR_WIDTH    = 5;

  // Scaled-up display dimensions
  localparam SCALE_FACTOR      = 4;
  localparam DISPLAY_WIDTH     = ROM_WIDTH * SCALE_FACTOR;
  localparam DISPLAY_HEIGHT    = ROM_HEIGHT * SCALE_FACTOR;

  wire [3:0] digit_10s       = game_duration / 10;
  wire [3:0] digit_1s        = game_duration % 10;

  // --- Coordinate & Address Calculation ---
  // 1. Find the X coordinate within a single 40x40 digit display area
  wire [9:0] x_in_display = (relative_x < DISPLAY_WIDTH) ? relative_x : relative_x - DISPLAY_WIDTH;

  wire [9:0] rom_coord_x = x_in_display >> 2; // Scale down from 0-39 to 0-9
  wire [9:0] rom_coord_y = relative_y >> 2;   // Scale down from 0-51 to 0-12

  // 3. Calculate the linear pixel address within the 10x13 ROM
  wire [7:0] rom_pixel_address = rom_coord_y * ROM_WIDTH + rom_coord_x;

  // 4. Calculate the final byte address and bit index for the ROM hardware
  wire [ROM_ADDR_WIDTH-1:0] rom_byte_address = rom_pixel_address >> 3;
  wire [2:0]                bit_select       = ~(rom_pixel_address % 8);

  // --- ROM Instantiations ---
  // Note: These ROMs must be generated with DEPTH=17 and WIDTH_A=8, WIDTHAD_A=5
  wire [7:0] out0, out1, out2, out3, out4, out5, out6, out7, out8, out9;

  rom_digit0 u0 (.clock(clk), .address(rom_byte_address), .q(out0));
  rom_digit1 u1 (.clock(clk), .address(rom_byte_address), .q(out1));
  rom_digit2 u2 (.clock(clk), .address(rom_byte_address), .q(out2));
  rom_digit3 u3 (.clock(clk), .address(rom_byte_address), .q(out3));
  rom_digit4 u4 (.clock(clk), .address(rom_byte_address), .q(out4));
  rom_digit5 u5 (.clock(clk), .address(rom_byte_address), .q(out5));
  rom_digit6 u6 (.clock(clk), .address(rom_byte_address), .q(out6));
  rom_digit7 u7 (.clock(clk), .address(rom_byte_address), .q(out7));
  rom_digit8 u8 (.clock(clk), .address(rom_byte_address), .q(out8));
  rom_digit9 u9 (.clock(clk), .address(rom_byte_address), .q(out9));

  always @(*) begin
    // Perform boundary checks first using the scaled-up display dimensions
    if (relative_y >= DISPLAY_HEIGHT || relative_x >= (DISPLAY_WIDTH * 2)) begin
      pixel_data = TRANSPARENT_COLOR;
    end else if (relative_x < DISPLAY_WIDTH) begin
      // Handle the Tens Digit (left side)
      case (digit_10s)
        4'd0:   pixel_data = out0[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd1:   pixel_data = out1[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd2:   pixel_data = out2[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd3:   pixel_data = out3[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd4:   pixel_data = out4[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd5:   pixel_data = out5[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd6:   pixel_data = out6[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd7:   pixel_data = out7[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd8:   pixel_data = out8[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd9:   pixel_data = out9[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        default: pixel_data = TRANSPARENT_COLOR;
      endcase
    end else begin
      // Handle the Ones Digit (right side)
      case (digit_1s)
        4'd0:   pixel_data = out0[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd1:   pixel_data = out1[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd2:   pixel_data = out2[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd3:   pixel_data = out3[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd4:   pixel_data = out4[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd5:   pixel_data = out5[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd6:   pixel_data = out6[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd7:   pixel_data = out7[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd8:   pixel_data = out8[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        4'd9:   pixel_data = out9[bit_select] ? COUNTER_COLOR : TRANSPARENT_COLOR;
        default: pixel_data = TRANSPARENT_COLOR;
      endcase
    end
  end

endmodule
