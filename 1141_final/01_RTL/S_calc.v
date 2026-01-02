// Syndrome calculator modules
module S1_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;
	
	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// code = 1: (63, 51), code = 2: (255, 239), code = 3: (1023, 983)
		case (code)
			1: begin
				syndrome_mul_alpha_8[5] = syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[4] = syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[3] = syndrome_in[5] ^ syndrome_in[1];
				syndrome_mul_alpha_8[2] = syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[4] ^ syndrome_in[3];
				syndrome_mul_alpha_8[0] = syndrome_in[3] ^ syndrome_in[2];

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 6'b011000 : 6'b0) ^ ((r_data[6]) ? 6'b110000 : 6'b0) ^ ((r_data[5]) ? 6'b000001 : 6'b0)
													^ ((r_data[4]) ? 6'b000010 : 6'b0) ^ ((r_data[3]) ? 6'b000100 : 6'b0) ^ ((r_data[2]) ? 6'b001000 : 6'b0)
													^ ((r_data[1]) ? 6'b010000 : 6'b0) ^ ((r_data[0]) ? 6'b100000 : 6'b0);
			end
			2: begin
				syndrome_mul_alpha_8[7] = syndrome_in[7] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[6] = syndrome_in[6] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[5] = syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[4] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[3];
				syndrome_mul_alpha_8[3] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[1];
				syndrome_mul_alpha_8[2] = syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3];
				syndrome_mul_alpha_8[0] = syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2];

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 8'b00000001 : 8'b0) ^ ((r_data[6]) ? 8'b00000010 : 8'b0) ^ ((r_data[5]) ? 8'b00000100 : 8'b0)
													^ ((r_data[4]) ? 8'b00001000 : 8'b0) ^ ((r_data[3]) ? 8'b00010000 : 8'b0) ^ ((r_data[2]) ? 8'b00100000 : 8'b0)
													^ ((r_data[1]) ? 8'b01000000 : 8'b0) ^ ((r_data[0]) ? 8'b10000000 : 8'b0);
			end
			3: begin
				syndrome_mul_alpha_8[9] = syndrome_in[7] ^ syndrome_in[0];
				syndrome_mul_alpha_8[8] = syndrome_in[6];
				syndrome_mul_alpha_8[7] = syndrome_in[5];
				syndrome_mul_alpha_8[6] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[0];
				syndrome_mul_alpha_8[5] = syndrome_in[6] ^ syndrome_in[3];
				syndrome_mul_alpha_8[4] = syndrome_in[5] ^ syndrome_in[2];
				syndrome_mul_alpha_8[3] = syndrome_in[4] ^ syndrome_in[1];
				syndrome_mul_alpha_8[2] = syndrome_in[3] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[9] ^ syndrome_in[2];
				syndrome_mul_alpha_8[0] = syndrome_in[8] ^ syndrome_in[1];

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0000000100 : 10'b0) ^ ((r_data[6]) ? 10'b0000001000 : 10'b0) ^ ((r_data[5]) ? 10'b0000010000 : 10'b0)
													^ ((r_data[4]) ? 10'b0000100000 : 10'b0) ^ ((r_data[3]) ? 10'b0001000000 : 10'b0) ^ ((r_data[2]) ? 10'b0010000000 : 10'b0)
													^ ((r_data[1]) ? 10'b0100000000 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
			end
		endcase
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end
endmodule

module S2_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// code = 1: (63, 51), code = 2: (255, 239), code = 3: (1023, 983)
		case (code)
			1: begin
				syndrome_mul_alpha_8[5] = syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[0];
				syndrome_mul_alpha_8[4] = syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[3] = syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[2] = syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[5] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[0] = syndrome_in[4] ^ syndrome_in[1] ^ syndrome_in[0]; 

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 6'b001010 : 6'b0) ^ ((r_data[6]) ? 6'b101000 : 6'b0) ^ ((r_data[5]) ? 6'b000011 : 6'b0)
													^ ((r_data[4]) ? 6'b001100 : 6'b0) ^ ((r_data[3]) ? 6'b110000 : 6'b0) ^ ((r_data[2]) ? 6'b000010 : 6'b0)
													^ ((r_data[1]) ? 6'b001000 : 6'b0) ^ ((r_data[0]) ? 6'b100000 : 6'b0);
			end
			2: begin
				syndrome_mul_alpha_8[7] = syndrome_in[5] ^ syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[6] = syndrome_in[4] ^ syndrome_in[1];
				syndrome_mul_alpha_8[5] = syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2];
				syndrome_mul_alpha_8[4] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[3] = syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2];
				syndrome_mul_alpha_8[2] = syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[1] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[0] = syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];


				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 8'b11001000 : 8'b0) ^ ((r_data[6]) ? 8'b10110011 : 8'b0) ^ ((r_data[5]) ? 8'b00101110 : 8'b0)
													^ ((r_data[4]) ? 8'b10111000 : 8'b0) ^ ((r_data[3]) ? 8'b00000010 : 8'b0) ^ ((r_data[2]) ? 8'b00001000 : 8'b0)
													^ ((r_data[1]) ? 8'b00100000 : 8'b0) ^ ((r_data[0]) ? 8'b10000000 : 8'b0);
			end
			3: begin
				syndrome_mul_alpha_8[9] = syndrome_in[8] ^ syndrome_in[5] ^ syndrome_in[1];
				syndrome_mul_alpha_8[8] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[0];
				syndrome_mul_alpha_8[7] = syndrome_in[6] ^ syndrome_in[3];
				syndrome_mul_alpha_8[6] = syndrome_in[8] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[5] = syndrome_in[7] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[4] = syndrome_in[6] ^ syndrome_in[0]; 
				syndrome_mul_alpha_8[3] = syndrome_in[9] ^ syndrome_in[5];
				syndrome_mul_alpha_8[2] = syndrome_in[8] ^ syndrome_in[4];
				syndrome_mul_alpha_8[1] = syndrome_in[7] ^ syndrome_in[3]; 
				syndrome_mul_alpha_8[0] = syndrome_in[9] ^ syndrome_in[6] ^ syndrome_in[2];

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0000100100 : 10'b0) ^ ((r_data[6]) ? 10'b0010010000 : 10'b0) ^ ((r_data[5]) ? 10'b1001000000 : 10'b0)
													^ ((r_data[4]) ? 10'b0000000010 : 10'b0) ^ ((r_data[3]) ? 10'b0000001000 : 10'b0) ^ ((r_data[2]) ? 10'b0000100000 : 10'b0)
													^ ((r_data[1]) ? 10'b0010000000 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
			end
		endcase
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end

endmodule

module S3_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// code = 1: (63, 51), code = 2: (255, 239), code = 3: (1023, 983)
		case (code)
			1: begin
				syndrome_mul_alpha_8[5] = syndrome_in[5] ^ syndrome_in[3];
				syndrome_mul_alpha_8[4] = syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2];
				syndrome_mul_alpha_8[3] = syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[2] = syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[5] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[0] = syndrome_in[4] ^ syndrome_in[0]; 

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 6'b110111 : 6'b0) ^ ((r_data[6]) ? 6'b111100 : 6'b0) ^ ((r_data[5]) ? 6'b000101 : 6'b0)
													^ ((r_data[4]) ? 6'b101000 : 6'b0) ^ ((r_data[3]) ? 6'b000110 : 6'b0) ^ ((r_data[2]) ? 6'b110000 : 6'b0)
													^ ((r_data[1]) ? 6'b000100 : 6'b0) ^ ((r_data[0]) ? 6'b100000 : 6'b0);
			end
			2: begin
				syndrome_mul_alpha_8[7] = syndrome_in[7] ^ syndrome_in[6];
				syndrome_mul_alpha_8[6] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5];
				syndrome_mul_alpha_8[5] = syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[4];
				syndrome_mul_alpha_8[4] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[3];
				syndrome_mul_alpha_8[3] = syndrome_in[3] ^ syndrome_in[2];
				syndrome_mul_alpha_8[2] = syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[1] = syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[0] = syndrome_in[7] ^ syndrome_in[0];


				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 8'b10101110 : 8'b0) ^ ((r_data[6]) ? 8'b10110100 : 8'b0) ^ ((r_data[5]) ? 8'b01100100 : 8'b0)
													^ ((r_data[4]) ? 8'b10110011 : 8'b0) ^ ((r_data[3]) ? 8'b01011100 : 8'b0) ^ ((r_data[2]) ? 8'b00000010 : 8'b0)
													^ ((r_data[1]) ? 8'b00010000 : 8'b0) ^ ((r_data[0]) ? 8'b10000000 : 8'b0);
			end
			3: begin
				syndrome_mul_alpha_8[9] = syndrome_in[9] ^ syndrome_in[3] ^ syndrome_in[2];
				syndrome_mul_alpha_8[8] = syndrome_in[8] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[7] = syndrome_in[7] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[6] = syndrome_in[9] ^ syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[5] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[5] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[4] = syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[3] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[0];
				syndrome_mul_alpha_8[2] = syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[2];
				syndrome_mul_alpha_8[1] = syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[1];
				syndrome_mul_alpha_8[0] = syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[0];

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0100000100 : 10'b0) ^ ((r_data[6]) ? 10'b0100100010 : 10'b0) ^ ((r_data[5]) ? 10'b0000010010 : 10'b0)
													^ ((r_data[4]) ? 10'b0010010000 : 10'b0) ^ ((r_data[3]) ? 10'b0000000001 : 10'b0) ^ ((r_data[2]) ? 10'b0000001000 : 10'b0)
													^ ((r_data[1]) ? 10'b0001000000 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
			end
		endcase
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end

endmodule

module S4_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// code = 1: (63, 51), code = 2: (255, 239), code = 3: (1023, 983)
		case (code)
			1: begin
				syndrome_mul_alpha_8[5] = syndrome_in[5] ^ syndrome_in[2];
				syndrome_mul_alpha_8[4] = syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[3] = syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[2] = syndrome_in[5] ^ syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[4] ^ syndrome_in[1];
				syndrome_mul_alpha_8[0] = syndrome_in[3] ^ syndrome_in[0]; 

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 6'b001110 : 6'b0) ^ ((r_data[6]) ? 6'b100010 : 6'b0) ^ ((r_data[5]) ? 6'b001111 : 6'b0)
													^ ((r_data[4]) ? 6'b110010 : 6'b0) ^ ((r_data[3]) ? 6'b101000 : 6'b0) ^ ((r_data[2]) ? 6'b001100 : 6'b0)
													^ ((r_data[1]) ? 6'b000010 : 6'b0) ^ ((r_data[0]) ? 6'b100000 : 6'b0);
			end
			2: begin
				syndrome_mul_alpha_8[7] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[0];
				syndrome_mul_alpha_8[6] = syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[2];
				syndrome_mul_alpha_8[5] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[4] = syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2];
				syndrome_mul_alpha_8[3] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[1] ^ syndrome_in[0];
				syndrome_mul_alpha_8[2] = syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[0];
				syndrome_mul_alpha_8[1] = syndrome_in[5] ^ syndrome_in[2];
				syndrome_mul_alpha_8[0] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[1]; 


				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 8'b00011000 : 8'b0) ^ ((r_data[6]) ? 8'b11110001 : 8'b0) ^ ((r_data[5]) ? 8'b00101101 : 8'b0)
													^ ((r_data[4]) ? 8'b00110010 : 8'b0) ^ ((r_data[3]) ? 8'b10110011 : 8'b0) ^ ((r_data[2]) ? 8'b10111000 : 8'b0)
													^ ((r_data[1]) ? 8'b00001000 : 8'b0) ^ ((r_data[0]) ? 8'b10000000 : 8'b0);
			end
			3: begin
				syndrome_mul_alpha_8[9] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1];
				syndrome_mul_alpha_8[8] = syndrome_in[9] ^ syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
				syndrome_mul_alpha_8[7] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[5] ^ syndrome_in[2] ^ syndrome_in[1];
				syndrome_mul_alpha_8[6] = syndrome_in[8] ^ syndrome_in[3] ^ syndrome_in[0];
				syndrome_mul_alpha_8[5] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[2];
				syndrome_mul_alpha_8[4] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[1];
				syndrome_mul_alpha_8[3] = syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[0];
				syndrome_mul_alpha_8[2] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4];
				syndrome_mul_alpha_8[1] = syndrome_in[9] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[3];
				syndrome_mul_alpha_8[0] = syndrome_in[8] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2];

				syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0000100110 : 10'b0) ^ ((r_data[6]) ? 10'b1001100000 : 10'b0) ^ ((r_data[5]) ? 10'b1000001000 : 10'b0)
													^ ((r_data[4]) ? 10'b0000001001 : 10'b0) ^ ((r_data[3]) ? 10'b0010010000 : 10'b0) ^ ((r_data[2]) ? 10'b0000000010 : 10'b0)
													^ ((r_data[1]) ? 10'b0000100000 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
			end
		endcase
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end

endmodule

module S5_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// only compute in code = 3: (1023, 983)
		if (code == 3) begin
			syndrome_mul_alpha_8[9] = syndrome_in[9] ^ syndrome_in[4] ^ syndrome_in[1];
			syndrome_mul_alpha_8[8] = syndrome_in[8] ^ syndrome_in[3] ^ syndrome_in[0];
			syndrome_mul_alpha_8[7] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[2];
			syndrome_mul_alpha_8[6] = syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[4];
			syndrome_mul_alpha_8[5] = syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[3];
			syndrome_mul_alpha_8[4] = syndrome_in[9] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[2];
			syndrome_mul_alpha_8[3] = syndrome_in[8] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[1];
			syndrome_mul_alpha_8[2] = syndrome_in[7] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[1] = syndrome_in[6] ^ syndrome_in[3] ^ syndrome_in[1];
			syndrome_mul_alpha_8[0] = syndrome_in[5] ^ syndrome_in[2] ^ syndrome_in[0];

			syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0100010110 : 10'b0) ^ ((r_data[6]) ? 10'b1001001001 : 10'b0) ^ ((r_data[5]) ? 10'b0100110000 : 10'b0)
												^ ((r_data[4]) ? 10'b1000001000 : 10'b0) ^ ((r_data[3]) ? 10'b0000010010 : 10'b0) ^ ((r_data[2]) ? 10'b1001000000 : 10'b0)
												^ ((r_data[1]) ? 10'b0000010000 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
		end
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end

endmodule

module S6_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// only compute in code = 3: (1023, 983)
		if (code == 3) begin
			syndrome_mul_alpha_8[9] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[0];
			syndrome_mul_alpha_8[8] = syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[4];
			syndrome_mul_alpha_8[7] = syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[3];
			syndrome_mul_alpha_8[6] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[5] = syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1];
			syndrome_mul_alpha_8[4] = syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[3] = syndrome_in[9] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1];
			syndrome_mul_alpha_8[2] = syndrome_in[8] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
			syndrome_mul_alpha_8[1] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];
			syndrome_mul_alpha_8[0] = syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[1] ^ syndrome_in[0];

			syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0010100100 : 10'b0) ^ ((r_data[6]) ? 10'b0010001011 : 10'b0) ^ ((r_data[5]) ? 10'b1001001001 : 10'b0)
												^ ((r_data[4]) ? 10'b1001100000 : 10'b0) ^ ((r_data[3]) ? 10'b0100100010 : 10'b0) ^ ((r_data[2]) ? 10'b0010010000 : 10'b0)
												^ ((r_data[1]) ? 10'b0000001000 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
		end
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end

endmodule

module S7_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// only compute in code = 3: (1023, 983)
		if (code == 3) begin
			syndrome_mul_alpha_8[9] = syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];
			syndrome_mul_alpha_8[8] = syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[7] = syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1];
			syndrome_mul_alpha_8[6] = syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1];
			syndrome_mul_alpha_8[5] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];
			syndrome_mul_alpha_8[4] = syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[3] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1];
			syndrome_mul_alpha_8[2] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[1] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[1];
			syndrome_mul_alpha_8[0] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1] ^ syndrome_in[0];

			syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0100000101 : 10'b0) ^ ((r_data[6]) ? 10'b0010100100 : 10'b0) ^ ((r_data[5]) ? 10'b0100010110 : 10'b0)
												^ ((r_data[4]) ? 10'b0000100110 : 10'b0) ^ ((r_data[3]) ? 10'b0100000100 : 10'b0) ^ ((r_data[2]) ? 10'b0000100100 : 10'b0)
												^ ((r_data[1]) ? 10'b0000000100 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
		end
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end

endmodule

module S8_calc(
	input clk,
	input rstn,
	input [7:0] r_data,
	input syndrome_calc_start,
	input [1:0] code,
	output reg [9:0] syndrome_out
);
	reg [9:0] syndrome_in;
	reg [9:0] syndrome_mul_alpha_8;
	integer i;

	// Compute S of each cycle
	always @(*) begin
		for (i = 0; i < 10; i = i + 1)
			syndrome_mul_alpha_8[i] = 0;
		syndrome_out = 0;

		// only compute in code = 3: (1023, 983)
		if (code == 3) begin
			syndrome_mul_alpha_8[9] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[8] = syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1];
			syndrome_mul_alpha_8[7] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];
			syndrome_mul_alpha_8[6] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[3];
			syndrome_mul_alpha_8[5] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2];
			syndrome_mul_alpha_8[4] = syndrome_in[8] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1];
			syndrome_mul_alpha_8[3] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];
			syndrome_mul_alpha_8[2] = syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[5] ^ syndrome_in[3] ^ syndrome_in[2] ^ syndrome_in[0];
			syndrome_mul_alpha_8[1] = syndrome_in[9] ^ syndrome_in[7] ^ syndrome_in[5] ^ syndrome_in[4] ^ syndrome_in[2] ^ syndrome_in[1];
			syndrome_mul_alpha_8[0] = syndrome_in[9] ^ syndrome_in[8] ^ syndrome_in[6] ^ syndrome_in[4] ^ syndrome_in[3] ^ syndrome_in[1] ^ syndrome_in[0];

			syndrome_out = syndrome_mul_alpha_8 ^ ((r_data[7]) ? 10'b0000101111 : 10'b0) ^ ((r_data[6]) ? 10'b1000001010 : 10'b0) ^ ((r_data[5]) ? 10'b1010010000 : 10'b0)
												^ ((r_data[4]) ? 10'b0110110010 : 10'b0) ^ ((r_data[3]) ? 10'b1001100000 : 10'b0) ^ ((r_data[2]) ? 10'b0000001001 : 10'b0)
												^ ((r_data[1]) ? 10'b0000000010 : 10'b0) ^ ((r_data[0]) ? 10'b1000000000 : 10'b0);
		end
	end

	// Update syndrome_in
	always @(posedge clk) begin
		if (!rstn) 
			syndrome_in <= 0;
		else if (syndrome_calc_start) 
			syndrome_in <= 0;
		else 
			syndrome_in <= syndrome_out;
	end
	
endmodule