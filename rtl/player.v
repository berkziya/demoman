module character #(
  parameter SIDE
) (
  input clk,
  input rst,
  input side,
  input left, right,
  input attack,
  output reg [16:0] posx,
  output reg [16:0] posy
);
parameter LEFT = 1'b0;
parameter RIGHT = 1'b1;

parameter S_IDLE = 3'd0;
parameter S_MOVEFORWARD = 3'd1;
parameter S_MOVEBACKWARDS = 3'd2;
parameter S_B_ATTACK_START = 3'd3;
parameter S_B_ATTACK_END = 3'd4;
parameter S_B_ATTACK_PULL = 3'd5;

reg [2:0] CS, NS;

wire counter;
reg rst_counter;

counter counter_inst (
  .clk(clk),
  .rst(rst_counter),
  .control(2'b01),
  .count(counter)
);

parameter SPEED = 1;

always @(posedge clk or posedge rst) begin
  if (rst) CS <= S_IDLE;
  else CS <= NS;
  rst <= 0;
end

always @(*) begin
  SIDE = 0;
  NS = S_IDLE;
  case (CS)
    S_IDLE: begin
      if (left && ~right) begin
        NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      end else if (~left && right) begin
        NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      end else if (attack) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b1;
      end
      else NS = S_IDLE;
    end
    S_MOVEFORWARD: begin
      if (left && ~right) begin
        NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      end else if (~left && right) begin
        NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      end else if (attack) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b1;
      end
      else NS = S_IDLE;
    end
    S_MOVEBACKWARDS: begin
      if (left && ~right) NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      else if (~left && right) NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      else if (attack) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b1;
      end
      else NS = S_IDLE;
    end
    S_B_ATTACK_START: begin
      if (left && ~right) NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      else if (~left && right) NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      else if (attack) NS = S_B_ATTACK_START; // Continue attack
      else NS = S_B_ATTACK_END; // End attack
    end
    S_B_ATTACK_END: begin
      if (left && ~right) NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      else if (~left && right) NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      else if (attack) NS = S_B_ATTACK_START; // Restart attack
      else NS = S_IDLE; // Return to idle
    end
    S_B_ATTACK_PULL: begin
      if (left && ~right) NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      else if (~left && right) NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      else if (attack) NS = S_B_ATTACK_START; // Restart attack
      else NS = S_IDLE; // Return to idle
    end
    default: NS = S_IDLE;
  endcase
end

// always @(posedge clk or posedge rst) begin

// end

endmodule