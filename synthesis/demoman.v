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

  /////////// SIM ///////////
  output [9:0] DEBUG_X,
  output [9:0] DEBUG_Y,
  input        reset
);

//=======================================================
//  REG/WIRE declarations
//=======================================================

wire [7:0] color_to_vga_driver; // Input color to VGA driver (RRRGGGBB)
wire [9:0] current_pixel_x;     // X-coordinate from vga_driver
wire [9:0] current_pixel_y;     // Y-coordinate from vga_driver
wire       is_active_display;   // From vga_driver's "blank" output (HIGH for active)
wire       clk_25mhz;

//=======================================================
//  Structural coding
//=======================================================

assign DEBUG_X = current_pixel_x;
assign DEBUG_Y = current_pixel_y;

clock_divider #(
  .DIV(2)
) clk_vga_inst (
  .clk_i(CLOCK_50),
  .rst_i(reset),
  .clk_o(clk_25mhz)
);

// Instantiate the VGA driver
vga_driver vga_inst (
  .clock(clk_25mhz),
  .reset(reset),
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
  .blank(is_active_display)       // Output: High during active display period
);

// Ensure VGA_BLANK_N is correctly driven (active LOW for blanking)
assign VGA_BLANK_N = ~is_active_display;

// LEDR assignment (Example: reflect SW state)
assign LEDR = SW;

// HEX display assignments (Example: show parts of SW and KEY)
assign HEX0 = SW[6:0];
assign HEX1 = {3'b0, KEY[3:0]};
// assign HEX2 = ...; // Undriven
// assign HEX3 = ...; // Undriven
// assign HEX4 = ...; // Undriven
// assign HEX5 = ...; // Undriven
// assign VGA_SYNC_N = ...; // Undriven

// --- Modified Color Logic for Debugging ---
wire [2:0] r_component;
wire [2:0] g_component;
wire [1:0] b_component;

reg [2:0] pattern_r;
reg [2:0] pattern_g;
reg [1:0] pattern_b;

// Changed to synchronous reset for pattern generation
always @(posedge clk_25mhz) begin
    if (reset) begin // Assuming 'reset' is asserted synchronously or for multiple clk_25mhz cycles
        pattern_r <= 3'b000;
        pattern_g <= 3'b000;
        pattern_b <= 2'b00;
    end else begin
        pattern_r <= current_pixel_x[7:5];
        pattern_g <= current_pixel_y[7:5];
        pattern_b <= current_pixel_x[2:1] ^ current_pixel_y[2:1];
    end
end

assign r_component = SW[0] ? 3'b111 : (SW[1] ? SW[4:2] : ( (~KEY[3]) ? 3'b100 : pattern_r ) );
assign g_component = SW[6] ? 3'b111 : (SW[7] ? SW[9:7] : ( (~KEY[2]) ? 3'b010 : pattern_g ) );
assign b_component = (~KEY[1]) ? ( (~KEY[0]) ? 2'b11 : 2'b10) : pattern_b;

assign color_to_vga_driver = {r_component, g_component, b_component};

endmodule
