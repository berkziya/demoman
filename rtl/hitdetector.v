module HitDetect (
  input [3:0] p1_state,

  input [9:0] p1_basic_hithurtbox_x1,
  input [9:0] p1_basic_hithurtbox_x2,
  input [9:0] p1_basic_hithurtbox_y1,
  input [9:0] p1_basic_hithurtbox_y2,
  
  input [9:0] p1_dir_hithurtbox_x1,
  input [9:0] p1_dir_hithurtbox_x2,
  input [9:0] p1_dir_hithurtbox_y1,
  input [9:0] p1_dir_hithurtbox_y2,

  input [9:0] p1_main_hurtbox_x1,
  input [9:0] p1_main_hurtbox_x2,
  input [9:0] p1_main_hurtbox_y1,
  input [9:0] p1_main_hurtbox_y2,


  input [3:0] p2_state,

  input [9:0] p2_basic_hithurtbox_x1,
  input [9:0] p2_basic_hithurtbox_x2,
  input [9:0] p2_basic_hithurtbox_y1,
  input [9:0] p2_basic_hithurtbox_y2,
  
  input [9:0] p2_dir_hithurtbox_x1,
  input [9:0] p2_dir_hithurtbox_x2,
  input [9:0] p2_dir_hithurtbox_y1,
  input [9:0] p2_dir_hithurtbox_y2,

  input [9:0] p2_main_hurtbox_x1,
  input [9:0] p2_main_hurtbox_x2,
  input [9:0] p2_main_hurtbox_y1,
  input [9:0] p2_main_hurtbox_y2,

  output reg [1:0] P1_hasBeenHitFlag,
  output reg [1:0] P2_hasBeenHitFlag
);

	localparam notHit = 2'b00;
	localparam hitByBasic = 2'b01;
	localparam hitByDirectional = 2'b10;

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

	wire colldet_p1ba_p2main_result;

	CollisionDetect colldet_p1ba_p2main(
		.a_x1(p1_basic_hithurtbox_x1),
		.a_x2(p1_basic_hithurtbox_x2),
		.a_y1(p1_basic_hithurtbox_y1),
		.a_y2(p1_basic_hithurtbox_y2),
		.b_x1(p2_main_hurtbox_x1),
		.b_x2(p2_main_hurtbox_x2),
		.b_y1(p2_main_hurtbox_y1),
		.b_y2(p2_main_hurtbox_y2),
		.collision_result(colldet_p1ba_p2main_result)
	);

	wire colldet_p2ba_p1main_result;

	CollisionDetect colldet_p2ba_p1main(
		.a_x1(p2_basic_hithurtbox_x1),
		.a_x2(p2_basic_hithurtbox_x2),
		.a_y1(p2_basic_hithurtbox_y1),
		.a_y2(p2_basic_hithurtbox_y2),
		.b_x1(p1_main_hurtbox_x1),
		.b_x2(p1_main_hurtbox_x2),
		.b_y1(p1_main_hurtbox_y1),
		.b_y2(p1_main_hurtbox_y2),
		.collision_result(colldet_p2ba_p1main_result)
	);

	wire colldet_p1ba_p2ba_result;

	CollisionDetect colldet_p1ba_p2ba(
		.a_x1(p1_basic_hithurtbox_x1),
		.a_x2(p1_basic_hithurtbox_x2),
		.a_y1(p1_basic_hithurtbox_y1),
		.a_y2(p1_basic_hithurtbox_y2),
		.b_x1(p2_basic_hithurtbox_x1),
		.b_x2(p2_basic_hithurtbox_x2),
		.b_y1(p2_basic_hithurtbox_y1),
		.b_y2(p2_basic_hithurtbox_y2),
		.collision_result(colldet_p1ba_p2ba_result)
	);
	
	wire colldet_p1da_p2main_result;

	CollisionDetect colldet_p1da_p2main(
		.a_x1(p1_dir_hithurtbox_x1),
		.a_x2(p1_dir_hithurtbox_x2),
		.a_y1(p1_dir_hithurtbox_y1),
		.a_y2(p1_dir_hithurtbox_y2),
		.b_x1(p2_main_hurtbox_x1),
		.b_x2(p2_main_hurtbox_x2),
		.b_y1(p2_main_hurtbox_y1),
		.b_y2(p2_main_hurtbox_y2),
		.collision_result(colldet_p1da_p2main_result)
	);

	wire colldet_p2da_p1main_result;

	CollisionDetect colldet_p2da_p1main(
		.a_x1(p2_dir_hithurtbox_x1),
		.a_x2(p2_dir_hithurtbox_x2),
		.a_y1(p2_dir_hithurtbox_y1),
		.a_y2(p2_dir_hithurtbox_y2),
		.b_x1(p1_main_hurtbox_x1),
		.b_x2(p1_main_hurtbox_x2),
		.b_y1(p1_main_hurtbox_y1),
		.b_y2(p1_main_hurtbox_y2),
		.collision_result(colldet_p2da_p1main_result)
	);

	wire colldet_p1da_p2da_result;

	CollisionDetect colldet_p1da_p2da(
		.a_x1(p1_dir_hithurtbox_x1),
		.a_x2(p1_dir_hithurtbox_x2),
		.a_y1(p1_dir_hithurtbox_y1),
		.a_y2(p1_dir_hithurtbox_y2),
		.b_x1(p2_dir_hithurtbox_x1),
		.b_x2(p2_dir_hithurtbox_x2),
		.b_y1(p2_dir_hithurtbox_y1),
		.b_y2(p2_dir_hithurtbox_y2),
		.collision_result(colldet_p1da_p2da_result)
	);
	
	wire colldet_p1da_p2ba_result;

	CollisionDetect colldet_p1da_p2ba(
		.a_x1(p1_dir_hithurtbox_x1),
		.a_x2(p1_dir_hithurtbox_x2),
		.a_y1(p1_dir_hithurtbox_y1),
		.a_y2(p1_dir_hithurtbox_y2),
		.b_x1(p2_basic_hithurtbox_x1),
		.b_x2(p2_basic_hithurtbox_x2),
		.b_y1(p2_basic_hithurtbox_y1),
		.b_y2(p2_basic_hithurtbox_y2),
		.collision_result(colldet_p1da_p2ba_result)
	);

	wire colldet_p2da_p1ba_result;

	CollisionDetect colldet_p2da_p1ba(
		.a_x1(p2_dir_hithurtbox_x1),
		.a_x2(p2_dir_hithurtbox_x2),
		.a_y1(p2_dir_hithurtbox_y1),
		.a_y2(p2_dir_hithurtbox_y2),
		.b_x1(p1_basic_hithurtbox_x1),
		.b_x2(p1_basic_hithurtbox_x2),
		.b_y1(p1_basic_hithurtbox_y1),
		.b_y2(p1_basic_hithurtbox_y2),
		.collision_result(colldet_p2da_p1ba_result)
	);


	always @(*) begin

		case (p1_state)

			S_B_ATTACK_END:begin

				case (p2_state)

					S_B_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p1ba_p2ba_result ? hitByBasic : notHit;
					P2_hasBeenHitFlag = colldet_p1ba_p2ba_result ? hitByBasic : notHit;
					end
					S_B_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					P2_hasBeenHitFlag = colldet_p1ba_p2ba_result ? hitByBasic : notHit;
					end
					S_D_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p2da_p1ba_result ? hitByDirectional : notHit;
					P2_hasBeenHitFlag = colldet_p2da_p1ba_result ? hitByBasic : notHit;
					end
					S_D_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					P2_hasBeenHitFlag = colldet_p2da_p1ba_result ? hitByBasic : notHit;
					end
					default:begin
					P1_hasBeenHitFlag = notHit;
					P2_hasBeenHitFlag = colldet_p1ba_p2main_result ? hitByBasic : notHit;
					end
				endcase

			end

			S_B_ATTACK_PULL:begin
				P2_hasBeenHitFlag = notHit;
				case (p2_state)
					S_B_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p1ba_p2ba_result ? hitByBasic : notHit;
					end
					S_B_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					end
					S_D_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p2da_p1ba_result ? hitByDirectional : notHit;
					end
					S_D_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					end
					default:begin
					P1_hasBeenHitFlag = notHit;
					end
				endcase

			end
			
			S_D_ATTACK_END:begin

				case (p2_state)

					S_B_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p1da_p2ba_result ? hitByBasic : notHit;
					P2_hasBeenHitFlag = colldet_p1da_p2ba_result ? hitByDirectional : notHit;
					end
					S_B_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					P2_hasBeenHitFlag = colldet_p1da_p2ba_result ? hitByDirectional : notHit;
					end
					S_D_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p1da_p2da_result ? hitByDirectional : notHit;
					P2_hasBeenHitFlag = colldet_p1da_p2da_result ? hitByDirectional : notHit;
					end
					S_D_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					P2_hasBeenHitFlag = colldet_p1da_p2da_result ? hitByDirectional: notHit;
					end
					default:begin
					P1_hasBeenHitFlag = notHit;
					P2_hasBeenHitFlag = colldet_p1da_p2main_result ? hitByDirectional : notHit;
					end
				endcase

			end

			S_D_ATTACK_PULL:begin
				P2_hasBeenHitFlag = notHit;
				case (p2_state)
					S_B_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p1da_p2ba_result ? hitByBasic : notHit;
					end
					S_B_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					end
					S_D_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p1da_p2da_result ? hitByDirectional : notHit;
					end
					S_D_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					end
					default:begin
					P1_hasBeenHitFlag = notHit;
					end
				endcase

			end

			default:begin
					P2_hasBeenHitFlag = notHit;
				case (p2_state)
					S_B_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p2ba_p1main_result ? hitByBasic : notHit;
					end
					S_B_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					end
					S_D_ATTACK_END:begin
					P1_hasBeenHitFlag = colldet_p2da_p1main_result ? hitByDirectional : notHit;
					end
					S_D_ATTACK_PULL: begin
					P1_hasBeenHitFlag = notHit;
					end
					default:begin
					P1_hasBeenHitFlag = notHit;
					end
				endcase
			end
		endcase
	end

endmodule
