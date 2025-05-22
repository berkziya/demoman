module charto7seg (
  output reg [6:0] seg_o, // Output for 7-segment (gfedcba, 0=ON, 1=OFF)
  input      [5:0] char_i  // Input character code
);
  // Definitions
  localparam _0=6'd0,  _1=6'd1,  _2=6'd2,  _3=6'd3,  _4=6'd4;  // 0-4
  localparam _5=6'd5,  _6=6'd6,  _7=6'd7,  _8=6'd8,  _9=6'd9;  // 5-9

  localparam _A=6'hA,  _B=6'hB,  _C=6'hC,  _D=6'hD,  _E=6'hE;  // A-E
  localparam _F=6'hF,  _G=6'd16, _H=6'd17, _I=6'd18, _J=6'd19; // F-J
  localparam _K=6'd20, _L=6'd21, _M=6'd22, _N=6'd23, _O=6'd24; // K-O
  localparam _P=6'd25, _Q=6'd26, _R=6'd27, _S=6'd28, _T=6'd29; // P-Q
  localparam _U=6'd30, _V=6'd31, _W=6'd32, _X=6'd33, _Y=6'd34; // U-Y
	localparam _Z=6'd35;                                         // Z

  localparam _SPACE=6'd36;                                     // ' '
  localparam _DASH=6'd37;                                      // '-'
	localparam _UNDERSCORE=6'd38;                                // '_'
  localparam _LOWSQUARE=6'd39;                                 // 'o'
  localparam _HIGHSQUARE=6'd40;                                // 'o' but flying

  // Transformations
  //    a
  //  f   b
  //    g
  //  e   c
  //    d
  //                  gfedcba
  localparam T_0 = 7'b1000000; // 0
  localparam T_1 = 7'b1111001; // 1
  localparam T_2 = 7'b0100100; // 2
  localparam T_3 = 7'b0110000; // 3
  localparam T_4 = 7'b0011001; // 4
  localparam T_5 = 7'b0010010; // 5
  localparam T_6 = 7'b0000010; // 6
  localparam T_7 = 7'b1111000; // 7
  localparam T_8 = 7'b0000000; // 8
  localparam T_9 = 7'b0010000; // 9

  localparam T_A = 7'b0001000; // A
  localparam T_B = 7'b0000011; // b
  localparam T_C = 7'b1000110; // C
  localparam T_D = 7'b0100001; // d
  localparam T_E = 7'b0000110; // E
  localparam T_F = 7'b0001110; // F
  localparam T_G = 7'b1000010; // G
  localparam T_H = 7'b0001001; // H
  localparam T_I = 7'b1111001; // I
  localparam T_J = 7'b1110001; // J
  localparam T_K = 7'b0001010; // (Custom K: H with a kicked leg)
  localparam T_L = 7'b1000111; // L
  localparam T_M = 7'b0101100; // (Custom M: like A with middle top, no center bar)
  localparam T_N = 7'b0101011; // n
  localparam T_O = 7'b1000000; // 0
  localparam T_P = 7'b0001100; // P
  localparam T_Q = 7'b0011000; // (Like 9 with 'a', for Q)
  localparam T_R = 7'b0101111; // r
  localparam T_S = 7'b0010010; // S
  localparam T_T = 7'b0000111; // t
  localparam T_U = 7'b1000001; // U
  localparam T_V = 7'b1100011; // (Lowercase u/v shape)
  localparam T_W = 7'b1000001; // (Using U for W)
  localparam T_X = 7'b0001001; // (Using H for X)
  localparam T_Y = 7'b0010001; // Y
  localparam T_Z = 7'b0110100; // Z

  localparam T_SPACE      = 7'b1111111; // ' '
  localparam T_DASH       = 7'b0111111; // '-'
  localparam T_UNDERSCORE = 7'b1110111; // '_'
  localparam T_LOWSQUARE  = 7'b0011100; // 'o'
  localparam T_HIGHSQUARE = 7'b0100011; // 'o' but flying

  always @(char_i) begin
    case (char_i)
      _0: seg_o = T_0;
      _1: seg_o = T_1;
      _2: seg_o = T_2;
      _3: seg_o = T_3;
      _4: seg_o = T_4;
      _5: seg_o = T_5;
      _6: seg_o = T_6;
      _7: seg_o = T_7;
      _8: seg_o = T_8;
      _9: seg_o = T_9;
      _A: seg_o = T_A;
      _B: seg_o = T_B;
      _C: seg_o = T_C;
      _D: seg_o = T_D;
      _E: seg_o = T_E;
      _F: seg_o = T_F;
      _G: seg_o = T_G;
      _H: seg_o = T_H;
      _I: seg_o = T_I;
      _J: seg_o = T_J;
      _K: seg_o = T_K;
      _L: seg_o = T_L;
      _M: seg_o = T_M;
      _N: seg_o = T_N;
      _O: seg_o = T_O;
      _P: seg_o = T_P;
      _Q: seg_o = T_Q;
      _R: seg_o = T_R;
      _S: seg_o = T_S;
      _T: seg_o = T_T;
      _U: seg_o = T_U;
      _V: seg_o = T_V;
      _W: seg_o = T_W;
      _X: seg_o = T_X;
      _Y: seg_o = T_Y;
      _Z: seg_o = T_Z;
      _SPACE: seg_o = T_SPACE;
      _DASH: seg_o = T_DASH;
      _UNDERSCORE: seg_o = T_UNDERSCORE;
      _LOWSQUARE: seg_o = T_LOWSQUARE;
      _HIGHSQUARE: seg_o = T_HIGHSQUARE;
      default: seg_o = T_SPACE;
    endcase
  end
endmodule
