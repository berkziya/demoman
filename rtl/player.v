module player #(
  parameter SIDE = 1'b0 // 0 for left, 1 for right
) (
  input            clk,
  input            rst,
  input            left, right, attack,
  output reg [9:0] posx,
  output reg [9:0] posy,
  output [3:0] currentstate
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

wire [10:0] counter;

reg        rst_counter;

counter #(
  .W(5)
) counter_inst (
  .clk(clk),
  .rst(rst_counter),
  .control(2'b01),
  .count(counter)
);

parameter P_SPEED = 1;

always @(posedge clk or posedge rst) begin
  if (rst) CS <= S_IDLE;
  else CS <= NS;
end

always @(*) begin
  case (CS)
    S_IDLE, S_MOVEFORWARD, S_MOVEBACKWARDS: begin
      if (left && ~right) NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
      else if (~left && right) NS = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
      else if (left && right) NS = S_MOVEBACKWARDS;
      else if (attack) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b1;
      end else NS = S_IDLE;
    end
    S_B_ATTACK_START: begin
	  rst_counter = 1'b0;
      if (counter < 4) NS = S_B_ATTACK_START;
      else 
		begin
			rst_counter = 1'b1;
			NS = S_B_ATTACK_END;
		end
    end
    S_B_ATTACK_END: begin
      if (counter < 1) NS = S_B_ATTACK_END;
      else 
		begin
			rst_counter = 1'b1;
			NS = S_B_ATTACK_PULL;
		end
    end
    S_B_ATTACK_PULL: begin
	  rst_counter = 1'b0;
      if (counter < 15) NS = S_B_ATTACK_PULL;
      else 
		begin
			rst_counter = 1'b1;
			NS = S_IDLE;
		end
    end
    default: NS = S_IDLE;
  endcase
end

always @(*) begin
  if (rst) begin
    posx <= SIDE == LEFT ? 10'd210 : 10'd420;
    posy <= 10'd240;
  end else begin
    case (CS)
      S_IDLE: begin
        posx <= posx;
      end
      S_MOVEFORWARD: begin
        if (SIDE == LEFT) posx <= posx - P_SPEED;
        else posx <= posx + P_SPEED;

      end
      S_MOVEBACKWARDS: begin
        if (SIDE == LEFT) posx <= posx + P_SPEED;
        else posx <= posx - P_SPEED;

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
  if (posx < 50) posx <= 0;
  else if (posx > 590) posx <= 590;
end

endmodule
