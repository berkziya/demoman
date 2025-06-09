module rom_but_only_digits (
  input clk,
  input [9:0] relative_x,
  input [9:0] relative_y,
  input [6:0] game_duration,

  output reg [7:0] pixel_data
);
localparam TRANSPARENT_COLOR = 8'b11100011; // Transparent color (magenta)
localparam SPRITE_WIDTH = 10;
localparam SPRITE_HEIGHT = 13;
localparam ROM_SIZE = SPRITE_WIDTH * SPRITE_HEIGHT;

wire [6:0] digit_10s = game_duration / 10;
wire [6:0] digit_1s = game_duration % 10;

wire [8:0] address = relative_x < SPRITE_WIDTH ?
                    (relative_y * SPRITE_WIDTH + relative_x) :
                    (relative_y * SPRITE_WIDTH + (relative_x - SPRITE_WIDTH));

wire [7:0] out0, out1, out2, out3, out4, out5, out6, out7, out8, out9;

rom_digit0 u0 (.clock(clk), .address(address), .q(out0));
rom_digit1 u1 (.clock(clk), .address(address), .q(out1));
rom_digit2 u2 (.clock(clk), .address(address), .q(out2));
rom_digit3 u3 (.clock(clk), .address(address), .q(out3));
rom_digit4 u4 (.clock(clk), .address(address), .q(out4));
rom_digit5 u5 (.clock(clk), .address(address), .q(out5));
rom_digit6 u6 (.clock(clk), .address(address), .q(out6));
rom_digit7 u7 (.clock(clk), .address(address), .q(out7));
rom_digit8 u8 (.clock(clk), .address(address), .q(out8));
rom_digit9 u9 (.clock(clk), .address(address), .q(out9));

always @(*) begin
  if (relative_y >= SPRITE_HEIGHT) begin
    pixel_data = TRANSPARENT_COLOR; // Outside the sprite height
  end else if (relative_x >= SPRITE_WIDTH * 2) begin
    pixel_data = TRANSPARENT_COLOR; // Outside the sprite width
  end else if (address >= ROM_SIZE) begin
    pixel_data = TRANSPARENT_COLOR; // Invalid address
  end else if (relative_x < SPRITE_WIDTH) begin
    case (digit_10s)
      7'd0: pixel_data = out0;
      7'd1: pixel_data = out1;
      7'd2: pixel_data = out2;
      7'd3: pixel_data = out3;
      7'd4: pixel_data = out4;
      7'd5: pixel_data = out5;
      7'd6: pixel_data = out6;
      7'd7: pixel_data = out7;
      7'd8: pixel_data = out8;
      7'd9: pixel_data = out9;
      default: pixel_data = TRANSPARENT_COLOR;
    endcase
  end else begin
    case (digit_1s)
      7'd0: pixel_data = out0;
      7'd1: pixel_data = out1;
      7'd2: pixel_data = out2;
      7'd3: pixel_data = out3;
      7'd4: pixel_data = out4;
      7'd5: pixel_data = out5;
      7'd6: pixel_data = out6;
      7'd7: pixel_data = out7;
      7'd8: pixel_data = out8;
      7'd9: pixel_data = out9;
      default: pixel_data = TRANSPARENT_COLOR;
    endcase
  end
end

endmodule