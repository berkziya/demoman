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

	output reg [7:0] pixel_data
);

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
assign addr = (relative_y * SPRITE_WIDTH) + relative_x; // Calculate address in ROM for first player

wire inside_sprite2 = (current_pixel_x >= posx2 && current_pixel_x < posx2 + SPRITE_WIDTH) &&
											(current_pixel_y >= posy2 && current_pixel_y < posy2 + SPRITE_HEIGHT);
assign addr2 = (relative_y2 * SPRITE_WIDTH) + relative_x2; // Calculate address in ROM for second player

// Instantiate ROM modules for each sprite state
// Each ROM module corresponds to a specific sprite state for each player

rom_attackendG rom_inst_attackendG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_attackendG)
);

rom_attackendR rom_inst_attackendR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_attackendR)
);

rom_attackpullG rom_inst_attackpullG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_attackpullG)
);

rom_attackpullR rom_inst_attackpullR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_attackpullR)
);

rom_attackstartG rom_inst_attackstartG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_attackstartG)
);

rom_attackstartR rom_inst_attackstartR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_attackstartR)
);

rom_blockG rom_inst_blockG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_blockG)
);

rom_blockR rom_inst_blockR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_blockR)
);

rom_dirattendG rom_inst_dirattendG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_dirattendG)
);

rom_dirattendR rom_inst_dirattendR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_dirattendR)
);

rom_dirattpullG rom_inst_dirattpullG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_dirattpullG)
);

rom_dirattpullR rom_inst_dirattpullR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_dirattpullR)
);

rom_dirattstartG rom_inst_dirattstartG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_dirattstartG)
);

rom_dirattstartR rom_inst_dirattstartR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_dirattstartR)
);

rom_gothitG rom_inst_gothitG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_gothitG)
);

rom_gothitR rom_inst_gothitR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_gothitR)
);

rom_idleG rom_inst_idleG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_idleG)
);

rom_idleR rom_inst_idleR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_idleR)
);

rom_walkbackG rom_inst_walkbackG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_walkbackG)
);

rom_walkbackR rom_inst_walkbackR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_walkbackR)
);

rom_walkG rom_inst_walkG (
	.address(addr),
	.clock(clk),
	.q(rom_sprite_walkG)
);

rom_walkR rom_inst_walkR (
	.address(addr2),
	.clock(clk),
	.q(rom_sprite_walkR)
);

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

always @(posedge clk) begin
	if (inside_sprite && addr >= 0 && addr < IMAGE_SIZE && rom_sprite != TRANSPARENT_COLOR) begin
		pixel_data <= rom_sprite;
	end else if (inside_sprite2 && addr2 >= 0 && addr2 < IMAGE_SIZE) begin
		pixel_data <= rom_sprite2;
	end else pixel_data <= TRANSPARENT_COLOR;
end

endmodule
