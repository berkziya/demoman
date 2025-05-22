module counter # (
  parameter W = 8
) (
  input clk_i,
  input rst_i, // Active-high reset
  input [1:0] control_i,
  output reg [W-1:0] count_o
);
  localparam INC = 2'b01;
  localparam DEC = 2'b10;

  always @(posedge clk_i) begin // Synchronous logic
    if (rst_i) begin // Active-high synchronous reset
      count_o <= {W{1'b0}};
    end else begin
      case (control_i)
        INC: count_o <= count_o + 1'b1;
        DEC: count_o <= count_o - 1'b1;
        default: count_o <= count_o; // Hold value
      endcase
    end
  end
endmodule
