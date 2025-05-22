module counter # (
  parameter W = 8
) (
  input              clk_i,
  input              rst_i,
  input        [1:0] control_i,
  output reg [W-1:0] count_o
);
  localparam INC = 2'b01;
  localparam DEC = 2'b10;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) count_o <= {W{1'b0}};
    else begin
      case (control_i)
        INC: count_o <= count_o + 1'b1;
        DEC: count_o <= count_o - 1'b1;
        default: count_o <= count_o; //hold;
      endcase
    end
  end
endmodule
