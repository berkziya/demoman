module player #(
  parameter SIDE = 1'b0 // 0 for left, 1 for right
) (
  input            clk,
  input            rst,
  input            left, right, attack,
  output reg [9:0] posx,
  output reg [9:0] posy,
  output reg [3:0] current_state,

  output wire [9:0] basic_hithurtbox_x1,
  output wire [9:0] basic_hithurtbox_x2,
  output wire [9:0] basic_hithurtbox_y1,
  output wire [9:0] basic_hithurtbox_y2,

  output wire [9:0] main_hurtbox_x1,
  output wire [9:0] main_hurtbox_x2,
  output wire [9:0] main_hurtbox_y1,
  output wire [9:0] main_hurtbox_y2
);
assign posy = 10'd170; // Fixed Y position for the player

assign basic_hithurtbox_x1 = posx + 37;
assign basic_hithurtbox_x2 = posx + 113;
assign basic_hithurtbox_y1 = posy + 24;
assign basic_hithurtbox_y2 = posy + 57;

assign main_hurtbox_x1 = (~SIDE) ? (posx + 37) : (posx + 86);
assign main_hurtbox_x2 = (~SIDE) ? (posx + 86) : (posx + 37);
assign main_hurtbox_y1 = posy;
assign main_hurtbox_y2 = posy + 150;

parameter LEFT = 1'b0;
parameter RIGHT = 1'b1;

parameter S_IDLE = 4'd0;
parameter S_MOVEFORWARD = 4'd1;
parameter S_MOVEBACKWARDS = 4'd2;
parameter S_B_ATTACK_START = 4'd3;
parameter S_B_ATTACK_END = 4'd4;
parameter S_B_ATTACK_PULL = 4'd5;

parameter P_SPEED = 15;

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
  $display("State: %d, Counter: %d, Counter Reset: %b", current_state, counter, rst_counter);
  if (rst) current_state <= S_IDLE;
  else current_state <= NS;
  rst_counter = 1'b0;
end

always @(*) begin
  case (current_state)
    S_IDLE, S_MOVEFORWARD, S_MOVEBACKWARDS: begin
      if (attack) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b1;
      end else if (left && right) begin
        NS = S_MOVEBACKWARDS;
        rst_counter = 1'b1;
      end else if (left && ~right) begin
        NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        rst_counter = 1'b1;
      end else if (~left && right) begin
        NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        rst_counter = 1'b1;
      end else begin
        NS = S_IDLE;
        rst_counter = 1'b0;
      end
    end
    S_B_ATTACK_START: begin
      if (counter < 4) begin
        NS = S_B_ATTACK_START;
        rst_counter = 1'b0;
      end else begin
        NS = S_B_ATTACK_END;
        rst_counter = 1'b1;
      end
    end
    S_B_ATTACK_END: begin
      if (counter < 1) begin
        NS = S_B_ATTACK_END;
        rst_counter = 1'b0;
      end else begin
        NS = S_B_ATTACK_PULL;
        rst_counter = 1'b1;
      end
    end
    S_B_ATTACK_PULL: begin
      if (counter < 15) begin
        NS = S_B_ATTACK_PULL;
        rst_counter = 1'b0;
      end else begin
        NS = S_IDLE;
        rst_counter = 1'b1;
      end
    end
    default: begin
      NS = S_IDLE;
      rst_counter = 1'b0;
    end
  endcase
end

always @(posedge clk) begin
  if (rst) begin
    posx <= (SIDE == LEFT) ? 10'd210 : 10'd420;
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
      end
    endcase
  end
  if (posx < 50) posx <= 50;
  else if (posx > 490) posx <= 490;
end

endmodule
