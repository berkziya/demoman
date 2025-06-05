module health_status (
  input clk,
  input rst,

  input [3:0] player1_state,
  input [3:0] player2_state,

  output [2:0] player1_health,
  output [2:0] player2_health,

  output [2:0] player1_block,
  output [2:0] player2_block
);
localparam S_HITSTUN = 4'd9;
localparam S_BLOCKSTUN = 4'd10;

wire player1_hitstun = (player1_state == S_HITSTUN);
wire player2_hitstun = (player2_state == S_HITSTUN);
wire player1_blockstun = (player1_state == S_BLOCKSTUN);
wire player2_blockstun = (player2_state == S_BLOCKSTUN);

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

counter #(
  .W(3)
) block_counter1 (
  .clk(player1_blockstun),
  .rst(rst),
  .control(2'b01),
  .count(player1_block)
);

counter #(
  .W(3)
) block_counter2 (
  .clk(player2_blockstun),
  .rst(rst),
  .control(2'b01),
  .count(player2_block)
);

assign player1_health = 3'd3 - player1_health;
assign player2_health = 3'd3 - player2_health;
assign player1_block = 3'd3 - player1_block;
assign player2_block = 3'd3 - player2_block;

endmodule