module counter #(parameter W=4)(
	input clk,
	input rst,
  input [1:0] control, //control
  output reg [W-1:0] count //counter value
);
	localparam stateHold = 2'b00,
             stateReset = 2'b11,
             stateIncrement = 2'b01,
             stateDecrement = 2'b10;
				 
	always @(rst)
		count = {W{1'b0}};

	always @(posedge clk) begin
		if (rst)
			count <= {W{1'b0}};
		else
			case(control)
				stateHold: begin //hold current counter value
					end
				stateIncrement: //increment counter
					count <= count + 1;
				stateDecrement: //decrement Counter
					count <= count - 1;
				stateReset: //reset Counter
					count <= {W{1'b0}};
			endcase
	end
endmodule
