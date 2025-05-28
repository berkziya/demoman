module player #(
  parameter SIDE = 1'b0 // 0 for left, 1 for right
) (
  input            clk,
  input            rst,
  input            left, right, attack,
  output reg [9:0] posx,
  output reg [9:0] posy,
  output reg [3:0] current_state
);
parameter LEFT = 1'b0;
parameter RIGHT = 1'b1;

parameter S_IDLE = 4'd0;
parameter S_MOVEFORWARD = 4'd1;
parameter S_MOVEBACKWARDS = 4'd2;
parameter S_B_ATTACK_START = 4'd3;
parameter S_B_ATTACK_END = 4'd4;
parameter S_B_ATTACK_PULL = 4'd5;

parameter P_SPEED = 10;

reg [3:0] NS;

wire [9:0] counter;
reg rst_counter;

counter #(
  .W(10)
) counter_inst (
  .clk(clk),
  .rst(rst_counter),
  .control(2'b01),
  .count(counter)
);

always @(posedge clk or posedge rst) begin
  if (rst) current_state <= S_IDLE;
  else current_state <= NS;
end
/* verilator lint_off LATCH */
always @(*) begin
  case (current_state)
    S_IDLE, S_MOVEFORWARD, S_MOVEBACKWARDS: begin
      if (attack) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b1;
      end else if (left && right) begin
        NS = S_MOVEBACKWARDS;
        rst_counter = 1'b0;
      end else if (left && ~right) begin
        NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        rst_counter = 1'b0;
      end else if (~left && right) begin
        NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        rst_counter = 1'b0;
      end else begin
        NS = S_IDLE;
        rst_counter = 1'b0;
      end
    end
    S_B_ATTACK_START: begin
      if (counter < 4) NS = S_B_ATTACK_START;
      else begin
        NS = S_B_ATTACK_END;
        rst_counter = 1'b1;
      end
    end
    S_B_ATTACK_END: begin
      if (counter < 1) NS = S_B_ATTACK_END;
      else begin
        rst_counter = 1'b1;
        NS = S_B_ATTACK_PULL;
      end
    end
    S_B_ATTACK_PULL: begin
      if (counter < 15) NS = S_B_ATTACK_PULL;
      else begin
        rst_counter = 1'b1;
        NS = S_IDLE;
      end
    end
    default: begin
      NS = S_IDLE;
      rst_counter = 1'b0;
    end
  endcase
end
/* verilator lint_off LATCH */
always @(posedge clk or posedge rst) begin
  if (rst) begin
    posx <= (SIDE == LEFT) ? 10'd210 : 10'd420;
    posy <= 10'd140;
  end else begin
    case (current_state)
      S_IDLE: begin
        posx = posx;
      end
      S_MOVEFORWARD: begin
        if (SIDE == LEFT) posx <= posx + P_SPEED;
        else posx <= posx - P_SPEED;
      end
      S_MOVEBACKWARDS: begin
        if (SIDE == LEFT) posx <= posx - P_SPEED;
        else posx <= posx + P_SPEED;
      end
      S_B_ATTACK_START: begin
        posx <= posx;
      end
      S_B_ATTACK_END: begin
        posx <= posx;
      end
      S_B_ATTACK_PULL: begin
        posx <= posx;
      end
      default: begin
        posx <= posx;
        posy <= posy;
      end
    endcase
  end
  if (posx < 50) posx <= 240;
  else if (posx > 590) posx <= 240;
end

endmodule
