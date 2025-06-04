module health_status (
    input clk,
    input reset,
    input [3:0] player1_status,
    input [3:0] player2_status,
    output [3:0] player1_health,
    output [3:0] player2_health,
);
localparam S_HITSTUN = 4'd9;

wire player1_hitstun = (player1_status == S_HITSTUN);
wire player2_hitstun = (player2_status == S_HITSTUN);

counter #(
    .W(4)
) health_counter1 (
    .clk(player1_hitstun),
    .rst(reset),
    .control(2'b01),
    .count(player1_health)
);

counter #(
    .W(4)
) health_counter2 (
    .clk(player2_hitstun),
    .rst(reset),
    .control(2'b01),
    .count(player2_health)
);

assign player1_health = 4'd3 - player1_health;
assign player2_health = 4'd3 - player2_health;

endmodule