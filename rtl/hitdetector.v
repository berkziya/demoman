module HitDetect (
  input [3:0] p1_state,

  input [9:0] p1_basic_hithurtbox_x1,
  input [9:0] p1_basic_hithurtbox_x2,
  input [9:0] p1_basic_hithurtbox_y1,
  input [9:0] p1_basic_hithurtbox_y2,

  input [9:0] p1_main_hurtbox_x1,
  input [9:0] p1_main_hurtbox_x2,
  input [9:0] p1_main_hurtbox_y1,
  input [9:0] p1_main_hurtbox_y2,


  input [3:0] p2_state,

  input [9:0] p2_basic_hithurtbox_x1,
  input [9:0] p2_basic_hithurtbox_x2,
  input [9:0] p2_basic_hithurtbox_y1,
  input [9:0] p2_basic_hithurtbox_y2,

  input [9:0] p2_main_hurtbox_x1,
  input [9:0] p2_main_hurtbox_x2,
  input [9:0] p2_main_hurtbox_y1,
  input [9:0] p2_main_hurtbox_y2,

  output reg [1:0] hitresult
);

	localparam P1_hitbox_touching_P2_hurtbox = 2'b10,
						P2_hitbox_touching_P1_hurtbox = 2'b01,
						no_hit_at_the_moment = 2'b00,
						both_being_hit = 2'b11;

	localparam S_IDLE = 4'd0;
	localparam S_MOVEFORWARD = 4'd1;
	localparam S_MOVEBACKWARDS = 4'd2;
	localparam S_B_ATTACK_START = 4'd3;
	localparam S_B_ATTACK_END = 4'd4;
	localparam S_B_ATTACK_PULL = 4'd5;

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
		.collision_result(colldet_p1ba_p2main_result)
	);


	always @(*) begin

		case p1_state

			S_B_ATTACK_END:begin

				case p2_state

					S_B_ATTACK_END: hitresult = colldet_p1ba_p2ba_result ? both_being_hit : no_hit_at_the_moment;
					S_B_ATTACK_PULL: hitresult = colldet_p1ba_p2ba_result ? P1_hitbox_touching_P2_hurtbox : no_hit_at_the_moment;
					default: hitresult = colldet_p1ba_p2main_result ? P1_hitbox_touching_P2_hurtbox : no_hit_at_the_moment;

				endcase

			end

			S_B_ATTACK_PULL:begin

				case p2_state

					S_B_ATTACK_END: hitresult = colldet_p1ba_p2ba_result ? P2_hitbox_touching_P1_hurtbox : no_hit_at_the_moment;
					default: hitresult = no_hit_at_the_moment;

				endcase

			end

			default:begin

					S_B_ATTACK_END: hitresult = colldet_p2ba_p1main_result ? P2_hitbox_touching_P1_hurtbox : no_hit_at_the_moment;
					default: hitresult = no_hit_at_the_moment;

			end
		endcase
	end

endmodule
