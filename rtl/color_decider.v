module color_decider(
	input [9:0] current_pixel_x, // Current pixel X coordinate
	input [9:0] current_pixel_y, // Current pixel Y coordinate
	input [9:0] posx, // X position of the sprite
	input [9:0] posy, // Y position of the sprite
	input [9:0] sprite_width, // Width of the sprite
	input [9:0] sprite_height, // Height of the sprite
	input [9:0] hithurt_x1, // X coordinate of the first corner of the basic hit hurtbox
	input [9:0] hithurt_x2, // X coordinate of the second corner of the basic hit hurtbox
	input [9:0] hithurt_y1, // Y coordinate of the first corner of the basic hit hurtbox
	input [9:0] hithurt_y2, // Y coordinate of the second corner of the basic hit hurtbox
	input [9:0] hurt_x1, // X coordinate of the first corner of the main hurtbox
	input [9:0] hurt_x2, // X coordinate of the second corner of the main hurtbox
	input [9:0] hurt_y1, // Y coordinate of the first corner of the main hurtbox
	input [9:0] hurt_y2, // Y coordinate of the second corner of the main hurtbox
	input [3:0] currentstate, // Current state of the sprite
	input [7:0] pixel_data, // Pixel data for the sprite
	input pixel_visible_flag, // Flag indicating if the pixel is visible
	output reg [7:0] color_to_vga_driver // Color to be sent to the VGA driver
);

wire inside_sprite; // Flag indicating if the current pixel is inside the sprite
wire on_hithurt_border; // Flag indicating if the current pixel is on the basic hit hurtbox border
wire on_hurt_border; // Flag indicating if the current pixel is on the main hurtbox border

assign inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width &&
                        current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
assign on_hithurt_border = (((current_pixel_x == hithurt_x1 || current_pixel_x == hithurt_x2) &&
                             (current_pixel_y >= hithurt_y1 && current_pixel_y <= hithurt_y2)) ||
                            ((current_pixel_y == hithurt_y1 || current_pixel_y == hithurt_y2) &&
                             (current_pixel_x >= hithurt_x1 && current_pixel_x <= hithurt_x2)));
assign on_hurt_border = (((current_pixel_x == hurt_x1 || current_pixel_x == hurt_x2) &&
                          (current_pixel_y >= hurt_y1 && current_pixel_y <= hurt_y2)) ||
                         ((current_pixel_y == hurt_y1 || current_pixel_y == hurt_y2) &&
                          (current_pixel_x >= hurt_x1 && current_pixel_x <= hurt_x2)));

always @(*) begin
	if ((currentstate == 4'd4) && (on_hithurt_border)) begin // If the current state is attack end and on the basic hit hurtbox border
		color_to_vga_driver = 8'b11100000; // Red color for basic hit hurtbox border
	end else if ((currentstate == 4'd5) && (on_hithurt_border)) begin // If the current state is attack pull and on the basic hit hurtbox border
		color_to_vga_driver = 8'b11111100; // Yellow color for basic hit hurtbox border
	end else if (on_hurt_border) begin // If the current pixel is on the main hurtbox border
		color_to_vga_driver = 8'b11111100; // Yellow color for main hurtbox border
	end else if (inside_sprite && pixel_visible_flag) begin // If the current pixel is inside the sprite and visible
		color_to_vga_driver = pixel_data;
	end else begin
		color_to_vga_driver = 8'b01111011; // Default color (purple) for background
	end
end
endmodule