module health_status (
  input clk,
  input rst,

  input [3:0] player1_state,
  input [3:0] player2_state,

  output [2:0] player1_health,
  output [2:0] player2_health,
);
localparam S_HITSTUN = 4'd9;

wire player1_hitstun = (player1_state == S_HITSTUN);
wire player2_hitstun = (player2_state == S_HITSTUN);

counter #(
  .W(3)
) health_counter1 (
  .clk(player1_hitstun),
  .rst(rst),
  .control(2'b01),
  .count(player1_health)
);

counter #(
  .W(3)
) health_counter2 (
  .clk(player2_hitstun),
  .rst(rst),
  .control(2'b01),
  .count(player2_health)
);

assign player1_health = 3'd3 - player1_health;
assign player2_health = 3'd3 - player2_health;

endmodule