module hextext_handler (
  input [2:0] hex_state,
  input [6:0] game_duration,

  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5
);
`include "charto7seg.vh"

localparam S_HEX_1P = 3'd0;
localparam S_HEX_2P = 3'd1;
localparam S_HEX_FIGHt = 3'd2;
localparam S_HEX_P1_WIN = 3'd3;
localparam S_HEX_P2_WIN = 3'd4;
localparam S_HEX_Eq = 3'd5;
localparam S_HEX_DEBUG = 3'd6;

reg [6:0] HEX_0, HEX_1, HEX_2, HEX_3, HEX_4, HEX_5;
assign HEX0 = HEX_0;
assign HEX1 = HEX_1;
assign HEX2 = HEX_2;
assign HEX3 = HEX_3;
assign HEX4 = HEX_4;
assign HEX5 = HEX_5;

wire [4:0] BCD_10s = game_duration / 10; // Tens digit
wire [4:0] BCD_1s  = game_duration % 10; // Ones digit

reg HEX_BDC_10s, HEX_BDC_1s;

always @(*) begin
  case (BCD_10s)
    0: HEX_BDC_10s = _0;
    1: HEX_BDC_10s = _1;
    2: HEX_BDC_10s = _2;
    3: HEX_BDC_10s = _3;
    4: HEX_BDC_10s = _4;
    5: HEX_BDC_10s = _5;
    6: HEX_BDC_10s = _6;
    7: HEX_BDC_10s = _7;
    8: HEX_BDC_10s = _8;
    9: HEX_BDC_10s = _9;
    default: HEX_BDC_10s = _SPACE; // Fallback
  endcase
  case (BCD_1s)
    0: HEX_BDC_1s = _0;
    1: HEX_BDC_1s = _1;
    2: HEX_BDC_1s = _2;
    3: HEX_BDC_1s = _3;
    4: HEX_BDC_1s = _4;
    5: HEX_BDC_1s = _5;
    6: HEX_BDC_1s = _6;
    7: HEX_BDC_1s = _7;
    8: HEX_BDC_1s = _8;
    9: HEX_BDC_1s = _9;
    default: HEX_BDC_1s = _SPACE; // Fallback
  endcase
end

always @(*) begin
  case (hex_state)
    S_HEX_1P: begin
      HEX_5 = _1;
      HEX_4 = _P;
      HEX_3 = _SPACE;
      HEX_2 = _SPACE;
      HEX_1 = _SPACE;
      HEX_0 = _SPACE;
    end
    S_HEX_2P: begin
      HEX_5 = _2;
      HEX_4 = _P;
      HEX_3 = _SPACE;
      HEX_2 = _SPACE;
      HEX_1 = _SPACE;
      HEX_0 = _SPACE;
    end
    S_HEX_FIGHt: begin
      HEX_5 = _F;
      HEX_4 = _I;
      HEX_3 = _G;
      HEX_2 = _H;
      HEX_1 = _T;
      HEX_0 = _SPACE;
    end
    S_HEX_P1_WIN: begin
      HEX_5 = _P;
      HEX_4 = _1;
      HEX_3 = _DASH;
      HEX_2 = HEX_BDC_10s;
      HEX_1 = HEX_BDC_1s;
      HEX_0 = _DASH;
    end
    S_HEX_P2_WIN: begin
      HEX_5 = _P;
      HEX_4 = _2;
      HEX_3 = _DASH;
      HEX_2 = HEX_BDC_10s;
      HEX_1 = HEX_BDC_1s;
      HEX_0 = _DASH;
    end
    S_HEX_Eq: begin
      HEX_5 = _E;
      HEX_4 = _Q;
      HEX_3 = _DASH;
      HEX_2 = HEX_BDC_10s;
      HEX_1 = HEX_BDC_1s;
      HEX_0 = _DASH;
    end
    S_HEX_DEBUG: begin // Debug state
      HEX_5 = _SPACE;
      HEX_4 = _SPACE;
      HEX_3 = _SPACE;
      HEX_2 = _SPACE;
      HEX_1 = HEX_BDC_10s; // Display tens digit of game duration
      HEX_0 = HEX_BDC_1s;  // Display ones digit of game duration
    end
    default: begin
      HEX_5 = _SPACE;
      HEX_4 = _SPACE;
      HEX_3 = _SPACE;
      HEX_2 = _SPACE;
      HEX_1 = HEX_BDC_10s; // Display tens digit of game duration
      HEX_0 = HEX_BDC_1s;  // Display ones digit of game duration
    end
  endcase
end

endmodule
