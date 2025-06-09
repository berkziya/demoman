module rom (
  input clk,

  input [9:0] current_pixel_x,
  input [9:0] current_pixel_y,

  input [9:0] posx,
  input [9:0] posy,

  input [9:0] posx2,
  input [9:0] posy2,

  input [3:0] player1_state,
  input [3:0] player2_state,
  input [2:0] player1_health,
  input [2:0] player2_health,
  input [2:0] player1_block,
  input [2:0] player2_block,

  input [2:0] game_state, // Current game state
  input [6:0] game_duration, // Game duration in seconds

  output reg [7:0] pixel_data
);
// Game states
localparam S_IDLE = 3'd0;
localparam S_COUNTDOWN = 3'd1;
localparam S_FIGHT = 3'd2;
localparam S_P1_WIN = 3'd3;
localparam S_P2_WIN = 3'd4;
localparam S_EQ = 3'd5;


//// Player sprites
localparam SPRITE_WIDTH = 113;
localparam SPRITE_HEIGHT = 157;
localparam IMAGE_SIZE = SPRITE_WIDTH * SPRITE_HEIGHT;
localparam [7:0] TRANSPARENT_COLOR = 8'b11100011; // Transparent color value (magenta)

reg [7:0] rom_sprite, rom_sprite2; // ROM sprite pixel_data
wire [7:0] rom_sprite_attackendG,
           rom_sprite_attackendR,
           rom_sprite_attackpullG,
           rom_sprite_attackpullR,
           rom_sprite_attackstartG,
           rom_sprite_attackstartR,
           rom_sprite_blockG,
           rom_sprite_blockR,
           rom_sprite_dirattendG,
           rom_sprite_dirattendR,
           rom_sprite_dirattpullG,
           rom_sprite_dirattpullR,
           rom_sprite_dirattstartG,
           rom_sprite_dirattstartR,
           rom_sprite_gothitG,
           rom_sprite_gothitR,
           rom_sprite_idleG,
           rom_sprite_idleR,
           rom_sprite_walkbackG,
           rom_sprite_walkbackR,
           rom_sprite_walkG,
           rom_sprite_walkR;

wire [9:0] relative_x = current_pixel_x - posx;
wire [9:0] relative_y = current_pixel_y - posy;
wire [9:0] relative_x2 = current_pixel_x - posx2;
wire [9:0] relative_y2 = current_pixel_y - posy2;
wire [14:0] addr, addr2;

wire inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + SPRITE_WIDTH) &&
                     (current_pixel_y >= posy && current_pixel_y < posy + SPRITE_HEIGHT);
assign addr = (relative_y * SPRITE_WIDTH) + relative_x;

wire inside_sprite2 = (current_pixel_x >= posx2 && current_pixel_x < posx2 + SPRITE_WIDTH) &&
                      (current_pixel_y >= posy2 && current_pixel_y < posy2 + SPRITE_HEIGHT);
assign addr2 = (relative_y2 * SPRITE_WIDTH) + relative_x2;

// Instantiate ROM modules for each sprite state
// Each ROM module corresponds to a specific sprite state for each player

rom_attackendG rom_inst_attackendG (.address(addr), .clock(clk), .q(rom_sprite_attackendG));
rom_attackendR rom_inst_attackendR (.address(addr2), .clock(clk), .q(rom_sprite_attackendR));
rom_attackpullG rom_inst_attackpullG (.address(addr), .clock(clk), .q(rom_sprite_attackpullG));
rom_attackpullR rom_inst_attackpullR (.address(addr2), .clock(clk), .q(rom_sprite_attackpullR));
rom_attackstartG rom_inst_attackstartG (.address(addr), .clock(clk), .q(rom_sprite_attackstartG));
rom_attackstartR rom_inst_attackstartR (.address(addr2), .clock(clk), .q(rom_sprite_attackstartR));
rom_blockG rom_inst_blockG (.address(addr), .clock(clk), .q(rom_sprite_blockG));
rom_blockR rom_inst_blockR (.address(addr2), .clock(clk), .q(rom_sprite_blockR));
rom_dirattendG rom_inst_dirattendG (.address(addr), .clock(clk), .q(rom_sprite_dirattendG));
rom_dirattendR rom_inst_dirattendR (.address(addr2), .clock(clk), .q(rom_sprite_dirattendR));
rom_dirattpullG rom_inst_dirattpullG (.address(addr), .clock(clk), .q(rom_sprite_dirattpullG));
rom_dirattpullR rom_inst_dirattpullR (.address(addr2), .clock(clk), .q(rom_sprite_dirattpullR));
rom_dirattstartG rom_inst_dirattstartG (.address(addr), .clock(clk), .q(rom_sprite_dirattstartG));
rom_dirattstartR rom_inst_dirattstartR (.address(addr2), .clock(clk), .q(rom_sprite_dirattstartR));
rom_gothitG rom_inst_gothitG (.address(addr), .clock(clk), .q(rom_sprite_gothitG));
rom_gothitR rom_inst_gothitR (.address(addr2), .clock(clk), .q(rom_sprite_gothitR));
rom_idleG rom_inst_idleG (.address(addr), .clock(clk), .q(rom_sprite_idleG));
rom_idleR rom_inst_idleR (.address(addr2), .clock(clk), .q(rom_sprite_idleR));
rom_walkbackG rom_inst_walkbackG (.address(addr), .clock(clk), .q(rom_sprite_walkbackG));
rom_walkbackR rom_inst_walkbackR (.address(addr2), .clock(clk), .q(rom_sprite_walkbackR));
rom_walkG rom_inst_walkG (.address(addr), .clock(clk), .q(rom_sprite_walkG));
rom_walkR rom_inst_walkR (.address(addr2), .clock(clk), .q(rom_sprite_walkR));

always @(*) begin
  case (player1_state)
    4'd0: rom_sprite = rom_sprite_idleG; // Idle state
    4'd1: rom_sprite = rom_sprite_walkG; // Move forward state
    4'd2: rom_sprite = rom_sprite_walkbackG; // Move backward state
    4'd3: rom_sprite = rom_sprite_attackstartG; // Attack start state
    4'd4: rom_sprite = rom_sprite_attackendG; // Attack end state
    4'd5: rom_sprite = rom_sprite_attackpullG; // Attack pull state
    4'd6: rom_sprite = rom_sprite_dirattstartG; // Directional attack start state
    4'd7: rom_sprite = rom_sprite_dirattendG; // Directional attack end state
    4'd8: rom_sprite = rom_sprite_dirattpullG; // Directional attack pull state
    4'd9: rom_sprite = rom_sprite_gothitG; // Hit state
    4'd10: rom_sprite = rom_sprite_blockG; // Block state
    default: rom_sprite = TRANSPARENT_COLOR;
  endcase

  case (player2_state)
    4'd0: rom_sprite2 = rom_sprite_idleR; // Idle state
    4'd1: rom_sprite2 = rom_sprite_walkR; // Move forward state
    4'd2: rom_sprite2 = rom_sprite_walkbackR; // Move backward state
    4'd3: rom_sprite2 = rom_sprite_attackstartR; // Attack start state
    4'd4: rom_sprite2 = rom_sprite_attackendR; // Attack end state
    4'd5: rom_sprite2 = rom_sprite_attackpullR; // Attack pull state
    4'd6: rom_sprite2 = rom_sprite_dirattstartR; // Directional attack start state
    4'd7: rom_sprite2 = rom_sprite_dirattendR; // Directional attack end state
    4'd8: rom_sprite2 = rom_sprite_dirattpullR; // Directional attack pull state
    4'd9: rom_sprite2 = rom_sprite_gothitR; // Hit state
    4'd10: rom_sprite2 = rom_sprite_blockR; // Block state
    default: rom_sprite2 = TRANSPARENT_COLOR;
  endcase
end

//// Heartbox and Blockbox sprites
localparam [9:0] HEARTBLOCK_SIZE = 10'd50; // Size of the heartbox
localparam [9:0] X_OFFSET = 10'd40; // X offset for heartbox coordinates
localparam [9:0] Y_OFFSET = 10'd40; // Y offset for heartbox coordinates
localparam [9:0] SPACE_BETWEEN = HEARTBLOCK_SIZE + 10'd20; // Space between heartboxes

localparam [7:0] HEARTBLOCK_COLOR = 8'b11100000; // Color for heartbox (red)
localparam [7:0] BLOCKBLOCK_COLOR = 8'b00000011; // Color for blockbox (blue)

wire [9:0] heart11x, heart11y, heart12x, heart12y, heart13x, heart13y; // Heartbox coordinates for player 1
wire [9:0] heart21x, heart21y, heart22x, heart22y, heart23x, heart23y; // Heartbox coordinates for player 2

wire [9:0] block11x, block11y, block12x, block12y, block13x, block13y; // Blockbox coordinates for player 1
wire [9:0] block21x, block21y, block22x, block22y, block23x, block23y; // Blockbox coordinates for player 2

assign heart11x = X_OFFSET;
assign heart11y = Y_OFFSET;
assign heart12x = X_OFFSET + SPACE_BETWEEN;
assign heart12y = Y_OFFSET;
assign heart13x = X_OFFSET + 2 * SPACE_BETWEEN;
assign heart13y = Y_OFFSET;

assign heart21x = 640 - X_OFFSET - HEARTBLOCK_SIZE;
assign heart21y = Y_OFFSET;
assign heart22x = 640 - X_OFFSET - HEARTBLOCK_SIZE - SPACE_BETWEEN;
assign heart22y = Y_OFFSET;
assign heart23x = 640 - X_OFFSET - HEARTBLOCK_SIZE - 2 * SPACE_BETWEEN;
assign heart23y = Y_OFFSET;

assign block11x = X_OFFSET;
assign block11y = 480 - Y_OFFSET - HEARTBLOCK_SIZE;
assign block12x = X_OFFSET + SPACE_BETWEEN;
assign block12y = 480 - Y_OFFSET - HEARTBLOCK_SIZE;
assign block13x = X_OFFSET + 2 * SPACE_BETWEEN;
assign block13y = 480 - Y_OFFSET - HEARTBLOCK_SIZE;

assign block21x = 640 - X_OFFSET - HEARTBLOCK_SIZE;
assign block21y = 480 - Y_OFFSET - HEARTBLOCK_SIZE;
assign block22x = 640 - X_OFFSET - HEARTBLOCK_SIZE - SPACE_BETWEEN;
assign block22y = 480 - Y_OFFSET - HEARTBLOCK_SIZE;
assign block23x = 640 - X_OFFSET - HEARTBLOCK_SIZE - 2 * SPACE_BETWEEN;
assign block23y = 480 - Y_OFFSET - HEARTBLOCK_SIZE;

wire is_heartbox = ((current_pixel_x >= heart11x && current_pixel_x < heart11x + HEARTBLOCK_SIZE && player1_health >= 1) ||
                    (current_pixel_x >= heart12x && current_pixel_x < heart12x + HEARTBLOCK_SIZE && player1_health >= 2) ||
                    (current_pixel_x >= heart13x && current_pixel_x < heart13x + HEARTBLOCK_SIZE && player1_health >= 3) ||
                    (current_pixel_x >= heart21x && current_pixel_x < heart21x + HEARTBLOCK_SIZE && player2_health >= 1) ||
                    (current_pixel_x >= heart22x && current_pixel_x < heart22x + HEARTBLOCK_SIZE && player2_health >= 2) ||
                    (current_pixel_x >= heart23x && current_pixel_x < heart23x + HEARTBLOCK_SIZE && player2_health >= 3)) &&
                    (current_pixel_y >= heart11y && current_pixel_y < heart11y + HEARTBLOCK_SIZE) && // Assume heartboxes are aligned vertically
                    (current_pixel_y >= heart21y && current_pixel_y < heart21y + HEARTBLOCK_SIZE);

wire is_blockbox = ((current_pixel_x >= block11x && current_pixel_x < block11x + HEARTBLOCK_SIZE && player1_block >= 1) ||
                    (current_pixel_x >= block12x && current_pixel_x < block12x + HEARTBLOCK_SIZE && player1_block >= 2) ||
                    (current_pixel_x >= block13x && current_pixel_x < block13x + HEARTBLOCK_SIZE && player1_block >= 3) ||
                    (current_pixel_x >= block21x && current_pixel_x < block21x + HEARTBLOCK_SIZE && player2_block >= 1) ||
                    (current_pixel_x >= block22x && current_pixel_x < block22x + HEARTBLOCK_SIZE && player2_block >= 2) ||
                    (current_pixel_x >= block23x && current_pixel_x < block23x + HEARTBLOCK_SIZE && player2_block >= 3)) &&
                    (current_pixel_y >= block11y && current_pixel_y < block11y + HEARTBLOCK_SIZE) && // Assume blockboxes are aligned vertically
                    (current_pixel_y >= block21y && current_pixel_y < block21y + HEARTBLOCK_SIZE);


wire [9:0] where_in_heartbox_x = current_pixel_x >= heart21x ? current_pixel_x - heart21x :
                                 current_pixel_x >= heart22x ? current_pixel_x - heart22x :
                                 current_pixel_x >= heart23x ? current_pixel_x - heart23x :
                                 current_pixel_x >= heart13x ? current_pixel_x - heart13x :
                                 current_pixel_x >= heart12x ? current_pixel_x - heart12x :
                                 current_pixel_x - heart11x;

wire [9:0] where_in_heartbox_y = current_pixel_y - heart11y;

wire [9:0] where_in_blockbox_x = current_pixel_x >= block21x ? current_pixel_x - block21x :
                                 current_pixel_x >= block22x ? current_pixel_x - block22x :
                                 current_pixel_x >= block23x ? current_pixel_x - block23x :
                                 current_pixel_x >= block13x ? current_pixel_x - block13x :
                                 current_pixel_x >= block12x ? current_pixel_x - block12x :
                                 current_pixel_x - block11x;

wire [9:0] where_in_blockbox_y = current_pixel_y - block11y;

wire [11:0] heart_addr = (where_in_heartbox_y * HEARTBLOCK_SIZE + where_in_heartbox_x);
wire [11:0] block_addr = (where_in_blockbox_y * HEARTBLOCK_SIZE + where_in_blockbox_x);

wire [7:0] heart_sprite_data, block_sprite_data;

rom_heart rom_heart_inst (
  .address(heart_addr >> 3),
  .clock(clk),
  .q(heart_sprite_data) // Output pixel data for heartbox
);

rom_shield rom_block_inst (
  .address(block_addr >> 3),
  .clock(clk),
  .q(block_sprite_data) // Output pixel data for blockbox
);

//// Countdown sprites
localparam COUNT_DOWN_WIDTH = 10;
localparam COUNT_DOWN_HEIGHT = 13;
localparam COUNT_DOWN_SIZE = COUNT_DOWN_WIDTH * COUNT_DOWN_HEIGHT;
localparam COUNT_DOWN_BYTE_SIZE = (COUNT_DOWN_SIZE + 7) / 8;
localparam COUNT_DOWN_ADDR_SIZE = $clog2(COUNT_DOWN_BYTE_SIZE);
localparam COUNTDOWN_SIZE = COUNT_DOWN_WIDTH * COUNT_DOWN_HEIGHT;
localparam COUNTDOWN_X_OFFSET = 320 - COUNT_DOWN_WIDTH / 2;
localparam COUNTDOWN_Y_OFFSET = 240 - COUNT_DOWN_HEIGHT / 2;
localparam [7:0] COUNTDOWN_COLOR = 8'b11111111; // Color for countdown (magenta)
localparam [7:0] COUNTDOWN_BG_COLOR = 8'b00000000; // Color for countdown (black)

wire [9:0] countdown_relative_x = current_pixel_x - COUNTDOWN_X_OFFSET;
wire [9:0] countdown_relative_y = current_pixel_y - COUNTDOWN_Y_OFFSET;
wire is_countdown_area = (current_pixel_x >= COUNTDOWN_X_OFFSET &&
                          current_pixel_x < COUNTDOWN_X_OFFSET + COUNT_DOWN_WIDTH &&
                          current_pixel_y >= COUNTDOWN_Y_OFFSET &&
                          current_pixel_y < COUNTDOWN_Y_OFFSET + COUNT_DOWN_HEIGHT);

wire [COUNT_DOWN_ADDR_SIZE-1:0] count_down_addr = countdown_relative_y * COUNT_DOWN_WIDTH + countdown_relative_x;

wire [7:0] pixel_data_countdown3, pixel_data_countdown2, pixel_data_countdown1; // Output pixel data for countdown

rom_digit3 rom_digit3_inst (.clock(clk), .address(count_down_addr >> 3), .q(pixel_data_countdown3));
rom_digit2 rom_digit2_inst (.clock(clk), .address(count_down_addr >> 3), .q(pixel_data_countdown2));
rom_digit1 rom_digit1_inst (.clock(clk), .address(count_down_addr >> 3), .q(pixel_data_countdown1));

//// Counter
localparam COUNTER_WIDTH = 20;
localparam COUNTER_HEIGHT = 13;
localparam X_OFFSET_COUNTER = 320 - COUNTER_WIDTH / 2;
localparam Y_OFFSET_COUNTER = 60;
wire [7:0] pixel_data_counter; // Output pixel data for counter

wire [9:0] counter_relative_x = current_pixel_x - X_OFFSET_COUNTER;
wire [9:0] counter_relative_y = current_pixel_y - Y_OFFSET_COUNTER;
wire is_counter_area = (current_pixel_x >= X_OFFSET_COUNTER &&
                        current_pixel_x < X_OFFSET_COUNTER + COUNTER_WIDTH &&
                        current_pixel_y >= Y_OFFSET_COUNTER &&
                        current_pixel_y < Y_OFFSET_COUNTER + COUNTER_HEIGHT);

rom_but_only_digits rom_counter_inst (
  .clk(clk),
  .relative_x(counter_relative_x),
  .relative_y(counter_relative_y),
  .game_duration(game_duration),
  .pixel_data(pixel_data_counter) // Output pixel data for counter
);


reg [7:0] next_pixel_data;

always @(*) begin
  // Heartbox and Blockbox pixel data selection
  case (game_state)
    S_IDLE: next_pixel_data <= 8'b00000000;

    S_COUNTDOWN: begin
      if (is_countdown_area) begin
        case (game_duration)
          7'd1: next_pixel_data <= pixel_data_countdown3[7 - (count_down_addr % 8)] ?
                                   COUNTDOWN_COLOR :
                                   COUNTDOWN_BG_COLOR;
          7'd2: next_pixel_data <= pixel_data_countdown2[7 - (count_down_addr % 8)] ?
                                   COUNTDOWN_COLOR :
                                   COUNTDOWN_BG_COLOR;
          7'd3: next_pixel_data <= pixel_data_countdown1[7 - (count_down_addr % 8)] ?
                                   COUNTDOWN_COLOR :
                                   COUNTDOWN_BG_COLOR;
          default: next_pixel_data <= COUNTDOWN_BG_COLOR; // Default background color
        endcase
      end
    end

    S_FIGHT: begin
      if (is_counter_area) begin
        next_pixel_data <= pixel_data_counter; // Display counter
      end else if (is_heartbox) begin
        next_pixel_data <= heart_sprite_data[7 - (heart_addr % 8)] ?
                           HEARTBLOCK_COLOR :
                           TRANSPARENT_COLOR;
      end else if (is_blockbox) begin
        next_pixel_data <= block_sprite_data[7 - (block_addr % 8)] ?
                           BLOCKBLOCK_COLOR :
                           TRANSPARENT_COLOR;
      // Player 2 or Player 1 sprite pixel data selection
      end else if (inside_sprite && addr < IMAGE_SIZE && rom_sprite != TRANSPARENT_COLOR) begin
        next_pixel_data <= rom_sprite;
      end else if (inside_sprite2 && addr2 < IMAGE_SIZE && rom_sprite2 != TRANSPARENT_COLOR) begin
        next_pixel_data <= rom_sprite2;
      // Default pixel data (transparent color)
      end else next_pixel_data <= TRANSPARENT_COLOR;
    end
  endcase
end

always @(posedge clk) begin
  pixel_data <= next_pixel_data;
end

endmodule
