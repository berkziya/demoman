module game (
  input         clk,
  input         reset,
  input   [3:0] KEY,
  output  [6:0] HEX0,
  output  [6:0] HEX1,
  output  [6:0] HEX2,
  output  [6:0] HEX3,
  output  [6:0] HEX4,
  output  [6:0] HEX5,
  output  [9:0] LEDR,
  input   [9:0] SW,
  inout  [35:0] GPIO,

  output  [2:0] game_state,
);
localparam S_IDLE = 3'd0;
localparam S_INTRO = 3'd1;
localparam S_PvP = 3'd2;
localparam S_PvAI = 3'd3;
localparam S_GAME_OVER = 3'd4;

reg [2:0] next_state;

always @(posedge effective_clk or posedge reset) begin
  if (reset) game_state <= S_IDLE;
  else game_state <= next_state;
end

always @(*) begin // debugging
  if (SW[9]) next_state = S_INTRO;
  else if (SW[8]) next_state = S_PvP;
  else if (SW[7]) next_state = S_GAME_OVER;
  else if (SW[6]) next_state = S_PvAI;
  else if (SW[5]) next_state = S_IDLE;
  else next_state = S_IDLE;
end

endmodule
