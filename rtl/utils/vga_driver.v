module vga_driver (
  input        clock,    // 25 MHz
  input        reset,    // Active high
  input  [7:0] color_in, // Pixel color data (RRRGGGBB)
  output [9:0] next_x,   // x-coordinate of NEXT pixel that will be drawn
  output [9:0] next_y,   // y-coordinate of NEXT pixel that will be drawn
  output       hsync,    // HSYNC (to VGA connector)
  output       vsync,    // VSYNC (to VGA connctor)
  output [7:0] red,      // RED (to resistor DAC VGA connector)
  output [7:0] green,    // GREEN (to resistor DAC to VGA connector)
  output [7:0] blue,     // BLUE (to resistor DAC to VGA connector)
  output       sync,     // SYNC to VGA connector
  output       clk,      // CLK to VGA connector
  output       blank     // BLANK to VGA connector
);
  // Horizontal localparams (measured in clock cycles)
  localparam [9:0] H_ACTIVE = 10'd639;
  localparam [9:0] H_FRONT  = 10'd15;
  localparam [9:0] H_PULSE  = 10'd95;
  localparam [9:0] H_BACK   = 10'd47;

  // Vertical localparams (measured in lines)
  localparam [9:0] V_ACTIVE =  10'd479;
  localparam [9:0] V_FRONT  =  10'd9;
  localparam [9:0] V_PULSE  =  10'd1;
  localparam [9:0] V_BACK   =  10'd32;

  // localparams for readability
  localparam LOW  = 1'b0;
  localparam HIGH = 1'b1;

  // States (more readable)
  localparam [1:0] H_ACTIVE_STATE = 2'd0;
  localparam [1:0] H_FRONT_STATE  = 2'd1;
  localparam [1:0] H_PULSE_STATE  = 2'd2;
  localparam [1:0] H_BACK_STATE   = 2'd3;

  localparam [1:0] V_ACTIVE_STATE = 2'd0;
  localparam [1:0] V_FRONT_STATE  = 2'd1;
  localparam [1:0] V_PULSE_STATE  = 2'd2;
  localparam [1:0] V_BACK_STATE   = 2'd3;

  // Clocked registers
  reg       hysnc_reg;
  reg       vsync_reg;
  reg [7:0] red_reg;
  reg [7:0] green_reg;
  reg [7:0] blue_reg;
  reg       line_done;

  // Control registers
  reg [9:0] h_counter;
  reg [9:0] v_counter;

  reg [1:0] h_state;
  reg [1:0] v_state;

  // State machine
  always @(posedge clock) begin
    // At reset . . .
    if (reset) begin
      // Zero the counters
      h_counter <= 10'd0;
      v_counter <= 10'd0;
      // States to ACTIVE
      h_state   <= H_ACTIVE_STATE;
      v_state   <= V_ACTIVE_STATE;
      // Deassert line done
      line_done <= LOW;
    end else begin
      //////////////////////////////////////////////////////////////////////////
      ///////////////////////// HORIZONTAL /////////////////////////////////////
      //////////////////////////////////////////////////////////////////////////
      if (h_state == H_ACTIVE_STATE) begin
        // Iterate horizontal counter, zero at end of ACTIVE mode
        h_counter <= (h_counter == H_ACTIVE) ? 10'd0 : (h_counter + 10'd1);
        // Set hsync
        hysnc_reg <= HIGH;
        // Deassert line done
        line_done <= LOW;
        // State transition
        h_state <= (h_counter == H_ACTIVE) ? H_FRONT_STATE : H_ACTIVE_STATE;
      end
      if (h_state == H_FRONT_STATE) begin
        // Iterate horizontal counter, zero at end of H_FRONT mode
        h_counter <= (h_counter == H_FRONT) ? 10'd0 : (h_counter + 10'd1);
        // Set hsync
        hysnc_reg <= HIGH;
        // State transition
        h_state <= (h_counter == H_FRONT) ? H_PULSE_STATE : H_FRONT_STATE;
      end
      if (h_state == H_PULSE_STATE) begin
        // Iterate horizontal counter, zero at end of H_PULSE mode
        h_counter <= (h_counter == H_PULSE) ? 10'd0 : (h_counter + 10'd1);
        // Clear hsync
        hysnc_reg <= LOW;
        // State transition
        h_state <= (h_counter == H_PULSE) ? H_BACK_STATE : H_PULSE_STATE;
      end
      if (h_state == H_BACK_STATE) begin
        // Iterate horizontal counter, zero at end of H_BACK mode
        h_counter <= (h_counter == H_BACK) ? 10'd0 : (h_counter + 10'd1);
        // Set hsync
        hysnc_reg <= HIGH;
        // State transition
        h_state <= (h_counter == H_BACK) ? H_ACTIVE_STATE : H_BACK_STATE;
        // Signal line complete at state transition (offset by 1 for synchronous state transition)
        line_done <= (h_counter == (H_BACK - 1'b1)) ? HIGH : LOW;
      end

      //////////////////////////////////////////////////////////////////////////
      ///////////////////////// VERTICAL ///////////////////////////////////////
      //////////////////////////////////////////////////////////////////////////
      if (v_state == V_ACTIVE_STATE) begin
        // increment vertical counter at end of line, zero on state transition
        v_counter <= (line_done == HIGH) ? ((v_counter == V_ACTIVE) ? 10'd0 : (v_counter + 10'd1)) : v_counter;
        // set vsync in active mode
        vsync_reg <= HIGH;
        // state transition - only on end of lines
        v_state <= (line_done == HIGH) ? ((v_counter == V_ACTIVE) ? V_FRONT_STATE : V_ACTIVE_STATE) : V_ACTIVE_STATE;
      end
      if (v_state == V_FRONT_STATE) begin
        // increment vertical counter at end of line, zero on state transition
        v_counter <= (line_done == HIGH) ? ((v_counter == V_FRONT) ? 10'd0 : (v_counter + 10'd1)) : v_counter;
        // set vsync in front porch
        vsync_reg <= HIGH;
        // state transition
        v_state <= (line_done == HIGH) ? ((v_counter == V_FRONT) ? V_PULSE_STATE : V_FRONT_STATE) : V_FRONT_STATE;
      end
      if (v_state == V_PULSE_STATE) begin
        // increment vertical counter at end of line, zero on state transition
        v_counter <= (line_done == HIGH) ? ((v_counter == V_PULSE) ? 10'd0 : (v_counter + 10'd1)) : v_counter;
        // clear vsync in pulse
        vsync_reg <= LOW;
        // state transition
        v_state <= (line_done == HIGH) ? ((v_counter == V_PULSE) ? V_BACK_STATE : V_PULSE_STATE) : V_PULSE_STATE;
      end
      if (v_state == V_BACK_STATE) begin
        // increment vertical counter at end of line, zero on state transition
        v_counter <= (line_done == HIGH) ? ((v_counter == V_BACK) ? 10'd0 : (v_counter + 10'd1)) : v_counter;
        // set vsync in back porch
        vsync_reg <= HIGH;
        // state transition
        v_state <= (line_done == HIGH) ? ((v_counter == V_BACK) ? V_ACTIVE_STATE : V_BACK_STATE) : V_BACK_STATE;
      end

      //////////////////////////////////////////////////////////////////////////
      //////////////////////////////// COLOR OUT ///////////////////////////////
      //////////////////////////////////////////////////////////////////////////
      // Assign colors if in active mode
      red_reg   <= (h_state == H_ACTIVE_STATE) ? ((v_state == V_ACTIVE_STATE) ? {color_in[7:5], 5'd0} : 8'd0) : 8'd0;
      green_reg <= (h_state == H_ACTIVE_STATE) ? ((v_state == V_ACTIVE_STATE) ? {color_in[4:2], 5'd0} : 8'd0) : 8'd0;
      blue_reg  <= (h_state == H_ACTIVE_STATE) ? ((v_state == V_ACTIVE_STATE) ? {color_in[1:0], 6'd0} : 8'd0) : 8'd0;
    end
  end

  // Assign output values - to VGA connector
  assign hsync  = hysnc_reg;
  assign vsync  = vsync_reg;
  assign red    = red_reg;
  assign green  = green_reg;
  assign blue   = blue_reg;
  assign clk    = clock;
  assign sync   = 1'b0;
  assign blank  = (h_state == H_ACTIVE_STATE && v_state == V_ACTIVE_STATE);

  // The x/y coordinates that should be available on the NEXT cycle
  assign next_x = (h_state == H_ACTIVE_STATE) ? h_counter : 10'd0;
  assign next_y = (v_state == V_ACTIVE_STATE) ? v_counter : 10'd0;
endmodule
