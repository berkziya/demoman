module charto7seg (
  output reg [6:0] 7seg_o, 		  // Output for 7-segment (gfedcba, 0=ON, 1=OFF)
  input      [5:0] char_i  // Input character code
);
  localparam _0 = 7'b1000000; // 0
  localparam _1 = 7'b1111001; // 1
  localparam _2 = 7'b0100100; // 2
  localparam _3 = 7'b0110000; // 3
  localparam _4 = 7'b0011001; // 4
  localparam _5 = 7'b0010010; // 5
  localparam _6 = 7'b0000010; // 6
  localparam _7 = 7'b1111000; // 7
  localparam _8 = 7'b0000000; // 8
  localparam _9 = 7'b0010000; // 9

  localparam _A = 7'b0001000; // A
  localparam _B = 7'b0000011; // b
  localparam _C = 7'b1000110; // C
  localparam _D = 7'b0100001; // d
  localparam _E = 7'b0000110; // E
  localparam _F = 7'b0001110; // F
  localparam _G = 7'b1000010; // G
  localparam _H = 7'b0001001; // H
  localparam _I = 7'b1111001; // I
  localparam _J = 7'b1110001; // J
  localparam _K = 7'b0001010; // (Custom K: H with a kicked leg)
  localparam _L = 7'b1000111; // L
  localparam _M = 7'b0101100; // (Custom M: like A with middle top, no center bar)
  localparam _N = 7'b0101011; // n
  localparam _O = 7'b1000000; // O
  localparam _P = 7'b0001100; // P
  localparam _Q = 7'b0011000; // (Like 9 with 'a', for Q)
  localparam _R = 7'b0101111; // r
  localparam _S = 7'b0010010; // S
  localparam _T = 7'b0000111; // t
  localparam _U = 7'b1000001; // U
  localparam _V = 7'b1100011; // (Lowercase u/v shape)
  localparam _W = 7'b1000001; // (Using U for W)
  localparam _X = 7'b0001001; // (Using H for X)
  localparam _Y = 7'b0010001; // Y
  localparam _Z = 7'b0110100; // Z

  localparam _SPACE      = 7'b1111111; // ' '
  localparam _DASH       = 7'b0111111; // '-'
  localparam _UNDERSCORE = 7'b1110111; // '_'

  localparam C_0=6'd0,  C_1=6'd1,  C_2=6'd2,  C_3=6'd3,  C_4=6'd4;
  localparam C_5=6'd5,  C_6=6'd6,  C_7=6'd7,  C_8=6'd8,  C_9=6'd9;
  localparam C_F=6'd15, C_A=6'd10, C_B=6'd11, C_C=6'd12, C_D=6'd13;
  localparam C_E=6'd14, C_G=6'd16, C_H=6'd17, C_I=6'd18, C_J=6'd19;
  localparam C_K=6'd20, C_L=6'd21, C_M=6'd22, C_N=6'd23, C_O=6'd24;
  localparam C_P=6'd25, C_Q=6'd26, C_R=6'd27, C_S=6'd28, C_T=6'd29;
  localparam C_U=6'd30, C_V=6'd31, C_W=6'd32, C_X=6'd33, C_Y=6'd34;
	localparam C_Z=6'd35, C_SPACE=6'd36, C_DASH=6'd37
	localparam C_UNDERSCORE=6'd38;

  always @(char_i) begin
    case (char_i)
      C_0: 7seg_o = _0;
      C_1: 7seg_o = _1;
      C_2: 7seg_o = _2;
      C_3: 7seg_o = _3;
      C_4: 7seg_o = _4;
      C_5: 7seg_o = _5;
      C_6: 7seg_o = _6;
      C_7: 7seg_o = _7;
      C_8: 7seg_o = _8;
      C_9: 7seg_o = _9;
      C_A: 7seg_o = _A;
      C_B: 7seg_o = _B;
      C_C: 7seg_o = _C;
      C_D: 7seg_o = _D;
      C_E: 7seg_o = _E;
      C_F: 7seg_o = _F;
      C_G: 7seg_o = _G;
      C_H: 7seg_o = _H;
      C_I: 7seg_o = _I;
      C_J: 7seg_o = _J;
      C_K: 7seg_o = _K;
      C_L: 7seg_o = _L;
      C_M: 7seg_o = _M;
      C_N: 7seg_o = _N;
      C_O: 7seg_o = _O;
      C_P: 7seg_o = _P;
      C_Q: 7seg_o = _Q;
      C_R: 7seg_o = _R;
      C_S: 7seg_o = _S;
      C_T: 7seg_o = _T;
      C_U: 7seg_o = _U;
      C_V: 7seg_o = _V;
      C_W: 7seg_o = _W;
      C_X: 7seg_o = _X;
      C_Y: 7seg_o = _Y;
      C_Z: 7seg_o = _Z;
      C_SPACE: 7seg_o = _SPACE;
      C_DASH:  7seg_o = _DASH;
      C_UNDERSCORE: 7seg_o = _UNDERSCORE;
      default: 7seg_o = _SPACE;
    endcase
  end
endmodule
