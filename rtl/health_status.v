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

always @(posedge clk or posedge rst) begin
  if (rst) begin
    player1_health <= 3'b011;
    player2_health <= 3'b011;
    player1_block <= 3'b011;
    player2_block <= 3'b011;
  end else begin
    if (player1_state == S_HITSTUN) begin
      player1_health <= player1_health - 1;
    end else if (player1_state == S_BLOCKSTUN) begin
      player1_block <= player1_block - 1;
    end

    // Player 2 health and block logic
    if (player2_state == S_HITSTUN) begin
      player2_health <= player2_health - 1;
    end else if (player2_state == S_BLOCKSTUN) begin
      player2_block <= player2_block - 1;
    end
  end
end

endmodule