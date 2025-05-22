module clock_divider # (
  parameter DIV = 50 // DIV > 1
) (
  input      clk_i,
  input      rst_i,
  output reg clk_o
);
  localparam INC = 2'b01;
  localparam DEC = 2'b10;

  reg   [1:0] STATE;
  wire [31:0] count;

  counter #(.W(32)) cntr (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .control_i(STATE),
    .count_o(count)
  );

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      STATE <= INC;
      clk_o <= 1'b0;
    end
    case (STATE)
      INC:if (count == DIV - 1'b1) begin
        STATE <= DEC;
        clk_o <= 1'b1;
      end
      DEC:if (count == 32'b1) begin
        STATE <= INC;
        clk_o <= 1'b0;
      end
      default: begin
        STATE <= INC;
        clk_o <= 1'b0;
      end
    endcase
  end
endmodule
