module rom (
    input clk,
    input rst,
    input [9:0] current_pixel_x, // Current pixel X position
    input [9:0] current_pixel_y, // Current pixel Y position
    input [9:0] posx, // Player's X position
    input [9:0] posy, // Player's Y position
    input [9:0] posx2, // Player's X position for second player
    input [9:0] posy2, // Player's Y position for second player
    input [9:0] sprite_height, // Height of the sprite
    input [9:0] sprite_width, // Width of the sprite
    input [3:0] currentstate,
    input [3:0] currentstate2,
    output reg visible_flag, // Flag to indicate if the sprite is visible
    output reg [7:0] data
);
    // ROM data initialization
    localparam image_size = 150 * 157; // Size of the sprite in pixels
    reg [7:0] rom_sprite, rom_sprite2; // ROM sprite data
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

    localparam [7:0] TRANSPARENT_COLOR = 8'b11100011; // Transparent color value

    wire inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width) &&
                         (current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
    assign addr = (relative_y * 15'd150) + relative_x; // Calculate address in ROM

    wire inside_sprite2 = (current_pixel_x >= posx2 && current_pixel_x < posx2 + sprite_width) &&
                          (current_pixel_y >= posy2 && current_pixel_y < posy2 + sprite_height);
    assign addr2 = (relative_y2 * 15'd150) + relative_x2; // Calculate address in ROM for second player

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
        case (currentstate2)
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
            default: rom_sprite2 = 8'b0111011;
        endcase
        case (currentstate)
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
            default: rom_sprite = 8'b0111011;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 8'b0111011; // Reset output data
            visible_flag <= 1'b0; // Reset visibility flag
        end else begin
            if (inside_sprite && addr > 0 && addr < image_size) begin
                // Ensure the address is within bounds of the ROM
            data <= rom_sprite; // Read data from ROM at the specified address
            visible_flag <= (rom_sprite != TRANSPARENT_COLOR); // Set visibility flag based on color
            end if (inside_sprite2 && addr2 > 0 && addr2 < image_size) begin
            // Ensure the address is within bounds of the ROM for second player
            data <= rom_sprite2; // Read data from ROM at the specified address for second player
            visible_flag <= ((rom_sprite || rom_sprite2) != TRANSPARENT_COLOR); // Set visibility flag based on color
            end
        end else begin
            data <= 8'b0111011; // Default value if outside sprite bounds or address out of range
            visible_flag <= 1'b0; // Not visible if outside sprite bounds
        end
    end
    
/*
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data = 8'b0111011; // Reset output data
            visible_flag = 1'b0; // Reset visibility flag
        end else if (inside_sprite2 && addr2 > 0 && addr2 < image_size) begin
                // Ensure the address is within bounds of the ROM
            data = rom_sprite2; // Read data from ROM at the specified address
            visible_flag = (rom_sprite2 != TRANSPARENT_COLOR); // Set visibility flag based on color
        end if (((inside_sprite && addr > 0) && (addr < image_size)) && (~visible_flag)) begin
            // Ensure the address is within bounds of the ROM for second player
            data = rom_sprite; // Read data from ROM at the specified address for second player
            visible_flag = (rom_sprite != TRANSPARENT_COLOR); // Set visibility flag based on color
        end else begin
            data = 8'b0111011; // Default value if outside sprite bounds or address out of range
            visible_flag = 1'b0; // Not visible if outside sprite bounds
        end
    end
	 */

endmodule
