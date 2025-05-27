module game (
  input clk,
  input frame,
  input [3:0] KEY,         // Key inputs
  output [6:0] HEX0,       // 7-segment display outputs
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,
  output [9:0] LEDR,       // LED outputs
  input [9:0] SW           // Switch inputs
);
parameter S_IDLE = 2'b00;
parameter S_PLAYING = 2'b01;
parameter S_GAME_OVER = 2'b10;
reg [1:0] state;

// always @(*) begin
// end

endmodule