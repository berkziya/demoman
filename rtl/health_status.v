module health_status (
  input clk,
  input rst,

  input [3:0] player1_state,
  input [3:0] player2_state,

  output reg [2:0] player1_health,
  output reg [2:0] player2_health,

  output reg [2:0] player1_block,
  output reg [2:0] player2_block
);
localparam S_HITSTUN = 4'd9;
localparam S_BLOCKSTUN = 4'd10;
reg [3:0] p1_prev_state, p2_prev_state;

wire [2:0] player1_health_count, player2_health_count;
wire [2:0] player1_block_count, player2_block_count;

always @(posedge clk) begin
  p1_prev_state <= player1_state;
  p2_prev_state <= player2_state;
end

wire player1_hitstun = ((p1_prev_state != S_HITSTUN) && (player1_state == S_HITSTUN)) ? 2'b01 : 2'b00;
wire player2_hitstun = ((p2_prev_state != S_HITSTUN) && (player2_state == S_HITSTUN)) ? 2'b01 : 2'b00;
wire player1_blockstun = ((p1_prev_state != S_BLOCKSTUN) && (player1_state == S_BLOCKSTUN)) ? 2'b01 : 2'b00;
wire player2_blockstun = ((p2_prev_state != S_BLOCKSTUN) && (player2_state == S_BLOCKSTUN)) ? 2'b01 : 2'b00;

counter #(
  .W(3)
) health_counter1 (
  .clk(clk),
  .rst(rst),
  .control(player1_hitstun),
  .count(player1_health_count)
);

counter #(
  .W(3)
) health_counter2 (
  .clk(clk),
  .rst(rst),
  .control(player2_hitstun),
  .count(player2_health_count)
);

counter #(
  .W(3)
) block_counter1 (
  .clk(clk),
  .rst(rst),
  .control(player1_blockstun),
  .count(player1_block_count)
);

counter #(
  .W(3)
) block_counter2 (
  .clk(clk),
  .rst(rst),
  .control(player2_blockstun),
  .count(player2_block_count)
);

always @(*) begin
  player1_health = 3'd3 - player1_health_count;
  player2_health = 3'd3 - player2_health_count;
  player1_block = 3'd3 - player1_block_count;
  player2_block = 3'd3 - player2_block_count;
end

endmodule