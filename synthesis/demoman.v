module demoman(
  /////////// CLOCK ///////////
  input CLOCK2_50,
  input CLOCK3_50,
  input CLOCK4_50,
  input CLOCK_50,

  /////////// SDRAM ///////////
  output [12:0] DRAM_ADDR,
  output  [1:0] DRAM_BA,
  output        DRAM_CAS_N,
  output        DRAM_CKE,
  output        DRAM_CLK,
  output        DRAM_CS_N,
  inout  [15:0] DRAM_DQ,
  output        DRAM_LDQM,
  output        DRAM_RAS_N,
  output        DRAM_UDQM,
  output        DRAM_WE_N,

  /////////// SEG7 ///////////
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [6:0] HEX2,
  output [6:0] HEX3,
  output [6:0] HEX4,
  output [6:0] HEX5,

  /////////// KEY ///////////
  input [3:0] KEY,

  /////////// LED ///////////
  output [9:0] LEDR,

  /////////// SW ///////////
  input [9:0] SW,

  /////////// VGA ///////////
  output       VGA_BLANK_N,
  output [7:0] VGA_B,
  output       VGA_CLK,
  output [7:0] VGA_G,
  output       VGA_HS,
  output [7:0] VGA_R,
  output       VGA_SYNC_N,
  output       VGA_VS,

  //////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
  inout [35:0] GPIO
);

//=======================================================
//  REG/WIRE declarations
//=======================================================



wire [3:0] player1_state; // First player's state
wire [3:0] player2_state; // Second player's state

wire [9:0] posx; // Player 1's X position
wire [9:0] posy; // Player 1's Y position
wire [9:0] posx2; // Player 2's X position
wire [9:0] posy2; // Player 2's Y position

wire [7:0] color_to_vga_driver; // Input color to VGA driver (RRRGGGBB)
wire [9:0] current_pixel_x;     // X-coordinate from vga_driver
wire [9:0] current_pixel_y;     // Y-coordinate from vga_driver

wire [9:0] hithurt_x1, hithurt_x2, hithurt_y1, hithurt_y2; // Basic hit hurtbox coordinates
wire [9:0] hithurt_x12, hithurt_x22, hithurt_y12, hithurt_y22; // Second player's basic hit hurtbox coordinates
wire [9:0] hurt_x1, hurt_x2, hurt_y1, hurt_y2; // Main hurtbox coordinates
wire [9:0] hurt_x12, hurt_x22, hurt_y12, hurt_y22; // Second player's main hurtbox coordinates
wire [9:0] dir_hithurt_x1, dir_hithurt_x2, dir_hithurt_y1, dir_hithurt_y2; // Directional hit hurtbox coordinates
wire [9:0] dir_hithurt_x12, dir_hithurt_x22, dir_hithurt_y12, dir_hithurt_y22; // Second player's directional hit hurtbox coordinates
wire [1:0] hasbeenHit1; // Flag indicating if Player 1 has been hit
wire [1:0] hasbeenHit2; // Flag indicating if Player 2 has been hit

wire [2:0] game_state, game_duration; // Game state and duration

//=======================================================
//  Structural coding
//=======================================================

wire reset;

assign reset = ((game_state==3'd0)|(game_state==3'd3)|(game_state==3'd4)|(game_state==3'd5))&((~KEY[3])|(~KEY[2])|(~KEY[1]));

wire clk_25mhz;
clock_divider #(
  .DIV(2)
) clk4vga_inst (
  .clk(CLOCK_50),
  .clk_o(clk_25mhz)
);

// Instantiate the VGA driver
vga_driver vga_inst (
  .clock(clk_25mhz),
  .reset(1'b0),
  .color_in(color_to_vga_driver), // Color data for the current pixel
  .next_x(current_pixel_x),       // Output: X-coordinate of the pixel being drawn
  .next_y(current_pixel_y),       // Output: Y-coordinate of the pixel being drawn
  .hsync(VGA_HS),                 // Output: Horizontal sync
  .vsync(VGA_VS),                 // Output: Vertical sync
  .red(VGA_R),                    // Output: Red component
  .green(VGA_G),                  // Output: Green component
  .blue(VGA_B),                   // Output: Blue component
  .sync(),                        // vga_driver's composite sync output (can be left unconnected)
  .clk(VGA_CLK),                  // vga_driver passes its clock input to this VGA connector pin
  .blank(VGA_BLANK_N)             // Output: High during active display period
);

wire effective_clk;
effective_clock_generator effective_clk_inst (
  .SW(SW[1]), // Switches for clock selection
  .KEY(KEY[0]), // Keys for control
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .effective_clk(effective_clk) // Output effective clock signal based on switch state
);

wire clk_1Hz;
clock_divider #(.DIV(60)) clk_div_inst ( // 60 Hz clock divider
  .clk(effective_clk),
  .clk_o(clk_1Hz)
);


wire [2:0] player1_health, player2_health;
wire [2:0] player1_block, player2_block;
health_status health_status_inst (
  .clk(effective_clk),
  .rst(reset),
  .player1_state(player1_state),
  .player2_state(player2_state),
  .player1_health(player1_health),
  .player2_health(player2_health),
  .player1_block(player1_block),
  .player2_block(player2_block)
);


player #(.SIDE(1'b0)) Player1 (
  .clk(effective_clk),
  .rst(reset),
  .gamestate(game_state),
  .otherPlayerposx(posx2),
  .left(~KEY[3]), // Player 1's left control, can be controlled by a switch
  .right(~KEY[2]), // Player 1's right control, can be controlled by a switch
  .attack(~KEY[1]), // Player 1's attack control, can be controlled by a switch
  .hitFlag(hasbeenHit1), // Hit flag for Player 1
  .posx(posx),
  .posy(posy),
  .current_state(player1_state),
  .health(player1_health),
  .block(player1_block),

  .basic_hithurtbox_x1(hithurt_x1),
  .basic_hithurtbox_x2(hithurt_x2),
  .basic_hithurtbox_y1(hithurt_y1),
  .basic_hithurtbox_y2(hithurt_y2),
  .main_hurtbox_x1(hurt_x1),
  .main_hurtbox_x2(hurt_x2),
  .main_hurtbox_y1(hurt_y1),
  .main_hurtbox_y2(hurt_y2),
  .dir_hithurtbox_x1(dir_hithurt_x1),
  .dir_hithurtbox_x2(dir_hithurt_x2),
  .dir_hithurtbox_y1(dir_hithurt_y1),
  .dir_hithurtbox_y2(dir_hithurt_y2)
);


wire random_num_clk;
clock_divider #(
  .DIV(44) // Player 2 random movement clock divider, higher is slower
) random_num_clk_divider (
  .clk(effective_clk),
  .clk_o(random_num_clk)
);

wire [31:0] random_number;
random_num random_gen (
  .clk(random_num_clk),
  .rand_o(random_number)
);

wire player2_left = ~SW[0] ? ~GPIO[5] : random_number[0];
wire player2_right = ~SW[0] ? ~GPIO[3] : random_number[1];
wire player2_attack = ~SW[0] ? ~GPIO[1] : (random_number[2] & random_number[3]);


player #(.SIDE(1'b1)) Player2 (
  .clk(effective_clk),
  .rst(reset),
  .gamestate(game_state),
  .otherPlayerposx(posx),
  .left(player2_left), // Player 2's left control, can be controlled by a switch or random number
  .right(player2_right), // Player 2's right control, can be controlled by a switch or random number
  .attack(player2_attack), // Player 2's attack control, can be controlled by a switch or random number
  .hitFlag(hasbeenHit2), // Hit flag for Player 2
  .posx(posx2),
  .posy(posy2),
  .current_state(player2_state),
  .health(player2_health),
  .block(player2_block),
  
  .basic_hithurtbox_x1(hithurt_x12),
  .basic_hithurtbox_x2(hithurt_x22),
  .basic_hithurtbox_y1(hithurt_y12),
  .basic_hithurtbox_y2(hithurt_y22),
  .main_hurtbox_x1(hurt_x12),
  .main_hurtbox_x2(hurt_x22),
  .main_hurtbox_y1(hurt_y12),
  .main_hurtbox_y2(hurt_y22),
  .dir_hithurtbox_x1(dir_hithurt_x12),
  .dir_hithurtbox_x2(dir_hithurt_x22),
  .dir_hithurtbox_y1(dir_hithurt_y12),
  .dir_hithurtbox_y2(dir_hithurt_y22)
);



HitDetect hitdetector_inst (
  .p1_state(player1_state),
  .p1_basic_hithurtbox_x1(hithurt_x1),
  .p1_basic_hithurtbox_x2(hithurt_x2),
  .p1_basic_hithurtbox_y1(hithurt_y1),
  .p1_basic_hithurtbox_y2(hithurt_y2),
  .p1_main_hurtbox_x1(hurt_x1),
  .p1_main_hurtbox_x2(hurt_x2),
  .p1_main_hurtbox_y1(hurt_y1),
  .p1_main_hurtbox_y2(hurt_y2),
  .p1_dir_hithurtbox_x1(dir_hithurt_x1),
  .p1_dir_hithurtbox_x2(dir_hithurt_x2),
  .p1_dir_hithurtbox_y1(dir_hithurt_y1),
  .p1_dir_hithurtbox_y2(dir_hithurt_y2),

  .p2_state(player2_state),
  .p2_basic_hithurtbox_x1(hithurt_x12),
  .p2_basic_hithurtbox_x2(hithurt_x22),
  .p2_basic_hithurtbox_y1(hithurt_y12),
  .p2_basic_hithurtbox_y2(hithurt_y22),
  .p2_main_hurtbox_x1(hurt_x12),
  .p2_main_hurtbox_x2(hurt_x22),
  .p2_main_hurtbox_y1(hurt_y12),
  .p2_main_hurtbox_y2(hurt_y22),
  .p2_dir_hithurtbox_x1(dir_hithurt_x12),
  .p2_dir_hithurtbox_x2(dir_hithurt_x22),
  .p2_dir_hithurtbox_y1(dir_hithurt_y12),
  .p2_dir_hithurtbox_y2(dir_hithurt_y22),

  .P1_hasBeenHitFlag(hasbeenHit1), // Output flag for Player 1
  .P2_hasBeenHitFlag(hasbeenHit2) // Output flag for Player 2
);


wire [7:0] pixel_data;
rom rom_inst (
  .clk(CLOCK_50),
  .current_pixel_x(current_pixel_x), // Current pixel X position
  .current_pixel_y(current_pixel_y), // Current pixel Y position
  .posx(posx), // Player 1's positions
  .posy(posy),
  .posx2(posx2), // Player 2's positions
  .posy2(posy2),
  .player1_state(player1_state),
  .player2_state(player2_state),
  .player1_health(player1_health),
  .player2_health(player2_health),
  .player1_block(player1_block),
  .player2_block(player2_block),
  .game_state(game_state), // Current game state
  .pixel_data(pixel_data), // Color data for the current pixel
);


color_decider color_decider_inst (
  .current_pixel_x(current_pixel_x), // Current pixel X coordinate
  .current_pixel_y(current_pixel_y), // Current pixel Y coordinate
  .posx(posx), // X position of the sprite
  .posy(posy), // Y position of the sprite
  .posx2(posx2), // X position of the second sprite
  .posy2(posy2), // Y position of the second sprite
  .hithurt_x1(hithurt_x1), // X coordinate of the first corner of the basic hit hurtbox
  .hithurt_x2(hithurt_x2), // X coordinate of the second corner of the basic hit hurtbox
  .hithurt_y1(hithurt_y1), // Y coordinate of the first corner of the basic hit hurtbox
  .hithurt_y2(hithurt_y2), // Y coordinate of the second corner of the basic hit hurtbox
  .hithurt_x12(hithurt_x12), // X coordinate of the first corner of the second basic hit hurtbox
  .hithurt_x22(hithurt_x22), // X coordinate of the second corner of the second basic hit hurtbox
  .hithurt_y12(hithurt_y12), // Y coordinate of the first corner of the second basic hit hurtbox
  .hithurt_y22(hithurt_y22), // Y coordinate of the second corner of the second basic hit hurtbox
  .dir_hithurt_x1(dir_hithurt_x1), // X coordinate of the first corner of the directional hit hurtbox
  .dir_hithurt_x2(dir_hithurt_x2), // X coordinate of the second corner of the directional hit hurtbox
  .dir_hithurt_y1(dir_hithurt_y1), // Y coordinate of the first corner of the directional hit hurtbox
  .dir_hithurt_y2(dir_hithurt_y2), // Y coordinate of the second corner of the directional hit hurtbox
  .dir_hithurt_x12(dir_hithurt_x12), // X coordinate of the first corner of the second directional hit hurtbox
  .dir_hithurt_x22(dir_hithurt_x22), // X coordinate of the second corner of the second directional hit hurtbox
  .dir_hithurt_y12(dir_hithurt_y12), // Y coordinate of the first corner of the second directional hit hurtbox
  .dir_hithurt_y22(dir_hithurt_y22), // Y coordinate of the second corner of the second directional hit hurtbox
  .hurt_x1(hurt_x1), // X coordinate of the first corner of the main hurtbox
  .hurt_x2(hurt_x2), // X coordinate of the second corner of the main hurtbox
  .hurt_y1(hurt_y1), // Y coordinate of the first corner of the main hurtbox
  .hurt_y2(hurt_y2), // Y coordinate of the second corner of the main hurtbox
  .hurt_x12(hurt_x12), // X coordinate of the first corner of the second main hurtbox
  .hurt_x22(hurt_x22), // X coordinate of the second corner of the second main hurtbox
  .hurt_y12(hurt_y12), // Y coordinate of the first corner of the second main hurtbox
  .hurt_y22(hurt_y22), // Y coordinate of the second corner of the second main hurtbox
  .player1_state(player1_state), // Current state of the sprite
  .player2_state(player2_state), // Current state of the second sprite
  .pixel_data(pixel_data), // Pixel data for the sprite
  .color_to_vga_driver(color_to_vga_driver) // Color to be sent to the VGA driver
);

LEDhandler leds_inst(
	.game_state(game_state),
	.clk(CLOCK_50),
	.p1_health(player1_health),
	.p2_health(player2_health),
	.LEDvalues(LEDR)
);

game game_inst (
  .clk(effective_clk), // 60 Hz clock
  .reset(1'b0), // Reset signal
  .KEY(KEY), // Key inputs
  .HEX0(HEX0), // Seven-segment display outputs
  .HEX1(HEX1),
  .HEX2(HEX2),
  .HEX3(HEX3),
  .HEX4(HEX4),
  .HEX5(HEX5),
  .SW(SW), // Switch inputs
  .GPIO(GPIO), // GPIO connections
  .player1_state(player1_state), // Player 1's state
  .player2_state(player2_state), // Player 2's state
  .player1_health(player1_health), // Player 1's health
  .player2_health(player2_health), // Player 2's health
  .game_state(game_state), // Game state output
  .game_duration(game_duration) // For countdown and hex display
);

endmodule
