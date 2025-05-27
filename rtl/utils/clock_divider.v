module clock_divider # (
  parameter DIV = 50 // DIV > 1
) (
  input      clk,
  input      rst,
  output reg clk_o
);
  localparam INC = 2'b01;
  localparam DEC = 2'b10;

  reg   [1:0] state;
  wire [31:0] count;

  counter #(.W(32)) cntr (
    .clk(clk),
    .rst(rst),
    .control(state),
    .count(count)
  );

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= INC;
      clk_o <= 1'b0;
    end
    case (state)
      INC:if (count == DIV - 1'b1) begin
        state <= DEC;
        clk_o <= 1'b1;
      end
      DEC:if (count == 32'b1) begin
        state <= INC;
        clk_o <= 1'b0;
      end
      default: begin
        state <= INC;
        clk_o <= 1'b0;
      end
    endcase
  end
endmodule
