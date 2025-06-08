module player #(
  parameter SIDE = 0 // 0 for left, 1 for right
) (
  input clk,
  input rst,
  input left, right, attack,

  input [1:0] hitFlag,
  input [2:0] health,
  input [2:0] block,

  output reg [9:0] posx,
  output     [9:0] posy,
  output reg [3:0] current_state,

  output wire [9:0] basic_hithurtbox_x1,
  output wire [9:0] basic_hithurtbox_x2,
  output wire [9:0] basic_hithurtbox_y1,
  output wire [9:0] basic_hithurtbox_y2,

  output wire [9:0] dir_hithurtbox_x1,
  output wire [9:0] dir_hithurtbox_x2,
  output wire [9:0] dir_hithurtbox_y1,
  output wire [9:0] dir_hithurtbox_y2,

  output wire [9:0] main_hurtbox_x1,
  output wire [9:0] main_hurtbox_x2,
  output wire [9:0] main_hurtbox_y1,
  output wire [9:0] main_hurtbox_y2
);

localparam LEFT = 1'b0;
localparam RIGHT = 1'b1;

localparam S_IDLE = 4'd0;
localparam S_MOVEFORWARD = 4'd1;
localparam S_MOVEBACKWARDS = 4'd2;
localparam S_B_ATTACK_START = 4'd3;
localparam S_B_ATTACK_END = 4'd4;
localparam S_B_ATTACK_PULL = 4'd5;
localparam S_D_ATTACK_START = 4'd6;
localparam S_D_ATTACK_END = 4'd7;
localparam S_D_ATTACK_PULL = 4'd8;
localparam S_HITSTUN = 4'd9;
localparam S_BLOCKSTUN = 4'd10;

//values for hitFlag:
localparam notHit = 2'b00;
localparam hitByBasic = 2'b01;
localparam hitByDirectional = 2'b10;

localparam COUNT_SIZE = 32;

localparam P_SPEED_FORW = 3;
localparam P_SPEED_BACK = 2;

reg [3:0] next_state;

assign posy = 170; // Fixed Y position for the player

assign basic_hithurtbox_x1 = (SIDE == LEFT) ? (posx + 35) : (posx);
assign basic_hithurtbox_x2 = (SIDE == LEFT) ? (posx + 113) : (posx + 113 - 35);
assign basic_hithurtbox_y1 = posy + 24;
assign basic_hithurtbox_y2 = posy + 57;

assign dir_hithurtbox_x1 = (SIDE == LEFT) ? (posx + 62) : (posx + 113 - 95);
assign dir_hithurtbox_x2 = (SIDE == LEFT) ? (posx + 95) : (posx + 113 - 62);
assign dir_hithurtbox_y1 = posy + 6;
assign dir_hithurtbox_y2 = posy + 110;

assign main_hurtbox_x1 = (SIDE == LEFT) ? (posx + 28) : (posx + 113 - 81);
assign main_hurtbox_x2 = (SIDE == LEFT) ? (posx + 81) : (posx + 113 - 28);
assign main_hurtbox_y1 = posy;
assign main_hurtbox_y2 = posy + 150;

reg juststarted;

wire [COUNT_SIZE-1:0] counter;
reg  [COUNT_SIZE-1:0] lastcountanchor;

reg [3:0] stunDurationValue;
reg [3:0] nextStunDurationValue;

counter #(
  .W(COUNT_SIZE)
) counter_inst (
  .clk(clk),
  .rst(1'b0),
  .control(2'b01),
  .count(counter)
);

always @(posedge clk) begin
  if (rst) begin
    current_state <= S_IDLE;
    lastcountanchor <= 0;
  end else begin
    if (current_state != next_state) begin
	lastcountanchor <= counter;
	stunDurationValue <= nextStunDurationValue;
	end
    current_state <= next_state;
  end
end

always @(*) begin
  case (current_state)
    // ---- IDLE STATE ----
    S_IDLE: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (attack) next_state = S_B_ATTACK_START;
        else if (left && right) next_state = S_MOVEBACKWARDS;
        else if (left && ~right) next_state = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        else if (~left && right) next_state = (SIDE == LEFT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        else next_state = S_IDLE;
      end
    end

    // ---- MOVEMENT STATES ----
    S_MOVEFORWARD: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (attack) next_state = S_D_ATTACK_START;
        else if (left && right) next_state = S_MOVEBACKWARDS;
        else if (left && ~right) next_state = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        else if (~left && right) next_state = (SIDE == LEFT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        else next_state = S_IDLE;
      end
    end

    S_MOVEBACKWARDS: begin
      if (hitFlag == hitByBasic) begin
        if (block > 0) begin
          next_state = S_BLOCKSTUN;
          nextStunDurationValue = 13;
        end else begin
          next_state = S_HITSTUN;
          nextStunDurationValue = 15;
        end
      end
      else if (hitFlag == hitByDirectional) begin
        if (block > 0) begin
          next_state = S_BLOCKSTUN;
          nextStunDurationValue = 12;
        end else begin
          next_state = S_HITSTUN;
          nextStunDurationValue = 14;
        end
      end
      else begin
      nextStunDurationValue = stunDurationValue;
        if (attack) next_state = S_D_ATTACK_START;
        else if (left && right) next_state = S_MOVEBACKWARDS;
        else if (left && ~right) next_state = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        else if (~left && right) next_state = (SIDE == LEFT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        else next_state = S_IDLE;
      end
    end

    // ---- ATTACK STATES ----
    S_B_ATTACK_START: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (counter-lastcountanchor < 5) next_state = S_B_ATTACK_START;
        else next_state = S_B_ATTACK_END;
      end
    end

    S_B_ATTACK_END: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (counter-lastcountanchor < 2) next_state = S_B_ATTACK_END;
        else next_state = S_B_ATTACK_PULL;
      end
    end

    S_B_ATTACK_PULL: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (counter-lastcountanchor < 16) next_state = S_B_ATTACK_PULL;
        else begin
          if (attack) next_state = S_B_ATTACK_START;
          else if (left && right) next_state = S_MOVEBACKWARDS;
          else if (left && ~right) next_state = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
          else if (~left && right) next_state = (SIDE == LEFT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
          else next_state = S_IDLE;
        end
      end
    end

    // ---- DIRECTIONAL ATTACK STATES ----
    S_D_ATTACK_START: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (counter-lastcountanchor < 4) next_state = S_D_ATTACK_START;
        else next_state = S_D_ATTACK_END;
      end
    end

    S_D_ATTACK_END: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (counter-lastcountanchor < 3) next_state = S_D_ATTACK_END;
        else next_state = S_D_ATTACK_PULL;
      end
    end

    S_D_ATTACK_PULL: begin
      if (hitFlag == hitByBasic) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 15;
      end
      else if (hitFlag == hitByDirectional) begin
        next_state = S_HITSTUN;
        nextStunDurationValue = 14;
      end
      else begin
        nextStunDurationValue = stunDurationValue;
        if (counter-lastcountanchor < 15) next_state = S_D_ATTACK_PULL;
        else begin
          if (attack) next_state = S_B_ATTACK_START;
          else if (left && right) next_state = S_MOVEBACKWARDS;
          else if (left && ~right) next_state = (SIDE == LEFT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
          else if (~left && right) next_state = (SIDE == LEFT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
          else next_state = S_IDLE;
        end
      end
    end

    // ---- STUN STATES ----
    S_HITSTUN: begin
      nextStunDurationValue = stunDurationValue;
      if (counter-lastcountanchor < stunDurationValue) next_state = S_HITSTUN;
      else begin
        if (attack) next_state = S_B_ATTACK_START;
        else if (left && right) next_state = S_MOVEBACKWARDS;
        else if (left && ~right) next_state = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        else if (~left && right) next_state = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        else next_state = S_IDLE;
      end
    end

    S_BLOCKSTUN: begin
      nextStunDurationValue = stunDurationValue;
      if (counter-lastcountanchor < stunDurationValue) next_state = S_BLOCKSTUN;
      else begin
        if (attack) next_state = S_B_ATTACK_START;
        else if (left && right) next_state = S_MOVEBACKWARDS;
        else if (left && ~right) next_state = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
        else if (~left && right) next_state = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
        else next_state = S_IDLE;
      end
    end

    default: begin
      nextStunDurationValue = stunDurationValue;
      next_state = S_IDLE;
    end
  endcase
end


/*
always @(posedge clk) begin
  if ((~juststarted) || rst) begin
    posx <= (SIDE == LEFT) ? 10'd100 : 10'd427;
    juststarted <= 1'b1;
  end else begin
    case (current_state)
      S_MOVEFORWARD: begin
        if (SIDE == LEFT && posx < 517) posx <= posx + P_SPEED_FORW;
        else if (posx > 10) posx <= posx - P_SPEED_FORW;
      end
      S_MOVEBACKWARDS: begin
        if (SIDE == LEFT && posx > 10) posx <= posx - P_SPEED_BACK;
        else if (posx < 517) posx <= posx + P_SPEED_BACK;
      end
      default: posx <= posx;
    endcase
  end
end
*/

always @(posedge clk) begin
  if ((posx == 0) || rst) begin
    posx <= (SIDE == LEFT) ? 10'd100 : 10'd427;
  end else begin
    case (current_state)
      S_MOVEFORWARD: begin
        if (SIDE == LEFT && posx < 517) posx <= posx + P_SPEED_FORW;
        else if (posx > 10) posx <= posx - P_SPEED_FORW;
      end
      S_MOVEBACKWARDS: begin
        if (SIDE == LEFT && posx > 10) posx <= posx - P_SPEED_BACK;
        else if (posx < 517) posx <= posx + P_SPEED_BACK;
      end
      default: posx <= posx;
    endcase
  end
end

endmodule
