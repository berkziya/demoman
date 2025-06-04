module CollisionDetect (
  input [9:0] a_x1,
  input [9:0] a_x2,
  input [9:0] a_y1,
  input [9:0] a_y2,

  input [9:0] b_x1,
  input [9:0] b_x2,
  input [9:0] b_y1,
  input [9:0] b_y2,

  output reg collision_result
);
  always @(*) begin
    if ((a_x2 >= b_x1) && (a_x1 <= b_x2) && (a_y1 <= b_y2) && (a_y2 >= b_y1))
      collision_result = 1'b1;
    else
      collision_result = 1'b0;
  end
endmodule
