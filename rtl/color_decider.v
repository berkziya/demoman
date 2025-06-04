module color_decider(
	input [9:0] current_pixel_x,
	input [9:0] current_pixel_y,
	input [9:0] posx,
	input [9:0] posy,
	input [9:0] posx2,
	input [9:0] posy2,
	input [9:0] sprite_width,
	input [9:0] sprite_height,
	input [9:0] hithurt_x1,
	input [9:0] hithurt_x2,
	input [9:0] hithurt_y1,
	input [9:0] hithurt_y2,
	input [9:0] hithurt_x12,
	input [9:0] hithurt_x22,
	input [9:0] hithurt_y12,
	input [9:0] hithurt_y22,
	input [9:0] dir_hithurt_x1,
	input [9:0] dir_hithurt_x2,
	input [9:0] dir_hithurt_y1,
	input [9:0] dir_hithurt_y2,
	input [9:0] dir_hithurt_x12,
	input [9:0] dir_hithurt_x22,
	input [9:0] dir_hithurt_y12,
	input [9:0] dir_hithurt_y22,
	input [9:0] hurt_x1,
	input [9:0] hurt_x2,
	input [9:0] hurt_y1,
	input [9:0] hurt_y2,
	input [9:0] hurt_x12,
	input [9:0] hurt_x22,
	input [9:0] hurt_y12,
	input [9:0] hurt_y22,
	input [3:0] currentstate,
	input [3:0] currentstate2,
	input [7:0] pixel_data,
	input pixel_visible_flag,
	output reg [7:0] color_to_vga_driver
);
localparam [7:0] TRANSPARENT_COLOR = 8'b11100011; // Transparent color for the sprite
wire inside_sprite; // Flag indicating if the current pixel is inside the sprite
wire on_hithurt_border; // Flag indicating if the current pixel is on the basic hit hurtbox border
wire on_hurt_border; // Flag indicating if the current pixel is on the main hurtbox border

assign inside_sprite = (current_pixel_x >= posx && current_pixel_x < posx + sprite_width &&
                        current_pixel_y >= posy && current_pixel_y < posy + sprite_height);
assign inside_sprite2 = (current_pixel_x >= posx2 && current_pixel_x < posx2 + sprite_width &&
						current_pixel_y >= posy2 && current_pixel_y < posy2 + sprite_height);
assign on_hithurt_border = (((current_pixel_x == hithurt_x1 || current_pixel_x == hithurt_x2) &&
                             (current_pixel_y >= hithurt_y1 && current_pixel_y <= hithurt_y2)) ||
                            ((current_pixel_y == hithurt_y1 || current_pixel_y == hithurt_y2) &&
                             (current_pixel_x >= hithurt_x1 && current_pixel_x <= hithurt_x2)));
assign on_hithurt_border2 = (((current_pixel_x == hithurt_x12 || current_pixel_x == hithurt_x22) &&
							 (current_pixel_y >= hithurt_y12 && current_pixel_y <= hithurt_y22)) ||
							((current_pixel_y == hithurt_y12 || current_pixel_y == hithurt_y22) &&
							 (current_pixel_x >= hithurt_x12 && current_pixel_x <= hithurt_x22)));
assign on_hurt_border =  (((current_pixel_x == hurt_x1 || current_pixel_x == hurt_x2) &&
                          (current_pixel_y >= hurt_y1 && current_pixel_y <= hurt_y2)) ||
                         ((current_pixel_y == hurt_y1 || current_pixel_y == hurt_y2) &&
                          (current_pixel_x >= hurt_x1 && current_pixel_x <= hurt_x2)));
assign on_hurt_border2 =  (((current_pixel_x == hurt_x12 || current_pixel_x == hurt_x22) &&
						   (current_pixel_y >= hurt_y12 && current_pixel_y <= hurt_y22)) ||
						  ((current_pixel_y == hurt_y12 || current_pixel_y == hurt_y22) &&
						   (current_pixel_x >= hurt_x12 && current_pixel_x <= hurt_x22)));
assign on_dir_hithurt_border = (((current_pixel_x == dir_hithurt_x1 || current_pixel_x == dir_hithurt_x2) &&
							 (current_pixel_y >= dir_hithurt_y1 && current_pixel_y <= dir_hithurt_y2)) ||
							((current_pixel_y == dir_hithurt_y1 || current_pixel_y == dir_hithurt_y2) &&
							 (current_pixel_x >= dir_hithurt_x1 && current_pixel_x <= dir_hithurt_x2)));
assign on_dir_hithurt_border2 = (((current_pixel_x == dir_hithurt_x12 || current_pixel_x == dir_hithurt_x22) &&
								  (current_pixel_y >= dir_hithurt_y12 && current_pixel_y <= dir_hithurt_y22)) ||
								 ((current_pixel_y == dir_hithurt_y12 || current_pixel_y == dir_hithurt_y22) &&
								  (current_pixel_x >= dir_hithurt_x12 && current_pixel_x <= dir_hithurt_x22)));


always @(*) begin
	if (((currentstate == 4'd4) && (on_hithurt_border)) || ((currentstate2 == 4'd4) && (on_hithurt_border2))) begin // If the current state is attack end and on the basic hit hurtbox border
		color_to_vga_driver = 8'b11100000; // Red color for basic hit hurtbox border
	end else if (((currentstate == 4'd5) && (on_hithurt_border)) || ((currentstate2 == 4'd5) && (on_hithurt_border2))) begin // If the current state is attack pull and on the basic hit hurtbox border
		color_to_vga_driver = 8'b11111100; // Yellow color for basic hit hurtbox border
	end else if (((currentstate == 4'd7) && (on_dir_hithurt_border)) || ((currentstate2 == 4'd7) && (on_dir_hithurt_border2))) begin // If the current state is directional attack end and on the directional hit hurtbox border
		color_to_vga_driver = 8'b11100000; // Red color for directional hit hurtbox border
	end else if (((currentstate == 4'd8) && (on_dir_hithurt_border)) || ((currentstate2 == 4'd8) && (on_dir_hithurt_border2))) begin // If the current state is attack pull and on the basic hit hurtbox border
		color_to_vga_driver = 8'b11111100; // Yellow color for basic hit hurtbox border
	end else if ((on_hurt_border) || (on_hurt_border2)) begin // If the current pixel is on the main hurtbox border
		color_to_vga_driver = 8'b11111100; // Yellow color for main hurtbox border
	end else if ((inside_sprite || inside_sprite2) && (pixel_data != TRANSPARENT_COLOR) ) begin // If the current pixel is inside the sprite and visible
		color_to_vga_driver = pixel_data;
	end else begin
		color_to_vga_driver = 8'b01111011; // Default color for background
	end
end
endmodule