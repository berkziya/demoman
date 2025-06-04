module player #(
  parameter SIDE = 1'b0 // 0 for left, 1 for right
) (
  input            clk,
  input            rst,
  input            left, right, attack,
  
  input		 [1:0] hitFlag,
  
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

assign posy = 10'd170; // Fixed Y position for the player

assign basic_hithurtbox_x1 = posx + 35; // old version was posx + 37
assign basic_hithurtbox_x2 = posx + 120;
assign basic_hithurtbox_y1 = posy + 24;
assign basic_hithurtbox_y2 = posy + 57;

assign dir_hithurtbox_x1 = posx + 62;
assign dir_hithurtbox_x2 = posx + 95;
assign dir_hithurtbox_y1 = posy + 6;
assign dir_hithurtbox_y2 = posy + 139;

assign main_hurtbox_x1 = (~SIDE) ? (posx + 28) : (posx + 81);
assign main_hurtbox_x2 = (~SIDE) ? (posx + 81) : (posx + 28);
assign main_hurtbox_y1 = posy;
assign main_hurtbox_y2 = posy + 150;

//values for hitFlag:
localparam notHit = 2'b00;
localparam hitByBasic = 2'b01;
localparam hitByDirectional = 2'b10;


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

localparam countsize = 32;

localparam P_SPEED_FORW = 3;
localparam P_SPEED_BACK = 2;

reg [3:0] NS;

reg juststarted;

wire [countsize-1:0] counter;

reg [countsize-1:0] lastcountanchor;

reg [3:0] stunDurationValue;

counter #(
  .W(countsize)
) counter_inst (
  .clk(clk),
  .rst(1'b0),
  .control(2'b01),
  .count(counter)
);

always @(posedge clk or posedge rst) begin
  // $display("State: %d, Counter: %d, Counter Reset: %b", current_state, counter, rst_counter);
  if (rst) begin
    current_state <= S_IDLE;
	lastcountanchor <= 0;
  end else begin
	if (current_state != NS) lastcountanchor <=counter;
    current_state <= NS;
	end
end

always @(*) begin
	  case (current_state)
		S_IDLE: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if (attack) begin
			NS = S_B_ATTACK_START;
		  end else if (left && right) begin
			NS = S_MOVEBACKWARDS;
		  end else if (left && ~right) begin
			NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
		  end else if (~left && right) begin
			NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
		  end else begin
			NS = S_IDLE;
		  end end
		end
		S_MOVEFORWARD: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if (attack) begin
			NS = S_D_ATTACK_START;
		  end else if (left && right) begin
			NS = S_MOVEBACKWARDS;
		  end else if (left && ~right) begin
			NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
		  end else if (~left && right) begin
			NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
		  end else begin
			NS = S_IDLE;
		  end end
		end
		S_MOVEBACKWARDS: begin
		if (hitFlag == hitByBasic) begin
			NS=S_BLOCKSTUN;
			stunDurationValue = 13;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_BLOCKSTUN;
			stunDurationValue = 12;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if (attack) begin
			NS = S_D_ATTACK_START;
		  end else if (left && right) begin
			NS = S_MOVEBACKWARDS;
		  end else if (left && ~right) begin
			NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
		  end else if (~left && right) begin
			NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
		  end else begin
			NS = S_IDLE;
		  end end
		end
		S_B_ATTACK_START: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < 32'd5) begin
			NS = S_B_ATTACK_START;
		  end else begin
			NS = S_B_ATTACK_END;
		  end end
		end
		S_B_ATTACK_END: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < 32'd2) begin
			NS = S_B_ATTACK_END;
		  end else begin
			NS = S_B_ATTACK_PULL;
		  end end
		end
		S_B_ATTACK_PULL: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < 32'd16) begin
			NS = S_B_ATTACK_PULL;
		  end else begin
		  if (attack) begin
			NS = S_B_ATTACK_START;
		  end else if (left && right) begin
			NS = S_MOVEBACKWARDS;
		  end else if (left && ~right) begin
			NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
		  end else if (~left && right) begin
			NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
		  end else begin
			NS = S_IDLE;
		  end
		  end end
		end
		S_D_ATTACK_START: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < 32'd5) begin
			NS = S_D_ATTACK_START;
		  end else begin
			NS = S_D_ATTACK_END;
		  end end
		end
		S_D_ATTACK_END: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < 32'd2) begin
			NS = S_D_ATTACK_END;
		  end else begin
			NS = S_D_ATTACK_PULL;
		  end end
		end
		S_B_ATTACK_PULL: begin
		if (hitFlag == hitByBasic) begin
			NS=S_HITSTUN;
			stunDurationValue = 15;
		end
		else if (hitFlag == hitByDirectional) begin
			NS=S_HITSTUN;
			stunDurationValue = 14;
		end
		else begin
		  stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < 32'd16) begin
			NS = S_D_ATTACK_PULL;
		  end else begin
		  if (attack) begin
			NS = S_D_ATTACK_START;
		  end else if (left && right) begin
			NS = S_MOVEBACKWARDS;
		  end else if (left && ~right) begin
			NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
		  end else if (~left && right) begin
			NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
		  end else begin
			NS = S_IDLE;
		  end
		  end end
		end
		S_HITSTUN: begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < stunDurationValue) begin
			NS = S_HITSTUN;
		  end else begin
			  if (attack) begin
				NS = S_B_ATTACK_START;
			  end else if (left && right) begin
				NS = S_MOVEBACKWARDS;
			  end else if (left && ~right) begin
				NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
			  end else if (~left && right) begin
				NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
			  end else begin
				NS = S_IDLE;
			  end
		  end
		end
		S_BLOCKSTUN: begin
		stunDurationValue = stunDurationValue;
		  if ((counter-lastcountanchor) < stunDurationValue) begin
			NS = S_BLOCKSTUN;
		  end else begin
			  if (attack) begin
				NS = S_B_ATTACK_START;
			  end else if (left && right) begin
				NS = S_MOVEBACKWARDS;
			  end else if (left && ~right) begin
				NS = (SIDE == RIGHT) ? S_MOVEFORWARD : S_MOVEBACKWARDS;
			  end else if (~left && right) begin
				NS = (SIDE == RIGHT) ? S_MOVEBACKWARDS : S_MOVEFORWARD;
			  end else begin
				NS = S_IDLE;
			  end
		  end
		end
		default: begin
		  NS = S_IDLE;
		  stunDurationValue = stunDurationValue;
		end
	  endcase
end

always @(posedge clk) begin
  if ((~juststarted) || rst) begin
    posx <= (SIDE == LEFT) ? 10'd100 : 10'd390;
	juststarted <= 1'b1;
  end else begin
    case (NS)
      S_IDLE: begin
        posx <= posx;
      end
      S_MOVEFORWARD: begin
        if (SIDE == LEFT) posx <= posx + P_SPEED_FORW;
        else posx <= posx - P_SPEED_FORW;
      end
      S_MOVEBACKWARDS: begin
        if (SIDE == LEFT) posx <= posx - P_SPEED_BACK;
        else posx <= posx + P_SPEED_BACK;
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
