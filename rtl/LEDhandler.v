module LEDhandler (
  input [2:0] game_state,
  input [2:0] p1_health,
  input [2:0] p2_health,
  input clk,

  output reg [9:0] LEDvalues
);

localparam S_IDLE = 3'd0;
localparam S_COUNTDOWN = 3'd1;
localparam S_FIGHT = 3'd2;
localparam S_P1_WIN = 3'd3;
localparam S_P2_WIN = 3'd4;
localparam S_EQ = 3'd5;

wire ledclk;

clock_divider #(.DIV(50000000)) ledclockinst(
	.clk(clk),
	.clk_o(ledclk)
);

  always @(*) begin
    case (LEDvalues)
		S_IDLE: LEDvalues[9:0] = 10'b0000000000; //menu mode, all leds off
		S_FIGHT: begin //indicate lives
			LEDvalues[6:3]=4'b0000;
			case (p1_health)
				3: LEDvalues[9:7] = 3'b111;
				2: LEDvalues[9:7] = 3'b110;
				1: LEDvalues[9:7] = 3'b100;
				default: LEDvalues[9:7] = 3'b000;
			endcase
			case (p2_health)
				3: LEDvalues[2:0] = 3'b111;
				2: LEDvalues[2:0] = 3'b110;
				1: LEDvalues[2:0] = 3'b100;
				default: LEDvalues[2:0] = 3'b000;
			endcase			
			end
		default: LEDvalues[9:0] = {10{ledclk}}; //blinking
	endcase
  end
endmodule
