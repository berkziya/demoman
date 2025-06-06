module game (
  input clk, // 60 Hz clock
  input reset,

  input [3:0] KEY,
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,
  output [9:0] LEDR,
  input [9:0] SW,
  inout [35:0] GPIO,

  input [2:0] player1_state,
  input [2:0] player2_state,
  input [2:0] player1_health,
  input [2:0] player2_health,

  output reg [2:0] game_state
);
localparam S_IDLE = 3'd0;
localparam S_COUNTDOWN = 3'd1;
localparam S_FIGHT = 3'd2;
localparam S_P1_WIN = 3'd3;
localparam S_P2_WIN = 3'd4;
localparam S_EQ = 3'd5;
reg [2:0] next_state;

localparam S_HEX_1P = 3'd0;
localparam S_HEX_2P = 3'd1;
localparam S_HEX_FIGHt = 3'd2;
localparam S_HEX_P1_WIN = 3'd3;
localparam S_HEX_P2_WIN = 3'd4;
localparam S_HEX_Eq = 3'd5;
reg [2:0] hex_state;


wire [6:0] game_duration; // Game timer in seconds
reg [1:0] counter_control; // 00: hold, 01: increment, 10: decrement, 11: reset

hextext_handler hextext_inst (
  .hex_state(hex_state),
  .game_duration(game_duration),
  .HEX0(HEX0),
  .HEX1(HEX1),
  .HEX2(HEX2),
  .HEX3(HEX3),
  .HEX4(HEX4),
  .HEX5(HEX5)
);


wire clk_1Hz;
clock_divider #(.DIV(60)) clk_div_inst ( // 60 Hz clock divider
  .clk(clk),
  .clk_o(clk_1Hz)
);

counter #(.W(7)) counter_inst ( // Game timer
  .clk(clk_1Hz),
  .rst(reset),
  .control(counter_control),
  .count(game_duration)
);


always @(posedge clk or posedge reset) begin
  if (reset) game_state <= S_IDLE;
  else game_state <= next_state;
end

always @(*) begin
end

always @(*) begin
end

endmodule
