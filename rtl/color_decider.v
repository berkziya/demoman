module color_decider(
  input [9:0] current_pixel_x,
  input [9:0] current_pixel_y,
  input [9:0] posx,
  input [9:0] posy,
  input [9:0] posx2,
  input [9:0] posy2,
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
  input [3:0] player1_state,
  input [3:0] player2_state,
  input [7:0] pixel_data,
  output reg [7:0] color_to_vga_driver
);
localparam [7:0] TRANSPARENT_COLOR = 8'b11100011;
localparam [7:0] BACKGROUND_COLOR = 8'b01111011;

wire on_hithurt_border; // Flag indicating if the current pixel is on the basic hit hurtbox border
wire on_hurt_border; // Flag indicating if the current pixel is on the main hurtbox border

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
	if (((player1_state == 4'd4) && (on_hithurt_border)) ||
      ((player2_state == 4'd4) && (on_hithurt_border2))) begin
		color_to_vga_driver = 8'b11100000; // Red color for active hithurtbox border
	end else if (((player1_state == 4'd5) && (on_hithurt_border)) ||
               ((player2_state == 4'd5) && (on_hithurt_border2))) begin
		color_to_vga_driver = 8'b11111100; // Yellow color for passive hithurtbox border
	end else if (((player1_state == 4'd7) && (on_dir_hithurt_border)) ||
               ((player2_state == 4'd7) && (on_dir_hithurt_border2))) begin
		color_to_vga_driver = 8'b11100000; // Red color for active directional hithurtbox border
	end else if (((player1_state == 4'd8) && (on_dir_hithurt_border)) ||
               ((player2_state == 4'd8) && (on_dir_hithurt_border2))) begin
		color_to_vga_driver = 8'b11111100; // Yellow color for passive directional hithurtbox border
	end else if ((on_hurt_border) || (on_hurt_border2)) begin
		color_to_vga_driver = 8'b11111100; // Yellow color for main hurtbox border
	end else if ((pixel_data != TRANSPARENT_COLOR)) begin
		color_to_vga_driver = pixel_data;
	end else begin
		color_to_vga_driver = BACKGROUND_COLOR; // Default color for background
	end
end
endmodule