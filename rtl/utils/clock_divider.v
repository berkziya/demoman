module clock_divider #(
  parameter DIV_FACTOR_WIDTH = 8
) (
  input clk_i,
  input rst_i,
  input [DIV_FACTOR_WIDTH-1:0] div_factor_input,
  output reg clk_o
);

  reg [DIV_FACTOR_WIDTH-1:0] counter_reg;
  reg [DIV_FACTOR_WIDTH-1:0] effective_div_factor;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      counter_reg          <= 0;
      clk_o                <= 1'b0;
      effective_div_factor <= 2;
    end else begin
      if (counter_reg == 0) begin
        if (div_factor_input < 2) begin
          effective_div_factor <= 2;
        end else begin
          effective_div_factor <= div_factor_input;
        end
      end

      if (counter_reg == (effective_div_factor >> 1) - 1'b1) begin
        counter_reg <= 0;
        clk_o       <= ~clk_o;
      end else begin
        counter_reg <= counter_reg + 1'b1;
      end
    end
  end
endmodule
