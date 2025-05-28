module counter # (
  parameter W = 8
) (
  input              clk,
  input              rst,
  input        [1:0] control,
  output reg [W-1:0] count
);
  localparam INC = 2'b01;
  localparam DEC = 2'b10;

  always @(posedge clk or posedge rst) begin
    if (rst) count <= {W{1'b0}};
    else begin
      case (control)
        INC: count <= count + 1'b1;
        DEC: count <= count - 1'b1;
        default: ; // hold
      endcase
    end
  end
endmodule
