module random_num #(
  parameter W = 32
) (
  input              clk,
  output reg [W-1:0] rand_o
);
  reg [W-1:0] seed = 32'hEEE12345; // Initial seed value, can be any non-zero value

  always @(posedge clk) begin
    seed   <= {seed[W-2:0], seed[W-1] ^ seed[W-2] ^ seed[W-3] ^ seed[W-4]};
    rand_o <= seed;
  end
endmodule
