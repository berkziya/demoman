module clock_divider #(
  parameter DIV = 50_000_000
) (
  input clk, //original clock (50MHz)
  output reg clk_o //divided, slower clock
);
  wire [31:0] currentCount;
  reg  [31:0] lastSwitchedAt;

	counter #(
    .W(32)
  ) counter_inst (
    .clk(clk),
    .rst(1'b0),
    .control(2'b01),
    .count(currentCount)
	);

  always @(posedge clk) begin
    if ((currentCount - lastSwitchedAt) >= (DIV>>1)) begin
      lastSwitchedAt <= currentCount;
      clk_o <= ~clk_o;
    end
  end
endmodule
