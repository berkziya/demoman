module game (
  input clk, // 60 Hz clock
  input reset,

  input [3:0] KEY,
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,

  input [9:0] SW,
  inout [35:0] GPIO,

  input [2:0] player1_state,
  input [2:0] player2_state,
  input [2:0] player1_health,
  input [2:0] player2_health,

  output reg [2:0] game_state,
  output [6:0] game_duration // 7-bit counter for game duration
);
localparam S_IDLE = 3'd0;
localparam S_COUNTDOWN = 3'd1;
localparam S_FIGHT = 3'd2;
localparam S_P1_WIN = 3'd3;
localparam S_P2_WIN = 3'd4;
localparam S_EQ = 3'd5;
reg [2:0] next_state;

localparam S_HEX_1P = 3'd0;
localparam S_HEX_2P = 3'd1;
localparam S_HEX_FIGHt = 3'd2;
localparam S_HEX_P1_WIN = 3'd3;
localparam S_HEX_P2_WIN = 3'd4;
localparam S_HEX_Eq = 3'd5;
reg [2:0] hex_state;

reg [1:0] counter_control; // 00: hold, 01: increment, 10: decrement, 11: reset

hextext_handler hextext_inst (
  .hex_state(hex_state),
  .game_duration(game_duration),
  .HEX0(HEX0),
  .HEX1(HEX1),
  .HEX2(HEX2),
  .HEX3(HEX3),
  .HEX4(HEX4),
  .HEX5(HEX5)
);

wire clk_1Hz;
clock_divider #(.DIV(60)) clk_div_inst ( // 60 Hz clock divider
  .clk(clk),
  .clk_o(clk_1Hz)
);

counter #(.W(7)) counter_inst ( // Game timer
  .clk(clk_1Hz),
  .rst(reset),
  .control(counter_control),
  .count(game_duration)
);

reg [6:0] last_counter_anchor;

always @(posedge clk or posedge reset) begin
  if (reset) begin
    game_state <= S_IDLE;
    counter_control <= 2'b11; // Reset the counter
  end else begin
    if (next_state != game_state) begin
      if (next_state == S_COUNTDOWN || next_state == S_FIGHT) begin
        counter_control <= 2'b11; // Reset the counter
      end else if (next_state == S_P1_WIN || next_state == S_P2_WIN || next_state == S_EQ) begin
        counter_control <= 2'b00; // Hold the counter
      end else begin
        counter_control <= 2'b11; // Reset the counter
      end
    end else begin
      if (game_state == S_COUNTDOWN || game_state == S_FIGHT) begin
        counter_control <= 2'b01; // Increment the counter
      end else if (game_state == S_P1_WIN || game_state == S_P2_WIN || game_state == S_EQ) begin
        counter_control <= 2'b00; // Hold the counter
      end else begin
        counter_control <= 2'b11; // Reset the counter
      end
    end
    game_state <= next_state;
  end
end

always @(*) begin
  case (game_state)
    S_IDLE: begin
      hex_state = SW[0] ? S_HEX_1P : S_HEX_2P;
      if (~KEY[0]) next_state = S_COUNTDOWN; // Start game on any key press
      else next_state = S_IDLE;
    end

    S_COUNTDOWN: begin
	   hex_state = hex_state;
      if (game_duration == 7'd4) next_state = S_FIGHT;
      else next_state = S_COUNTDOWN;
    end

    S_FIGHT: begin
      hex_state = S_HEX_FIGHt;
      if ((~(player1_health>0)) && (player2_health>0)) next_state = S_P2_WIN; // Player 2 wins
      else if ((player1_health>0) && (~(player2_health>0))) next_state = S_P1_WIN; // Player 1 wins
      else if ((~(player1_health>0)) && (~(player2_health>0))) next_state = S_EQ; // Draw
      else next_state = S_FIGHT; // Continue fighting
    end

    S_P1_WIN, S_P2_WIN, S_EQ: begin
      hex_state = (game_state == S_P1_WIN) ? S_HEX_P1_WIN :
                  (game_state == S_P2_WIN) ? S_HEX_P2_WIN : S_HEX_Eq;
      if (~KEY[0]) next_state = S_IDLE; // Reset game on key press
      else next_state = game_state; // Stay in the current state
    end

    default: next_state = S_IDLE; // Default case to handle unexpected states
				 hex_state = hex_state;
  endcase
end

endmodule
