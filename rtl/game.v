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
  output  [9:0] player1_posx,
  output  [9:0] player1_posy,
  output  [9:0] player2_posx,
  output  [9:0] player2_posy
);
parameter S_IDLE = 3'd0;
parameter S_INTRO = 3'd1;
parameter S_PvP = 3'd2;
parameter S_PvAI = 3'd3;
parameter S_GAME_OVER = 3'd4;

reg [2:0] CS, NS;

wire effective_clk;
assign effective_clk = SW[1] ? clk : KEY[3];

reg [31:0] random_number;
random_num random_gen (
  .clk(effective_clk),
  .rst(reset),
  .rand_o(random_number)
);

player #(
  .SIDE(1'b0)
) player1 (
  .clk(effective_clk),
  .rst(~KEY[0]),
  .left(GPIO[4]),
  .right(GPIO[6]),
  .attack(GPIO[8]),
  .posx(player1_posx),
  .posy(player1_posy),
  .current_state()
);

wire player2_left, player2_right, player2_attack;

assign player2_left = (CS == S_PvP) ? GPIO[10] : random_number[0];
assign player2_right = (CS == S_PvP) ? GPIO[12] : random_number[1];
assign player2_attack = (CS == S_PvP) ? GPIO[14] : random_number[2];

player #(
  .SIDE(1'b1)
) player2 (
  .clk(effective_clk),
  .rst(~KEY[0]),
  .left(player2_left),
  .right(player2_right),
  .attack(player2_attack),
  .posx(player2_posx),
  .posy(player2_posy),
  .current_state()
);

always @(posedge effective_clk or posedge reset) begin
  if (reset) CS <= S_IDLE;
  else CS <= NS;
end

always @(*) begin // debugging
  if (SW[9]) NS = S_INTRO;
  else if (SW[8]) NS = S_PvP;
  else if (SW[7]) NS = S_GAME_OVER;
  else if (SW[6]) NS = S_PvAI;
  else if (SW[5]) NS = S_IDLE;
  else NS = S_IDLE;
end

endmodule
