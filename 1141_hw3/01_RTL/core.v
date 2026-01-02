module core (                       //Don't modify interface
	input      		i_clk,
	input      		i_rst_n,
	input    	  	i_in_valid,
	input 	[31: 0] i_in_data, // 4 pixels per cycle

	output			o_in_ready,

	output	[ 7: 0]	o_out_data1,
	output	[ 7: 0]	o_out_data2,
	output	[ 7: 0]	o_out_data3,
	output	[ 7: 0]	o_out_data4,

	output	[11: 0] o_out_addr1,
	output	[11: 0] o_out_addr2,
	output	[11: 0] o_out_addr3,
	output	[11: 0] o_out_addr4,

	output 			o_out_valid1,
	output 			o_out_valid2,
	output 			o_out_valid3,
	output 			o_out_valid4,

	output 			o_exe_finish
);

localparam IDLE = 3'd0, LOAD_IMG = 3'd1, DECODE = 3'd2, LOAD_WEIGHT = 3'd3, CONV = 3'd4, DONE = 3'd5;
reg [2:0] state, next_state;
reg [31:0] i_in_data_r;

// SRAM interface
reg [8:0] sram_addr; // 9 bits, 0~511 for 8 SRAMs
wire sram_wen [0:1];  // sram_wen[0] for sram_0~3, sram_wen[1] for sram_4~7
reg [9:0] input_cycle_cnt; // 10 bits, 0~1023
reg [7:0] sram_out_data [0:7];  // SRAM output wires

assign sram_wen[0] = (state == LOAD_IMG && input_cycle_cnt[0] == 1'b0) ? 1'b0 : 1'b1; // input_cycle_cnt is even
assign sram_wen[1] = (state == LOAD_IMG && input_cycle_cnt[0] == 1'b1) ? 1'b0 : 1'b1; // input_cycle_cnt is odd

assign o_in_ready = (state == IDLE) || (state == LOAD_IMG) || (state == LOAD_WEIGHT);

// -----------------------------------------------------------------------------
// Decode barcode
// -----------------------------------------------------------------------------
// patterns of (K,S,D) = (3,1,1), (3,1,2), (3,2,1), (3,2,2)
localparam [56:0] PATTERN_K3S1D1 = 57'b11010011100_10010011000_11001101100_11001101100_1100011101011;
localparam [56:0] PATTERN_K3S1D2 = 57'b11010011100_10010011000_11001101100_11001100110_1100011101011;
localparam [56:0] PATTERN_K3S2D1 = 57'b11010011100_10010011000_11001100110_11001101100_1100011101011;
localparam [56:0] PATTERN_K3S2D2 = 57'b11010011100_10010011000_11001100110_11001100110_1100011101011;

reg [63:0] row_bits_r, row_bits_w;
reg [2:0] row_bits_idx_r, row_bits_idx_w; 
// reg first_pattern_match_flag_r, first_pattern_match_flag_w;
reg [56:0] candidate;
reg [3:0]  barcode_found_cnt;
reg        row_has_match;
reg [12:0] pixel_cnt;
reg [3:0] tmp;
reg decode_last_flag;

integer i, j, k;

reg [1:0] K_param, S_param, D_param;

reg o_out_valid1_r, o_out_valid2_r, o_out_valid3_r;
reg [7:0] o_out_data1_r, o_out_data2_r, o_out_data3_r;
reg [7:0] o_out_data1_w, o_out_data2_w, o_out_data3_w;

assign o_out_valid1 = o_out_valid1_r;
assign o_out_valid2 = o_out_valid2_r;
assign o_out_valid3 = o_out_valid3_r;
assign o_out_data1  = o_out_data1_r;
assign o_out_data2  = o_out_data2_r;
assign o_out_data3  = o_out_data3_r;

assign o_exe_finish = (state == DONE);

// -----------------------------------------------------------------------------
// Convolution
// -----------------------------------------------------------------------------
reg signed [7:0] weight_r [0:2][0:2]; // 3x3 weight matrix, each is 8 bits signed fixed point number represented by 2’s complement
reg [7:0] row_buf0 [0:63], row_buf1 [0:63], row_buf2 [0:63], row_buf3 [0:63]; // row_data (64 bits)
reg [7:0] new_row_buf_r [0:5], new_row_buf_w [0:5]; // new_row_buf (6 bytes) for D_param = 1
reg [7:0] new_row_buf_D2_r [0:7], new_row_buf_D2_w [0:7]; // new_row_buf (8 bytes) for D_param = 2
reg [12:0] conv_pixel_cnt;
reg [6:0] first_row_buf_cnt;
reg [12:0] conv_res_cnt_S1; // count the number of convolution results generated for S_param = 1, total 4096 results
reg [10:0] conv_res_cnt_S2; // count the number of convolution results generated for S_param = 2, total 1024 results
reg addr_add_flag;
reg row_end_flag;
reg [5:0] row_buf_idx;
reg [7:0] row_buf0_pixel [0:5], row_buf1_pixel [0:5];
reg [7:0] row_buf0_pixel_D2 [0:7], row_buf2_pixel_D2 [0:7];

reg o_out_valid4_r;
reg [7:0] o_out_data4_r, o_out_data4_w;
reg [11:0] o_out_addr1_r, o_out_addr2_r, o_out_addr3_r, o_out_addr4_r;
reg [11:0] o_out_addr1_w, o_out_addr2_w, o_out_addr3_w, o_out_addr4_w;

assign o_out_valid4 = o_out_valid4_r;
assign o_out_data4 = o_out_data4_r;
assign o_out_addr1 = o_out_addr1_r;
assign o_out_addr2 = o_out_addr2_r;
assign o_out_addr3 = o_out_addr3_r;
assign o_out_addr4 = o_out_addr4_r;

reg [7:0] conv_input_0 [0:2][0:2];
reg [7:0] conv_input_1 [0:2][0:2];
reg [7:0] conv_input_2 [0:2][0:2];
reg [7:0] conv_input_3 [0:2][0:2];
reg [7:0] conv_out [0:3];
reg conv_start_flag;
reg conv_valid_in;
reg [3:0] conv_valid_out;
wire conv_addr0_flag;

assign conv_addr0_flag = (S_param == 2'd1 && D_param == 2'd1 && conv_res_cnt_S1 == 3) ||
						 (S_param == 2'd2 && D_param == 2'd1 && conv_res_cnt_S2 == 2) ||
						 (S_param == 2'd1 && D_param == 2'd2 && conv_res_cnt_S1 == 2) ||
						 (S_param == 2'd2 && D_param == 2'd2 && conv_res_cnt_S2 == 1);

conv3x3_pipe u_conv0(.clk(i_clk), .rst_n(i_rst_n), .valid_in(conv_valid_in), .weight(weight_r), 
	.p00(conv_input_0[0][0]), .p01(conv_input_0[0][1]), .p02(conv_input_0[0][2]),
    .p10(conv_input_0[1][0]), .p11(conv_input_0[1][1]), .p12(conv_input_0[1][2]),
    .p20(conv_input_0[2][0]), .p21(conv_input_0[2][1]), .p22(conv_input_0[2][2]),
    .conv_out(o_out_data1_w), .valid_out(conv_valid_out[3]));

conv3x3_pipe u_conv1(.clk(i_clk), .rst_n(i_rst_n), .valid_in(conv_valid_in), .weight(weight_r), 
	.p00(conv_input_1[0][0]), .p01(conv_input_1[0][1]), .p02(conv_input_1[0][2]),
    .p10(conv_input_1[1][0]), .p11(conv_input_1[1][1]), .p12(conv_input_1[1][2]),
    .p20(conv_input_1[2][0]), .p21(conv_input_1[2][1]), .p22(conv_input_1[2][2]),
    .conv_out(o_out_data2_w), .valid_out(conv_valid_out[2]));

conv3x3_pipe u_conv2(.clk(i_clk), .rst_n(i_rst_n), .valid_in(conv_valid_in), .weight(weight_r), 
	.p00(conv_input_2[0][0]), .p01(conv_input_2[0][1]), .p02(conv_input_2[0][2]),
    .p10(conv_input_2[1][0]), .p11(conv_input_2[1][1]), .p12(conv_input_2[1][2]),
    .p20(conv_input_2[2][0]), .p21(conv_input_2[2][1]), .p22(conv_input_2[2][2]),
    .conv_out(o_out_data3_w), .valid_out(conv_valid_out[1]));

conv3x3_pipe u_conv3(.clk(i_clk), .rst_n(i_rst_n), .valid_in(conv_valid_in), .weight(weight_r), 
	.p00(conv_input_3[0][0]), .p01(conv_input_3[0][1]), .p02(conv_input_3[0][2]),
    .p10(conv_input_3[1][0]), .p11(conv_input_3[1][1]), .p12(conv_input_3[1][2]),
    .p20(conv_input_3[2][0]), .p21(conv_input_3[2][1]), .p22(conv_input_3[2][2]),
    .conv_out(o_out_data4_w), .valid_out(conv_valid_out[0]));


// SRAM instances
// pixel1 ~ pixel8 stored in sram_0 ~ sram_7 respectively
// SRAM checks CEN, WEN, A, D at posedge of CLK, and outputs Q after some delay (within a cycle)
sram_512x8 sram_0(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[0]), .A(sram_addr), .D(i_in_data_r[31:24]), .Q(sram_out_data[0]));
sram_512x8 sram_1(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[0]), .A(sram_addr), .D(i_in_data_r[23:16]), .Q(sram_out_data[1]));
sram_512x8 sram_2(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[0]), .A(sram_addr), .D(i_in_data_r[15:8]),  .Q(sram_out_data[2]));
sram_512x8 sram_3(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[0]), .A(sram_addr), .D(i_in_data_r[7:0]),  .Q(sram_out_data[3]));
sram_512x8 sram_4(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[1]), .A(sram_addr), .D(i_in_data_r[31:24]), .Q(sram_out_data[4]));
sram_512x8 sram_5(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[1]), .A(sram_addr), .D(i_in_data_r[23:16]), .Q(sram_out_data[5]));
sram_512x8 sram_6(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[1]), .A(sram_addr), .D(i_in_data_r[15:8]),  .Q(sram_out_data[6]));
sram_512x8 sram_7(.CLK(i_clk), .CEN(1'b0), .WEN(sram_wen[1]), .A(sram_addr), .D(i_in_data_r[7:0]),  .Q(sram_out_data[7]));

// Next state logic
always @(*) begin
	case (state)
		IDLE:       
			next_state = i_in_valid ? LOAD_IMG : IDLE;
		LOAD_IMG:   
			next_state = (input_cycle_cnt == 10'd1023) ? DECODE : LOAD_IMG;
		DECODE: begin
			if (o_out_valid1 && o_out_valid2 && o_out_valid3) 
				next_state = (o_out_data1 == 0 && o_out_data2 == 0 && o_out_data3 == 0) ? DONE : LOAD_WEIGHT; // invalid decode configuration => DONE
			else
				next_state = DECODE;
		end
		LOAD_WEIGHT: 
			next_state = (input_cycle_cnt == 10'd3) ? CONV : LOAD_WEIGHT;
		CONV: 
			next_state = (conv_res_cnt_S1 == 4096 && (conv_start_flag)) ? DONE : CONV;
		DONE:       
			next_state = DONE;
		default:    
			next_state = IDLE;
	endcase
end

// LOAD_WEIGHT sequential logic
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i = 0; i < 3; i = i + 1)
            for (j = 0; j < 3; j = j + 1)
                weight_r[i][j] <= 8'd0;
	end
	else if (state == LOAD_WEIGHT) begin
        case (input_cycle_cnt)
            10'd1: begin
                weight_r[0][0] <= i_in_data_r[31:24];
                weight_r[0][1] <= i_in_data_r[23:16];
                weight_r[0][2] <= i_in_data_r[15:8];
                weight_r[1][0] <= i_in_data_r[7:0];
            end
            10'd2: begin
                weight_r[1][1] <= i_in_data_r[31:24];
                weight_r[1][2] <= i_in_data_r[23:16];
                weight_r[2][0] <= i_in_data_r[15:8];
                weight_r[2][1] <= i_in_data_r[7:0];
            end
            10'd3: begin
                weight_r[2][2] <= i_in_data_r[31:24];
            end
        endcase
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        conv_start_flag <= 0;
    else if ((&conv_valid_out) || (D_param == 2'd1 && conv_pixel_cnt == 56) || (D_param == 2'd2 && conv_pixel_cnt == 120))
        conv_start_flag <= 1;
    else
        conv_start_flag <= 0;
end

// -----------------------------------------------------------------------------
// Convolution logic
// -----------------------------------------------------------------------------
always @(*) begin
	if (state == CONV && conv_start_flag) begin
		conv_valid_in = 1;
		case(D_param)
			2'd1: begin
				new_row_buf_D2_w[0] = 0;
				new_row_buf_D2_w[1] = 0;
				new_row_buf_D2_w[2] = 0;
				new_row_buf_D2_w[3] = 0;
				new_row_buf_D2_w[4] = 0;
				new_row_buf_D2_w[5] = 0;
				new_row_buf_D2_w[6] = 0;
				new_row_buf_D2_w[7] = 0;
				
				if (conv_pixel_cnt >= 64) begin // load pixels in row1
					if ((conv_res_cnt_S1 & 6'b111111) == 0) begin // ex: 0, 64, 128, ...
						// For the start of a row, only output 3 convolution results in a cycle
						new_row_buf_w[0] = 8'd0; 
						new_row_buf_w[1] = 8'd0;
						new_row_buf_w[2] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[0]; 
						new_row_buf_w[3] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[1]; 
						new_row_buf_w[4] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[2]; 
						new_row_buf_w[5] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[3]; 

						if (S_param == 2'd1) begin
							// compute and output the first 3 convolution results of the row
							conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = row_buf0[0]; 	  conv_input_0[0][2] = row_buf0[1];
							conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = row_buf1[0]; 	  conv_input_0[1][2] = row_buf1[1];
							conv_input_0[2][0] = new_row_buf_w[1]; conv_input_0[2][1] = new_row_buf_w[2]; conv_input_0[2][2] = new_row_buf_w[3];

							conv_input_1[0][0] = row_buf0[0]; 	   conv_input_1[0][1] = row_buf0[1]; 	  conv_input_1[0][2] = row_buf0[2];
							conv_input_1[1][0] = row_buf1[0]; 	   conv_input_1[1][1] = row_buf1[1]; 	  conv_input_1[1][2] = row_buf1[2];
							conv_input_1[2][0] = new_row_buf_w[2]; conv_input_1[2][1] = new_row_buf_w[3]; conv_input_1[2][2] = new_row_buf_w[4];

							conv_input_2[0][0] = row_buf0[1]; 	   conv_input_2[0][1] = row_buf0[2]; 	  conv_input_2[0][2] = row_buf0[3];
							conv_input_2[1][0] = row_buf1[1]; 	   conv_input_2[1][1] = row_buf1[2]; 	  conv_input_2[1][2] = row_buf1[3];
							conv_input_2[2][0] = new_row_buf_w[3]; conv_input_2[2][1] = new_row_buf_w[4]; conv_input_2[2][2] = new_row_buf_w[5];

							conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
							conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
							conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;

							// o_out_data1_w = convolution(weight_r, 
							// 							8'd0, row_buf0[0], row_buf0[1],
							// 							8'd0, row_buf1[0], row_buf1[1],
							// 							new_row_buf_w[1], new_row_buf_w[2], new_row_buf_w[3]);
							// o_out_data2_w = convolution(weight_r, 
							// 							row_buf0[0], row_buf0[1], row_buf0[2],
							// 							row_buf1[0], row_buf1[1], row_buf1[2],
							// 							new_row_buf_w[2], new_row_buf_w[3], new_row_buf_w[4]);
							// o_out_data3_w = convolution(weight_r, 
							// 							row_buf0[1], row_buf0[2], row_buf0[3],
							// 							row_buf1[1], row_buf1[2], row_buf1[3],
							// 							new_row_buf_w[3], new_row_buf_w[4], new_row_buf_w[5]);
							// o_out_data4_w = 8'd0; // unused
							
							o_out_addr1_w = conv_res_cnt_S1;
							o_out_addr2_w = conv_res_cnt_S1 + 1;
							o_out_addr3_w = conv_res_cnt_S1 + 2;
							o_out_addr4_w = 12'd0; // unused
						end
						else begin // S_param == 2'd2
							if (conv_res_cnt_S1[6:0] >= 64) begin // ex: 64, 192, 320, ...
								// don't compute and output convolution result of the row
								conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
								conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
								conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

								conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
								conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
								conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

								conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
								conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
								conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

								conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
								conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
								conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;
								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
							else begin
								// compute and output the first 2 convolution results of the row
								conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = row_buf0[0]; 	  conv_input_0[0][2] = row_buf0[1];
								conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = row_buf1[0]; 	  conv_input_0[1][2] = row_buf1[1];
								conv_input_0[2][0] = new_row_buf_w[1]; conv_input_0[2][1] = new_row_buf_w[2]; conv_input_0[2][2] = new_row_buf_w[3];

								conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
								conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
								conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

								conv_input_2[0][0] = row_buf0[1]; 	   conv_input_2[0][1] = row_buf0[2]; 	  conv_input_2[0][2] = row_buf0[3];
								conv_input_2[1][0] = row_buf1[1]; 	   conv_input_2[1][1] = row_buf1[2]; 	  conv_input_2[1][2] = row_buf1[3];
								conv_input_2[2][0] = new_row_buf_w[3]; conv_input_2[2][1] = new_row_buf_w[4]; conv_input_2[2][2] = new_row_buf_w[5];

								conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
								conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
								conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;

								// o_out_data1_w = convolution(weight_r, 
								// 							8'd0, row_buf0[0], row_buf0[1],
								// 							8'd0, row_buf1[0], row_buf1[1],
								// 							new_row_buf_w[1], new_row_buf_w[2], new_row_buf_w[3]);
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = convolution(weight_r, 
								// 							row_buf0[1], row_buf0[2], row_buf0[3],
								// 							row_buf1[1], row_buf1[2], row_buf1[3],
								// 							new_row_buf_w[3], new_row_buf_w[4], new_row_buf_w[5]);
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = conv_res_cnt_S2;
								o_out_addr2_w = 8'd0; // unused
								o_out_addr3_w = conv_res_cnt_S2 + 1;
								o_out_addr4_w = 12'd0; // unused
							end
						end
					end
					else if (conv_res_cnt_S1[5:0] == 59) begin // ex: 59, 123, 187, ...
						// For the end of a row, need to output 4 + 1 convolution results in two cycles
						if (row_end_flag == 1'b0) begin // first cycle
							// new_row_buf_w shifts left by 4, fill in new 4 pixels
							new_row_buf_w[0] = new_row_buf_r[4];
							new_row_buf_w[1] = new_row_buf_r[5];
							new_row_buf_w[2] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[4]; 
							new_row_buf_w[3] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[5]; 
							new_row_buf_w[4] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[6]; 
							new_row_buf_w[5] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : sram_out_data[7]; 

							if (S_param == 2'd1) begin
								// compute and output the first 3 convolution results of the row
								conv_input_0[0][0] = row_buf0[58]; 	   conv_input_0[0][1] = row_buf0[59]; 	  conv_input_0[0][2] = row_buf0[60];
								conv_input_0[1][0] = row_buf1[58]; 	   conv_input_0[1][1] = row_buf1[59]; 	  conv_input_0[1][2] = row_buf1[60];
								conv_input_0[2][0] = new_row_buf_w[0]; conv_input_0[2][1] = new_row_buf_w[1]; conv_input_0[2][2] = new_row_buf_w[2];

								conv_input_1[0][0] = row_buf0[59]; 	   conv_input_1[0][1] = row_buf0[60]; 	  conv_input_1[0][2] = row_buf0[61];
								conv_input_1[1][0] = row_buf1[59]; 	   conv_input_1[1][1] = row_buf1[60]; 	  conv_input_1[1][2] = row_buf1[61];
								conv_input_1[2][0] = new_row_buf_w[1]; conv_input_1[2][1] = new_row_buf_w[2]; conv_input_1[2][2] = new_row_buf_w[3];

								conv_input_2[0][0] = row_buf0[60]; 	   conv_input_2[0][1] = row_buf0[61]; 	  conv_input_2[0][2] = row_buf0[62];
								conv_input_2[1][0] = row_buf1[60]; 	   conv_input_2[1][1] = row_buf1[61]; 	  conv_input_2[1][2] = row_buf1[62];
								conv_input_2[2][0] = new_row_buf_w[2]; conv_input_2[2][1] = new_row_buf_w[3]; conv_input_2[2][2] = new_row_buf_w[4];

								conv_input_3[0][0] = row_buf0[61]; 	   conv_input_3[0][1] = row_buf0[62]; 	  conv_input_3[0][2] = row_buf0[63];
								conv_input_3[1][0] = row_buf1[61]; 	   conv_input_3[1][1] = row_buf1[62]; 	  conv_input_3[1][2] = row_buf1[63];
								conv_input_3[2][0] = new_row_buf_w[3]; conv_input_3[2][1] = new_row_buf_w[4]; conv_input_3[2][2] = new_row_buf_w[5];

								// o_out_data1_w = convolution(weight_r, 
								// 							row_buf0[58], row_buf0[59], row_buf0[60],
								// 							row_buf1[58], row_buf1[59], row_buf1[60],
								// 							new_row_buf_w[0], new_row_buf_w[1], new_row_buf_w[2]);
								// o_out_data2_w = convolution(weight_r, 
								// 							row_buf0[59], row_buf0[60], row_buf0[61],
								// 							row_buf1[59], row_buf1[60], row_buf1[61],
								// 							new_row_buf_w[1], new_row_buf_w[2], new_row_buf_w[3]);
								// o_out_data3_w = convolution(weight_r, 
								// 							row_buf0[60], row_buf0[61], row_buf0[62],
								// 							row_buf1[60], row_buf1[61], row_buf1[62],
								// 							new_row_buf_w[2], new_row_buf_w[3], new_row_buf_w[4]);
								// o_out_data4_w = convolution(weight_r, 
								// 							row_buf0[61], row_buf0[62], row_buf0[63],
								// 							row_buf1[61], row_buf1[62], row_buf1[63],
								// 							new_row_buf_w[3], new_row_buf_w[4], new_row_buf_w[5]);
								o_out_addr1_w = conv_res_cnt_S1;
								o_out_addr2_w = conv_res_cnt_S1 + 1;
								o_out_addr3_w = conv_res_cnt_S1 + 2;
								o_out_addr4_w = conv_res_cnt_S1 + 3; 
							end
							else begin // S_param == 2'd2
								if (conv_res_cnt_S1[6:0] >= 64) begin
									// don't compute and output convolution result of the row
									conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
									conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
									conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

									conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
									conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
									conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

									conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
									conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
									conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

									conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
									conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
									conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;
									// o_out_data1_w = 8'd0; // unused
									// o_out_data2_w = 8'd0; // unused
									// o_out_data3_w = 8'd0; // unused
									// o_out_data4_w = 8'd0; // unused
									o_out_addr1_w = 12'd0; // unused
									o_out_addr2_w = 12'd0; // unused
									o_out_addr3_w = 12'd0; // unused
									o_out_addr4_w = 12'd0; // unused
								end
								else begin
									// compute and output the last 2 convolution results of the row
									conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
									conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
									conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 		 	  conv_input_0[2][2] = 8'd0;

									conv_input_1[0][0] = row_buf0[59]; 	   conv_input_1[0][1] = row_buf0[60]; 	  conv_input_1[0][2] = row_buf0[61];
									conv_input_1[1][0] = row_buf1[59]; 	   conv_input_1[1][1] = row_buf1[60]; 	  conv_input_1[1][2] = row_buf1[61];
									conv_input_1[2][0] = new_row_buf_w[1]; conv_input_1[2][1] = new_row_buf_w[2]; conv_input_1[2][2] = new_row_buf_w[3];

									conv_input_2[0][0] = 8'd0; 	   		   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
									conv_input_2[1][0] = 8'd0; 	   		   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
									conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 		 	  conv_input_2[2][2] = 8'd0;

									conv_input_3[0][0] = row_buf0[61]; 	   conv_input_3[0][1] = row_buf0[62]; 	  conv_input_3[0][2] = row_buf0[63];
									conv_input_3[1][0] = row_buf1[61]; 	   conv_input_3[1][1] = row_buf1[62]; 	  conv_input_3[1][2] = row_buf1[63];
									conv_input_3[2][0] = new_row_buf_w[3]; conv_input_3[2][1] = new_row_buf_w[4]; conv_input_3[2][2] = new_row_buf_w[5];

									// o_out_data1_w = 8'd0; // unused
									// o_out_data2_w = convolution(weight_r, 
									// 							row_buf0[59], row_buf0[60], row_buf0[61],
									// 							row_buf1[59], row_buf1[60], row_buf1[61],
									// 							new_row_buf_w[1], new_row_buf_w[2], new_row_buf_w[3]);
									// o_out_data3_w = 8'd0; // unused
									// o_out_data4_w = convolution(weight_r, 
									// 							row_buf0[61], row_buf0[62], row_buf0[63],
									// 							row_buf1[61], row_buf1[62], row_buf1[63],
									// 							new_row_buf_w[3], new_row_buf_w[4], new_row_buf_w[5]);
									o_out_addr1_w = 12'd0; // unused
									o_out_addr2_w = conv_res_cnt_S2;
									o_out_addr3_w = 12'd0; // unused
									o_out_addr4_w = conv_res_cnt_S2 + 1; 
								end
							end
						end
						else begin // second cycle
							new_row_buf_w[0] = new_row_buf_r[0];
							new_row_buf_w[1] = new_row_buf_r[1];
							new_row_buf_w[2] = new_row_buf_r[2];
							new_row_buf_w[3] = new_row_buf_r[3];
							new_row_buf_w[4] = new_row_buf_r[4];
							new_row_buf_w[5] = new_row_buf_r[5];
							
							conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
							conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
							conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

							conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
							conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
							conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

							conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
							conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
							conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

							conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
							conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
							conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;

							if (S_param == 2'd1) begin
								conv_input_0[0][0] = row_buf0[62]; 	   conv_input_0[0][1] = row_buf0[63]; 	  conv_input_0[0][2] = 8'd0;
								conv_input_0[1][0] = row_buf1[62]; 	   conv_input_0[1][1] = row_buf1[63]; 	  conv_input_0[1][2] = 8'd0;
								conv_input_0[2][0] = new_row_buf_w[4]; conv_input_0[2][1] = new_row_buf_w[5]; conv_input_0[2][2] = 8'd0;

								// o_out_data1_w = convolution(weight_r, 
								// 							row_buf0[62], row_buf0[63], 8'd0,
								// 							row_buf1[62], row_buf1[63], 8'd0,
								// 							new_row_buf_w[4], new_row_buf_w[5], 8'd0);
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = conv_res_cnt_S1 + 4;
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
							else begin // S_param == 2'd2
								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
						end
					end
					else begin
						// output 4 convolution results in a cycle
						// new_row_buf_w shifts left by 4, fill in new 4 pixels
						new_row_buf_w[0] = new_row_buf_r[4]; 
						new_row_buf_w[1] = new_row_buf_r[5]; 
						new_row_buf_w[2] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : (addr_add_flag) ? sram_out_data[0] : sram_out_data[4];
						new_row_buf_w[3] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : (addr_add_flag) ? sram_out_data[1] : sram_out_data[5];
						new_row_buf_w[4] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : (addr_add_flag) ? sram_out_data[2] : sram_out_data[6];
						new_row_buf_w[5] = (conv_res_cnt_S1 >= 4032) ? 8'd0 : (addr_add_flag) ? sram_out_data[3] : sram_out_data[7];

						for (i = 0; i < 6; i = i + 1) begin
							row_buf0_pixel[i] = row_buf0[i + row_buf_idx];
							row_buf1_pixel[i] = row_buf1[i + row_buf_idx];
						end

						conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
						conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
						conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

						conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
						conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
						conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

						conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
						conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
						conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

						conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
						conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
						conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;

						if (S_param == 2'd1) begin
							// compute and output the 4 convolution results
							conv_input_0[0][0] = row_buf0_pixel[0]; conv_input_0[0][1] = row_buf0_pixel[1]; conv_input_0[0][2] = row_buf0_pixel[2];
							conv_input_0[1][0] = row_buf1_pixel[0]; conv_input_0[1][1] = row_buf1_pixel[1]; conv_input_0[1][2] = row_buf1_pixel[2];
							conv_input_0[2][0] = new_row_buf_w[0];  conv_input_0[2][1] = new_row_buf_w[1];  conv_input_0[2][2] = new_row_buf_w[2];

							conv_input_1[0][0] = row_buf0_pixel[1]; conv_input_1[0][1] = row_buf0_pixel[2]; conv_input_1[0][2] = row_buf0_pixel[3];
							conv_input_1[1][0] = row_buf1_pixel[1]; conv_input_1[1][1] = row_buf1_pixel[2]; conv_input_1[1][2] = row_buf1_pixel[3];
							conv_input_1[2][0] = new_row_buf_w[1];  conv_input_1[2][1] = new_row_buf_w[2];  conv_input_1[2][2] = new_row_buf_w[3];

							conv_input_2[0][0] = row_buf0_pixel[2]; conv_input_2[0][1] = row_buf0_pixel[3]; conv_input_2[0][2] = row_buf0_pixel[4];
							conv_input_2[1][0] = row_buf1_pixel[2]; conv_input_2[1][1] = row_buf1_pixel[3]; conv_input_2[1][2] = row_buf1_pixel[4];
							conv_input_2[2][0] = new_row_buf_w[2];  conv_input_2[2][1] = new_row_buf_w[3];  conv_input_2[2][2] = new_row_buf_w[4];

							conv_input_3[0][0] = row_buf0_pixel[3]; conv_input_3[0][1] = row_buf0_pixel[4]; conv_input_3[0][2] = row_buf0_pixel[5];
							conv_input_3[1][0] = row_buf1_pixel[3]; conv_input_3[1][1] = row_buf1_pixel[4]; conv_input_3[1][2] = row_buf1_pixel[5];
							conv_input_3[2][0] = new_row_buf_w[3];  conv_input_3[2][1] = new_row_buf_w[4];  conv_input_3[2][2] = new_row_buf_w[5];

							// o_out_data1_w = convolution(weight_r, 
							// 							row_buf0_pixel[0], row_buf0_pixel[1], row_buf0_pixel[2],
							// 							row_buf1_pixel[0], row_buf1_pixel[1], row_buf1_pixel[2],
							// 							new_row_buf_w[0], new_row_buf_w[1], new_row_buf_w[2]);
							// o_out_data2_w = convolution(weight_r, 
							// 							row_buf0_pixel[1], row_buf0_pixel[2], row_buf0_pixel[3],
							// 							row_buf1_pixel[1], row_buf1_pixel[2], row_buf1_pixel[3],
							// 							new_row_buf_w[1], new_row_buf_w[2], new_row_buf_w[3]);
							// o_out_data3_w = convolution(weight_r, 
							// 							row_buf0_pixel[2], row_buf0_pixel[3], row_buf0_pixel[4],
							// 							row_buf1_pixel[2], row_buf1_pixel[3], row_buf1_pixel[4],
							// 							new_row_buf_w[2], new_row_buf_w[3], new_row_buf_w[4]);
							// o_out_data4_w = convolution(weight_r, 
							// 							row_buf0_pixel[3], row_buf0_pixel[4], row_buf0_pixel[5],
							// 							row_buf1_pixel[3], row_buf1_pixel[4], row_buf1_pixel[5],
							// 							new_row_buf_w[3], new_row_buf_w[4], new_row_buf_w[5]);
							o_out_addr1_w = conv_res_cnt_S1;
							o_out_addr2_w = conv_res_cnt_S1 + 1;
							o_out_addr3_w = conv_res_cnt_S1 + 2;
							o_out_addr4_w = conv_res_cnt_S1 + 3;
						end
						else begin // S_param == 2'd2
							if (conv_res_cnt_S1[6:0] >= 64) begin
								// don't compute and output convolution result of the row
								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
							else begin
								// compute and output the 4 convolution results
								conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
								conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
								conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

								conv_input_1[0][0] = row_buf0_pixel[1]; conv_input_1[0][1] = row_buf0_pixel[2]; conv_input_1[0][2] = row_buf0_pixel[3];
								conv_input_1[1][0] = row_buf1_pixel[1]; conv_input_1[1][1] = row_buf1_pixel[2]; conv_input_1[1][2] = row_buf1_pixel[3];
								conv_input_1[2][0] = new_row_buf_w[1];  conv_input_1[2][1] = new_row_buf_w[2];  conv_input_1[2][2] = new_row_buf_w[3];

								conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
								conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
								conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

								conv_input_3[0][0] = row_buf0_pixel[3]; conv_input_3[0][1] = row_buf0_pixel[4]; conv_input_3[0][2] = row_buf0_pixel[5];
								conv_input_3[1][0] = row_buf1_pixel[3]; conv_input_3[1][1] = row_buf1_pixel[4]; conv_input_3[1][2] = row_buf1_pixel[5];
								conv_input_3[2][0] = new_row_buf_w[3];  conv_input_3[2][1] = new_row_buf_w[4];  conv_input_3[2][2] = new_row_buf_w[5];


								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = convolution(weight_r, 
								// 							row_buf0_pixel[1], row_buf0_pixel[2], row_buf0_pixel[3],
								// 							row_buf1_pixel[1], row_buf1_pixel[2], row_buf1_pixel[3],
								// 							new_row_buf_w[1], new_row_buf_w[2], new_row_buf_w[3]);
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = convolution(weight_r, 
								// 							row_buf0_pixel[3], row_buf0_pixel[4], row_buf0_pixel[5],
								// 							row_buf1_pixel[3], row_buf1_pixel[4], row_buf1_pixel[5],
								// 							new_row_buf_w[3], new_row_buf_w[4], new_row_buf_w[5]);
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = conv_res_cnt_S2;
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = conv_res_cnt_S2 + 1;
							end
						end
					end
				end
				else begin
					new_row_buf_w[0] = 0;
					new_row_buf_w[1] = 0;
					new_row_buf_w[2] = 0;
					new_row_buf_w[3] = 0;
					new_row_buf_w[4] = 0;
					new_row_buf_w[5] = 0;

					conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
					conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
					conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

					conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
					conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
					conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

					conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
					conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
					conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

					conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
					conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
					conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;

					// o_out_data1_w = 0;
					// o_out_data2_w = 0;
					// o_out_data3_w = 0;
					// o_out_data4_w = 0;
					o_out_addr1_w = 0;
					o_out_addr2_w = 0;
					o_out_addr3_w = 0;
					o_out_addr4_w = 0;
				end
			end
			2'd2: begin
				new_row_buf_w[0] = 0;
				new_row_buf_w[1] = 0;
				new_row_buf_w[2] = 0;
				new_row_buf_w[3] = 0;
				new_row_buf_w[4] = 0;
				new_row_buf_w[5] = 0;

				new_row_buf_D2_w[0] = new_row_buf_D2_r[0];
				new_row_buf_D2_w[1] = new_row_buf_D2_r[1];
				new_row_buf_D2_w[2] = new_row_buf_D2_r[2];
				new_row_buf_D2_w[3] = new_row_buf_D2_r[3];
				new_row_buf_D2_w[4] = new_row_buf_D2_r[4];
				new_row_buf_D2_w[5] = new_row_buf_D2_r[5];
				new_row_buf_D2_w[6] = new_row_buf_D2_r[6];
				new_row_buf_D2_w[7] = new_row_buf_D2_r[7];

				conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
				conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
				conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

				conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
				conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
				conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

				conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
				conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
				conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

				conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
				conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
				conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;

				if (conv_pixel_cnt >= 64) begin // row1 loaded
					if ((conv_res_cnt_S1 & 6'b111111) == 0) begin // ex: 0, 64, 128, ...
						// For the start of a row, only output 2 convolution results in a cycle
						new_row_buf_D2_w[0] = 8'd0; 
						new_row_buf_D2_w[1] = 8'd0;
						new_row_buf_D2_w[2] = 8'd0;
						new_row_buf_D2_w[3] = 8'd0;
						new_row_buf_D2_w[4] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : sram_out_data[0]; 
						new_row_buf_D2_w[5] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : sram_out_data[1]; 
						new_row_buf_D2_w[6] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : sram_out_data[2]; 
						new_row_buf_D2_w[7] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : sram_out_data[3]; 

						if (S_param == 2'd1) begin
							// compute and output the first 2 convolution results of the row
							conv_input_0[0][0] = 8'd0; 			      conv_input_0[0][1] = row_buf0[0]; 		conv_input_0[0][2] = row_buf0[2];
							conv_input_0[1][0] = 8'd0; 			   	  conv_input_0[1][1] = row_buf2[0]; 		conv_input_0[1][2] = row_buf2[2];
							conv_input_0[2][0] = new_row_buf_D2_w[2]; conv_input_0[2][1] = new_row_buf_D2_w[4]; conv_input_0[2][2] = new_row_buf_D2_w[6];

							conv_input_1[0][0] = 8'd0; 			   	  conv_input_1[0][1] = row_buf0[1]; 	  	conv_input_1[0][2] = row_buf0[3];
							conv_input_1[1][0] = 8'd0; 			   	  conv_input_1[1][1] = row_buf2[1]; 	  	conv_input_1[1][2] = row_buf2[3];
							conv_input_1[2][0] = new_row_buf_D2_w[3]; conv_input_1[2][1] = new_row_buf_D2_w[5]; conv_input_1[2][2] = new_row_buf_D2_w[7];

							// o_out_data1_w = convolution(weight_r, 
							// 							8'd0, row_buf0[0], row_buf0[2],
							// 							8'd0, row_buf2[0], row_buf2[2],
							// 							new_row_buf_D2_w[2], new_row_buf_D2_w[4], new_row_buf_D2_w[6]);

							// o_out_data2_w = convolution(weight_r, 
							// 							8'd0, row_buf0[1], row_buf0[3],
							// 							8'd0, row_buf2[1], row_buf2[3],
							// 							new_row_buf_D2_w[3], new_row_buf_D2_w[5], new_row_buf_D2_w[7]);
							// o_out_data3_w = 8'd0; // unused
							// o_out_data4_w = 8'd0; // unused
							o_out_addr1_w = conv_res_cnt_S1;
							o_out_addr2_w = conv_res_cnt_S1 + 1;
							o_out_addr3_w = 12'd0; // unused
							o_out_addr4_w = 12'd0; // unused
						end
						else begin // S_param == 2'd2
							if (conv_res_cnt_S1[6:0] >= 64) begin // ex: 64, 192, 320, ...
								// don't compute and output convolution result of the row
								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
							else begin
								// compute and output the first 2 convolution results of the row
								conv_input_0[0][0] = 8'd0; 			      conv_input_0[0][1] = row_buf0[0]; 		conv_input_0[0][2] = row_buf0[2];
								conv_input_0[1][0] = 8'd0; 			   	  conv_input_0[1][1] = row_buf2[0]; 		conv_input_0[1][2] = row_buf2[2];
								conv_input_0[2][0] = new_row_buf_D2_w[2]; conv_input_0[2][1] = new_row_buf_D2_w[4]; conv_input_0[2][2] = new_row_buf_D2_w[6];

								// o_out_data1_w = convolution(weight_r, 
								// 							8'd0, row_buf0[0], row_buf0[2],
								// 							8'd0, row_buf2[0], row_buf2[2],
								// 							new_row_buf_D2_w[2], new_row_buf_D2_w[4], new_row_buf_D2_w[6]);
															
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = conv_res_cnt_S2;
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
						end
					end
					else if (conv_res_cnt_S1[5:0] == 62) begin // ex: 62, 126, 190, ...
						// For the end of a row, also only output 2 convolution results in a cycle
						// new_row_buf_D2_w shifts left by 4, fill in new 4 pixels
						new_row_buf_D2_w[0] = new_row_buf_D2_r[4];
						new_row_buf_D2_w[1] = new_row_buf_D2_r[5];
						new_row_buf_D2_w[2] = new_row_buf_D2_r[6];
						new_row_buf_D2_w[3] = new_row_buf_D2_r[7];
						new_row_buf_D2_w[4] = 8'd0; 
						new_row_buf_D2_w[5] = 8'd0; 
						new_row_buf_D2_w[6] = 8'd0; 
						new_row_buf_D2_w[7] = 8'd0; 

						if (S_param == 2'd1) begin
							// compute and output the first 3 convolution results of the row
							conv_input_0[0][0] = row_buf0[60]; 		  conv_input_0[0][1] = row_buf0[62]; 		conv_input_0[0][2] = 8'd0;
							conv_input_0[1][0] = row_buf2[60]; 		  conv_input_0[1][1] = row_buf2[62]; 		conv_input_0[1][2] = 8'd0;
							conv_input_0[2][0] = new_row_buf_D2_w[0]; conv_input_0[2][1] = new_row_buf_D2_w[2]; conv_input_0[2][2] = new_row_buf_D2_w[4];

							conv_input_1[0][0] = row_buf0[61]; 		  conv_input_1[0][1] = row_buf0[63]; 	  	conv_input_1[0][2] = 8'd0;
							conv_input_1[1][0] = row_buf2[61]; 		  conv_input_1[1][1] = row_buf2[63]; 	  	conv_input_1[1][2] = 8'd0;
							conv_input_1[2][0] = new_row_buf_D2_w[1]; conv_input_1[2][1] = new_row_buf_D2_w[3]; conv_input_1[2][2] = new_row_buf_D2_w[5];

							// o_out_data1_w = convolution(weight_r, 
							// 							row_buf0[60], row_buf0[62], 8'd0,
							// 							row_buf2[60], row_buf2[62], 8'd0,
							// 							new_row_buf_D2_w[0], new_row_buf_D2_w[2], new_row_buf_D2_w[4]);
							// o_out_data2_w = convolution(weight_r, 
							// 							row_buf0[61], row_buf0[63], 8'd0,
							// 							row_buf2[61], row_buf2[63], 8'd0,
							// 							new_row_buf_D2_w[1], new_row_buf_D2_w[3], new_row_buf_D2_w[5]);
							// o_out_data3_w = 12'd0; // unused
							// o_out_data4_w = 12'd0; // unused
							o_out_addr1_w = conv_res_cnt_S1;
							o_out_addr2_w = conv_res_cnt_S1 + 1;
							o_out_addr3_w = 12'd0; // unused
							o_out_addr4_w = 12'd0; // unused
						end
						else begin // S_param == 2'd2
							if (conv_res_cnt_S1[6:0] >= 64) begin // ex: 126, 254, 382, ...  
								// don't compute and output convolution result of the row
								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
							else begin
								// compute and output the last 2 convolution results of the row
								conv_input_0[0][0] = row_buf0[60]; 		  conv_input_0[0][1] = row_buf0[62]; 		conv_input_0[0][2] = 8'd0;
								conv_input_0[1][0] = row_buf2[60]; 		  conv_input_0[1][1] = row_buf2[62]; 		conv_input_0[1][2] = 8'd0;
								conv_input_0[2][0] = new_row_buf_D2_w[0]; conv_input_0[2][1] = new_row_buf_D2_w[2]; conv_input_0[2][2] = new_row_buf_D2_w[4];

								// o_out_data1_w = convolution(weight_r, 
								// 						row_buf0[60], row_buf0[62], 8'd0,
								// 						row_buf2[60], row_buf2[62], 8'd0,
								// 						new_row_buf_D2_w[0], new_row_buf_D2_w[2], new_row_buf_D2_w[4]);
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = conv_res_cnt_S2; 
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
						end
					end
					else begin
						// output 4 convolution results in a cycle
						// new_row_buf_D2_w shifts left by 4, fill in new 4 pixels
						new_row_buf_D2_w[0] = new_row_buf_D2_r[4]; 
						new_row_buf_D2_w[1] = new_row_buf_D2_r[5]; 
						new_row_buf_D2_w[2] = new_row_buf_D2_r[6]; 
						new_row_buf_D2_w[3] = new_row_buf_D2_r[7];
						new_row_buf_D2_w[4] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : (addr_add_flag) ? sram_out_data[0] : sram_out_data[4];
						new_row_buf_D2_w[5] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : (addr_add_flag) ? sram_out_data[1] : sram_out_data[5];
						new_row_buf_D2_w[6] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : (addr_add_flag) ? sram_out_data[2] : sram_out_data[6];
						new_row_buf_D2_w[7] = (conv_res_cnt_S1 >= 3968) ? 8'd0 : (addr_add_flag) ? sram_out_data[3] : sram_out_data[7];

						// be careful here: row_buf_idx for D_param == 2'd2
						for (i = 0; i < 8; i = i + 1) begin
							row_buf0_pixel_D2[i] = row_buf0[i + row_buf_idx];
							row_buf2_pixel_D2[i] = row_buf2[i + row_buf_idx];
						end

						if (S_param == 2'd1) begin
							// compute and output the 4 convolution results
							conv_input_0[0][0] = row_buf0_pixel_D2[0]; conv_input_0[0][1] = row_buf0_pixel_D2[2]; conv_input_0[0][2] = row_buf0_pixel_D2[4];
							conv_input_0[1][0] = row_buf2_pixel_D2[0]; conv_input_0[1][1] = row_buf2_pixel_D2[2]; conv_input_0[1][2] = row_buf2_pixel_D2[4];
							conv_input_0[2][0] = new_row_buf_D2_w[0];  conv_input_0[2][1] = new_row_buf_D2_w[2];  conv_input_0[2][2] = new_row_buf_D2_w[4];

							conv_input_1[0][0] = row_buf0_pixel_D2[1]; conv_input_1[0][1] = row_buf0_pixel_D2[3]; conv_input_1[0][2] = row_buf0_pixel_D2[5];
							conv_input_1[1][0] = row_buf2_pixel_D2[1]; conv_input_1[1][1] = row_buf2_pixel_D2[3]; conv_input_1[1][2] = row_buf2_pixel_D2[5];
							conv_input_1[2][0] = new_row_buf_D2_w[1];  conv_input_1[2][1] = new_row_buf_D2_w[3];  conv_input_1[2][2] = new_row_buf_D2_w[5];

							conv_input_2[0][0] = row_buf0_pixel_D2[2]; conv_input_2[0][1] = row_buf0_pixel_D2[4]; conv_input_2[0][2] = row_buf0_pixel_D2[6];
							conv_input_2[1][0] = row_buf2_pixel_D2[2]; conv_input_2[1][1] = row_buf2_pixel_D2[4]; conv_input_2[1][2] = row_buf2_pixel_D2[6];
							conv_input_2[2][0] = new_row_buf_D2_w[2];  conv_input_2[2][1] = new_row_buf_D2_w[4];  conv_input_2[2][2] = new_row_buf_D2_w[6];

							conv_input_3[0][0] = row_buf0_pixel_D2[3]; conv_input_3[0][1] = row_buf0_pixel_D2[5]; conv_input_3[0][2] = row_buf0_pixel_D2[7];
							conv_input_3[1][0] = row_buf2_pixel_D2[3]; conv_input_3[1][1] = row_buf2_pixel_D2[5]; conv_input_3[1][2] = row_buf2_pixel_D2[7];
							conv_input_3[2][0] = new_row_buf_D2_w[3];  conv_input_3[2][1] = new_row_buf_D2_w[5];  conv_input_3[2][2] = new_row_buf_D2_w[7];

							// o_out_data1_w = convolution(weight_r, 
							// 							row_buf0_pixel_D2[0], row_buf0_pixel_D2[2], row_buf0_pixel_D2[4],
							// 							row_buf2_pixel_D2[0], row_buf2_pixel_D2[2], row_buf2_pixel_D2[4],
							// 							new_row_buf_D2_w[0], new_row_buf_D2_w[2], new_row_buf_D2_w[4]);
							// o_out_data2_w = convolution(weight_r, 
							// 							row_buf0_pixel_D2[1], row_buf0_pixel_D2[3], row_buf0_pixel_D2[5],
							// 							row_buf2_pixel_D2[1], row_buf2_pixel_D2[3], row_buf2_pixel_D2[5],
							// 							new_row_buf_D2_w[1], new_row_buf_D2_w[3], new_row_buf_D2_w[5]);
							// o_out_data3_w = convolution(weight_r, 
							// 							row_buf0_pixel_D2[2], row_buf0_pixel_D2[4], row_buf0_pixel_D2[6],
							// 							row_buf2_pixel_D2[2], row_buf2_pixel_D2[4], row_buf2_pixel_D2[6],
							// 							new_row_buf_D2_w[2], new_row_buf_D2_w[4], new_row_buf_D2_w[6]);
							// o_out_data4_w = convolution(weight_r, 
							// 							row_buf0_pixel_D2[3], row_buf0_pixel_D2[5], row_buf0_pixel_D2[7],
							// 							row_buf2_pixel_D2[3], row_buf2_pixel_D2[5], row_buf2_pixel_D2[7],
							// 							new_row_buf_D2_w[3], new_row_buf_D2_w[5], new_row_buf_D2_w[7]);
							o_out_addr1_w = conv_res_cnt_S1;
							o_out_addr2_w = conv_res_cnt_S1 + 1;
							o_out_addr3_w = conv_res_cnt_S1 + 2;
							o_out_addr4_w = conv_res_cnt_S1 + 3;
						end
						else begin // S_param == 2'd2
							if (conv_res_cnt_S1[6:0] >= 64) begin
								// don't compute and output convolution result of the row
								// o_out_data1_w = 8'd0; // unused
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = 8'd0; // unused
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = 12'd0; // unused
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = 12'd0; // unused
								o_out_addr4_w = 12'd0; // unused
							end
							else begin
								// compute and output the 4 convolution results
								conv_input_0[0][0] = row_buf0_pixel_D2[0]; conv_input_0[0][1] = row_buf0_pixel_D2[2]; conv_input_0[0][2] = row_buf0_pixel_D2[4];
								conv_input_0[1][0] = row_buf2_pixel_D2[0]; conv_input_0[1][1] = row_buf2_pixel_D2[2]; conv_input_0[1][2] = row_buf2_pixel_D2[4];
								conv_input_0[2][0] = new_row_buf_D2_w[0];  conv_input_0[2][1] = new_row_buf_D2_w[2];  conv_input_0[2][2] = new_row_buf_D2_w[4];

								conv_input_2[0][0] = row_buf0_pixel_D2[2]; conv_input_2[0][1] = row_buf0_pixel_D2[4]; conv_input_2[0][2] = row_buf0_pixel_D2[6];
								conv_input_2[1][0] = row_buf2_pixel_D2[2]; conv_input_2[1][1] = row_buf2_pixel_D2[4]; conv_input_2[1][2] = row_buf2_pixel_D2[6];
								conv_input_2[2][0] = new_row_buf_D2_w[2];  conv_input_2[2][1] = new_row_buf_D2_w[4];  conv_input_2[2][2] = new_row_buf_D2_w[6];
								
								// o_out_data1_w = convolution(weight_r, 
								// 						row_buf0_pixel_D2[0], row_buf0_pixel_D2[2], row_buf0_pixel_D2[4],
								// 						row_buf2_pixel_D2[0], row_buf2_pixel_D2[2], row_buf2_pixel_D2[4],
								// 						new_row_buf_D2_w[0], new_row_buf_D2_w[2], new_row_buf_D2_w[4]);
								// o_out_data2_w = 8'd0; // unused
								// o_out_data3_w = convolution(weight_r, 
								// 							row_buf0_pixel_D2[2], row_buf0_pixel_D2[4], row_buf0_pixel_D2[6],
								// 							row_buf2_pixel_D2[2], row_buf2_pixel_D2[4], row_buf2_pixel_D2[6],
								// 							new_row_buf_D2_w[2], new_row_buf_D2_w[4], new_row_buf_D2_w[6]);
								// o_out_data4_w = 8'd0; // unused
								o_out_addr1_w = conv_res_cnt_S2;
								o_out_addr2_w = 12'd0; // unused
								o_out_addr3_w = conv_res_cnt_S2 + 1;
								o_out_addr4_w = 12'd0; // unused
							end
						end
					end
				end
				else begin
					conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
					conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
					conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

					conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
					conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
					conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

					conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
					conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
					conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

					conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
					conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
					conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;
					// o_out_data1_w = 0;
					// o_out_data2_w = 0;
					// o_out_data3_w = 0;
					// o_out_data4_w = 0;
					o_out_addr1_w = 0;
					o_out_addr2_w = 0;
					o_out_addr3_w = 0;
					o_out_addr4_w = 0;
				end
			end
			default: begin
				new_row_buf_w[0] = 0;
				new_row_buf_w[1] = 0;
				new_row_buf_w[2] = 0;
				new_row_buf_w[3] = 0;
				new_row_buf_w[4] = 0;
				new_row_buf_w[5] = 0;

				new_row_buf_D2_w[0] = 0;
				new_row_buf_D2_w[1] = 0;
				new_row_buf_D2_w[2] = 0;
				new_row_buf_D2_w[3] = 0;
				new_row_buf_D2_w[4] = 0;
				new_row_buf_D2_w[5] = 0;
				new_row_buf_D2_w[6] = 0;
				new_row_buf_D2_w[7] = 0;

				conv_valid_in = 0;

				conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
				conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
				conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

				conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
				conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
				conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

				conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
				conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
				conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

				conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
				conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
				conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;
				// o_out_data1_w = 0;
				// o_out_data2_w = 0;
				// o_out_data3_w = 0;
				// o_out_data4_w = 0;
				o_out_addr1_w = 0;
				o_out_addr2_w = 0;
				o_out_addr3_w = 0;
				o_out_addr4_w = 0;
			end
		endcase
	end
	else begin
		new_row_buf_w[0] = 0;
		new_row_buf_w[1] = 0;
		new_row_buf_w[2] = 0;
		new_row_buf_w[3] = 0;
		new_row_buf_w[4] = 0;
		new_row_buf_w[5] = 0;

		new_row_buf_D2_w[0] = 0;
		new_row_buf_D2_w[1] = 0;
		new_row_buf_D2_w[2] = 0;
		new_row_buf_D2_w[3] = 0;
		new_row_buf_D2_w[4] = 0;
		new_row_buf_D2_w[5] = 0;
		new_row_buf_D2_w[6] = 0;
		new_row_buf_D2_w[7] = 0;

		conv_valid_in = 0;

		conv_input_0[0][0] = 8'd0; 			   conv_input_0[0][1] = 8'd0; 	  		  conv_input_0[0][2] = 8'd0;
		conv_input_0[1][0] = 8'd0; 			   conv_input_0[1][1] = 8'd0; 	  		  conv_input_0[1][2] = 8'd0;
		conv_input_0[2][0] = 8'd0; 			   conv_input_0[2][1] = 8'd0; 	  		  conv_input_0[2][2] = 8'd0;

		conv_input_1[0][0] = 8'd0; 			   conv_input_1[0][1] = 8'd0; 	  		  conv_input_1[0][2] = 8'd0;
		conv_input_1[1][0] = 8'd0; 			   conv_input_1[1][1] = 8'd0; 	  		  conv_input_1[1][2] = 8'd0;
		conv_input_1[2][0] = 8'd0; 			   conv_input_1[2][1] = 8'd0; 	  		  conv_input_1[2][2] = 8'd0;

		conv_input_2[0][0] = 8'd0; 			   conv_input_2[0][1] = 8'd0; 	  		  conv_input_2[0][2] = 8'd0;
		conv_input_2[1][0] = 8'd0; 			   conv_input_2[1][1] = 8'd0; 	  		  conv_input_2[1][2] = 8'd0;
		conv_input_2[2][0] = 8'd0; 			   conv_input_2[2][1] = 8'd0; 	  		  conv_input_2[2][2] = 8'd0;

		conv_input_3[0][0] = 8'd0; 			   conv_input_3[0][1] = 8'd0; 			  conv_input_3[0][2] = 8'd0;
		conv_input_3[1][0] = 8'd0; 			   conv_input_3[1][1] = 8'd0; 			  conv_input_3[1][2] = 8'd0;
		conv_input_3[2][0] = 8'd0; 			   conv_input_3[2][1] = 8'd0; 			  conv_input_3[2][2] = 8'd0;
		// o_out_data1_w = 0;
		// o_out_data2_w = 0;
		// o_out_data3_w = 0;
		// o_out_data4_w = 0;
		o_out_addr1_w = 0;
		o_out_addr2_w = 0;
		o_out_addr3_w = 0;
		o_out_addr4_w = 0;
	end
end

// update row_buf0, row_buf1, (row_buf2, row_buf3) 
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		for (k = 0; k < 64; k = k + 1) begin
			row_buf0[k] <= 0;
			row_buf1[k] <= 0;
			row_buf2[k] <= 0;
			row_buf3[k] <= 0;
		end
		conv_pixel_cnt <= 0;
		row_end_flag <= 0;
		row_buf_idx <= 0;
		conv_res_cnt_S1 <= 0;
		conv_res_cnt_S2 <= 0;
		for (k = 0; k < 6; k = k + 1) begin
			new_row_buf_r[k] <= 0;
		end
	end
	else if (state == CONV) begin
		case(D_param)
			2'd1: begin
				// When sram_addr == 0, conv_pixel_cnt need to stay 0 for 1 cycle due to SRAM output latency
				if (sram_addr == 0 || row_end_flag) begin
					conv_pixel_cnt <= conv_pixel_cnt;
				end
				else if (conv_pixel_cnt < 64) begin
					// loading pixels from row1 into row_buf2
					conv_pixel_cnt <= conv_pixel_cnt + 8;
				end
				else if (conv_pixel_cnt == 4096) begin
					// finish loading all pixels, do nothing
					conv_pixel_cnt <= conv_pixel_cnt;
				end
				else begin
					// After loading all pixels from row1 into row_buf2, shift row_buf0 and row_buf1 in every cycle
					conv_pixel_cnt <= conv_pixel_cnt + 4;
				end

				// update row_buf0, row_buf1 and new_row_buf_r
				if (conv_pixel_cnt < 64 && sram_addr != 0) begin // load pixels from row0 into row_buf1
					// Shift row_buf1 to make space for new pixels
					for (k = 0; k < 56; k = k + 1)
						row_buf1[k] <= row_buf1[k+8];

					// fill the new 8 pixels into the end of row_buf1
					row_buf1[56] <= sram_out_data[0]; // pixel_1, pixel_9, ..., pixel_57
					row_buf1[57] <= sram_out_data[1]; // pixel_2, pixel_10, ..., pixel_58
					row_buf1[58] <= sram_out_data[2]; // pixel_3, pixel_11, ..., pixel_59
					row_buf1[59] <= sram_out_data[3]; // pixel_4, pixel_12, ..., pixel_60
					row_buf1[60] <= sram_out_data[4]; // pixel_5, pixel_13, ..., pixel_61
					row_buf1[61] <= sram_out_data[5]; // pixel_6, pixel_14, ..., pixel_62
					row_buf1[62] <= sram_out_data[6]; // pixel_7, pixel_15, ..., pixel_63
					row_buf1[63] <= sram_out_data[7]; // pixel_8, pixel_16, ..., pixel_64
				end
				else if (conv_pixel_cnt >= 64 && conv_start_flag) begin // After loading all pixels from row0 into row_buf1, shift row_buf0 and row_buf1 in every cycle
					for (k = 0; k < 6; k = k + 1) begin
						new_row_buf_r[k] <= new_row_buf_w[k];
					end

					if ((conv_res_cnt_S1 & 6'b111111) == 0) begin // ex: 0, 64, 128, ...
						// For the start of a row, only output 3 convolution results in a cycle
						// Therefore, only shift the first 2 pixels from row_buf1 into row_buf0, from new_row_buf_w[0:5] into row_buf1
						row_buf0[0] <= row_buf1[0];
						row_buf0[1] <= row_buf1[1];
						row_buf1[0] <= new_row_buf_w[2];
						row_buf1[1] <= new_row_buf_w[3];
						row_buf_idx <= row_buf_idx + 2; 
						conv_res_cnt_S1 <= conv_res_cnt_S1 + 3;
						conv_res_cnt_S2 <= (conv_res_cnt_S1[6:0] >= 64) ? conv_res_cnt_S2 : conv_res_cnt_S2 + 2;
					end
					else if (conv_res_cnt_S1[5:0] == 59) begin // ex: 59, 123, 187, ...
						// For the end of a row, need to output 4 + 1 convolution results in two cycles
						if (row_end_flag == 0) begin // first cycle
							row_buf0[58] <= row_buf1[58];
							row_buf0[59] <= row_buf1[59];
							row_buf0[60] <= row_buf1[60];
							row_buf0[61] <= row_buf1[61];
							row_buf1[58] <= new_row_buf_w[0];
							row_buf1[59] <= new_row_buf_w[1];
							row_buf1[60] <= new_row_buf_w[2];
							row_buf1[61] <= new_row_buf_w[3];
							row_buf_idx <= row_buf_idx + 4;
							row_end_flag <= 1;
						end
						else begin // second cycle
							row_buf0[62] <= row_buf1[62];
							row_buf0[63] <= row_buf1[63];
							row_buf1[62] <= new_row_buf_w[4];
							row_buf1[63] <= new_row_buf_w[5];
							row_buf_idx <= 0; // reset for next row
							row_end_flag <= 0;
							conv_res_cnt_S1 <= conv_res_cnt_S1 + 5;
							conv_res_cnt_S2 <= (conv_res_cnt_S1[6:0] >= 64) ? conv_res_cnt_S2 : conv_res_cnt_S2 + 2;
						end
					end
					else begin
						for (i = 0; i < 4; i = i + 1) begin
							row_buf0[row_buf_idx + i] <= row_buf1[row_buf_idx + i];
							row_buf1[row_buf_idx + i] <= new_row_buf_w[i];
						end
						row_buf_idx <= row_buf_idx + 4;
						conv_res_cnt_S1 <= conv_res_cnt_S1 + 4;
						conv_res_cnt_S2 <= (conv_res_cnt_S1[6:0] >= 64) ? conv_res_cnt_S2 : conv_res_cnt_S2 + 2;
					end
				end
			end
			2'd2: begin
				// When sram_addr == 0, conv_pixel_cnt need to stay 0 for 1 cycle due to SRAM output latency
				if (sram_addr == 0) begin
					conv_pixel_cnt <= conv_pixel_cnt;
				end
				else if (conv_pixel_cnt < 128) begin
					// load row0, row1 into row_buf2, row_buf3 respectively
					conv_pixel_cnt <= conv_pixel_cnt + 8;
				end
				else if (conv_pixel_cnt == 4096) begin
					// finish loading all pixels, do nothing
					conv_pixel_cnt <= conv_pixel_cnt;
				end
				else begin
					// After loading all pixels from row1 into row_buf2, shift row_buf0 and row_buf1 in every cycle
					conv_pixel_cnt <= conv_pixel_cnt + 4;
				end

				// update row_buf0, row_buf1 and new_row_buf_r
				if (conv_pixel_cnt < 64 && sram_addr != 0) begin // load pixels from row0 into row_buf2
					// Shift row_buf1 to make space for new pixels
					for (k = 0; k < 56; k = k + 1)
						row_buf2[k] <= row_buf2[k+8];

					// fill the new 8 pixels into the end of row_buf1
					row_buf2[56] <= sram_out_data[0]; // pixel_1, pixel_9, ..., pixel_57
					row_buf2[57] <= sram_out_data[1]; // pixel_2, pixel_10, ..., pixel_58
					row_buf2[58] <= sram_out_data[2]; // pixel_3, pixel_11, ..., pixel_59
					row_buf2[59] <= sram_out_data[3]; // pixel_4, pixel_12, ..., pixel_60
					row_buf2[60] <= sram_out_data[4]; // pixel_5, pixel_13, ..., pixel_61
					row_buf2[61] <= sram_out_data[5]; // pixel_6, pixel_14, ..., pixel_62
					row_buf2[62] <= sram_out_data[6]; // pixel_7, pixel_15, ..., pixel_63
					row_buf2[63] <= sram_out_data[7]; // pixel_8, pixel_16, ..., pixel_64
				end
				else if (conv_pixel_cnt >= 64 && conv_pixel_cnt < 128) begin // load pixels from row1 into row_buf3
					// Shift row_buf3 to make space for new pixels
					for (k = 0; k < 56; k = k + 1)
						row_buf3[k] <= row_buf3[k+8];

					// fill the new 8 pixels into the end of row_buf3
					row_buf3[56] <= sram_out_data[0]; // pixel_65, pixel_73, ..., pixel_121
					row_buf3[57] <= sram_out_data[1]; // pixel_66, pixel_74, ..., pixel_122
					row_buf3[58] <= sram_out_data[2]; // pixel_67, pixel_75, ..., pixel_123
					row_buf3[59] <= sram_out_data[3]; // pixel_68, pixel_76, ..., pixel_124
					row_buf3[60] <= sram_out_data[4]; // pixel_69, pixel_77, ..., pixel_125
					row_buf3[61] <= sram_out_data[5]; // pixel_70, pixel_78, ..., pixel_126
					row_buf3[62] <= sram_out_data[6]; // pixel_71, pixel_79, ..., pixel_127
					row_buf3[63] <= sram_out_data[7]; // pixel_72, pixel_80, ..., pixel_128
				end
				else if (conv_pixel_cnt >= 128 && conv_start_flag) begin // After loading row0 and row1, load new row and shift upward in every cycle
					for (k = 0; k < 8; k = k + 1) begin
						new_row_buf_D2_r[k] <= new_row_buf_D2_w[k];
					end

					if ((conv_res_cnt_S1 & 6'b111111) == 0) begin // ex: 0, 64, 128, ...
						// For the start of a row, only output 2 convolution results in a cycle
						// Don't need to shift upward in this cycle
						row_buf_idx <= row_buf_idx; 
						conv_res_cnt_S1 <= conv_res_cnt_S1 + 2;
						conv_res_cnt_S2 <= (conv_res_cnt_S1[6:0] >= 64) ? conv_res_cnt_S2 : conv_res_cnt_S2 + 1;
					end
					else if (conv_res_cnt_S1[5:0] == 6'd62) begin // ex: 62, 126, 190, ...
						// For the end of a row, also only output 2 convolution results in a cycle
						// However, need to shift upward 4 pixels from each row_buf into the upper row_buf
						row_buf0[60] <= row_buf1[60];
						row_buf0[61] <= row_buf1[61];
						row_buf0[62] <= row_buf1[62];
						row_buf0[63] <= row_buf1[63];

						row_buf1[60] <= row_buf2[60];
						row_buf1[61] <= row_buf2[61];
						row_buf1[62] <= row_buf2[62];
						row_buf1[63] <= row_buf2[63];

						row_buf2[60] <= row_buf3[60];
						row_buf2[61] <= row_buf3[61];
						row_buf2[62] <= row_buf3[62];
						row_buf2[63] <= row_buf3[63];

						row_buf3[60] <= new_row_buf_D2_w[0];
						row_buf3[61] <= new_row_buf_D2_w[1];
						row_buf3[62] <= new_row_buf_D2_w[2];
						row_buf3[63] <= new_row_buf_D2_w[3];

						row_buf_idx <= 0; // reset for next row
						row_end_flag <= 0;
						conv_res_cnt_S1 <= conv_res_cnt_S1 + 2;
						conv_res_cnt_S2 <= (conv_res_cnt_S1[6:0] >= 64) ? conv_res_cnt_S2 : conv_res_cnt_S2 + 1;
					end
					else begin
						for (i = 0; i < 4; i = i + 1) begin
							row_buf0[row_buf_idx + i] <= row_buf1[row_buf_idx + i];
							row_buf1[row_buf_idx + i] <= row_buf2[row_buf_idx + i];
							row_buf2[row_buf_idx + i] <= row_buf3[row_buf_idx + i];
							row_buf3[row_buf_idx + i] <= new_row_buf_D2_w[i];
						end
						row_buf_idx <= row_buf_idx + 4;
						conv_res_cnt_S1 <= conv_res_cnt_S1 + 4;
						conv_res_cnt_S2 <= (conv_res_cnt_S1[6:0] >= 64) ? conv_res_cnt_S2 : conv_res_cnt_S2 + 2;
					end
				end
			end
		endcase
	end
end

// Update state
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) 
		state <= IDLE;
	else begin
		state <= next_state;
	end
end

// Update i_in_data_r used in LOAD_IMG and LOAD_WEIGHT
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) 
		i_in_data_r <= 0;
	else 
		i_in_data_r <= i_in_data;
end

// Update SRAM address
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		sram_addr <= 0;
		addr_add_flag <= 1'b0;
	end
	// Actually don't need this check since sram_addr is 9 bits, so it can't reach 512
	else if ((state == LOAD_IMG && next_state == DECODE) || state == LOAD_WEIGHT) begin 
		sram_addr <= 0;
	end
	else if ((state == LOAD_IMG && input_cycle_cnt[0]) || state == DECODE) begin
		sram_addr <= (sram_addr == 511) ? 511 : sram_addr + 1;
	end
	else if (state == CONV) begin
		case(D_param)
			2'd1: begin
				if (conv_pixel_cnt < 64) begin
					if (conv_pixel_cnt == 56) begin
						sram_addr <= sram_addr; // do nothing, keep the same address for 1 cycle
						addr_add_flag <= 1'b1;
					end
					else begin
						sram_addr <= sram_addr + 1;
						addr_add_flag <= 1'b0;
					end
				end
				else if (&conv_valid_out) begin // conv_pixel_cnt >= 64
					// In this case, for every two cycle, first read 4 pixels from sram0~3, then read 4 pixels from sram4~7
					if (row_end_flag) begin
						sram_addr <= sram_addr; // do nothing, keep the same address for 1 cycle
						addr_add_flag <= addr_add_flag;
					end
					else if (addr_add_flag) begin // add address
						sram_addr <= (sram_addr == 511) ? 511 : sram_addr + 1; // when sram_addr = 511, next will be 0 due to 9-bit overflow
						addr_add_flag <= 1'b0;
					end
					else begin
						sram_addr <= sram_addr; // do nothing, keep the same address for 1 cycle
						addr_add_flag <= 1'b1;
					end
				end
			end
			2'd2: begin
				if (conv_pixel_cnt < 128) begin
					if (conv_pixel_cnt == 120) begin
						sram_addr <= sram_addr; // do nothing, keep the same address for 1 cycle
						addr_add_flag <= 1'b1;
					end
					else begin
						sram_addr <= sram_addr + 1;
						addr_add_flag <= 1'b0;
					end
				end
				else if (&conv_valid_out) begin // conv_pixel_cnt >= 128
					// In this case, for every two cycle, first read 4 pixels from sram0~3, then read 4 pixels from sram4~7
					if (conv_res_cnt_S1[5:0] == 62) begin
						sram_addr <= sram_addr; // do nothing, keep the same address for 1 cycle
						addr_add_flag <= addr_add_flag;
					end
					else
					if (addr_add_flag) begin // add address
						sram_addr <= (sram_addr == 511) ? 511 : sram_addr + 1; // when sram_addr = 511, next will be 0 due to 9-bit overflow
						addr_add_flag <= 1'b0;
					end
					else begin
						sram_addr <= sram_addr; // do nothing, keep the same address for 1 cycle
						addr_add_flag <= 1'b1;
					end
				end
			end
		endcase
	end
end

// Input cycle counter used in LOAD_IMG and LOAD_WEIGHT
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) 
		input_cycle_cnt <= 0;
	else if (state == LOAD_IMG || state == LOAD_WEIGHT) 
		input_cycle_cnt <= input_cycle_cnt + 1;
end

// -----------------------------------------------------------------------------
// DECODE logic
// -----------------------------------------------------------------------------
always @(*) begin
	row_bits_w = row_bits_r;
	row_bits_idx_w = row_bits_idx_r;
	candidate = 0;
	row_has_match = 0;
	if (state == DECODE) begin
		if (sram_addr != 0) begin
			// tmp = (sram_addr % 8 == 0) ? 8 : sram_addr % 8;
			tmp = (sram_addr[2:0] == 3'd0 || decode_last_flag) ? 4'd8 : {1'b0, sram_addr[2:0]};
			row_bits_w[(63 - (tmp - 1)*8) -: 8] = {sram_out_data[0][0], sram_out_data[1][0], sram_out_data[2][0], sram_out_data[3][0],
												sram_out_data[4][0], sram_out_data[5][0], sram_out_data[6][0], sram_out_data[7][0]};

			// Search for patterns when pixel_cnt = 0, 64, 128, ..., 4032, 4096
			if ((pixel_cnt & 6'b111111) == 0) begin
				for (i = 0; i <= 7; i = i + 1) begin
					if ((row_bits_w[63-i -: 57] == PATTERN_K3S1D1) || (row_bits_w[63-i -: 57] == PATTERN_K3S1D2) ||
						(row_bits_w[63-i -: 57] == PATTERN_K3S2D1) || (row_bits_w[63-i -: 57] == PATTERN_K3S2D2)) begin
						candidate = row_bits_w[63-i -: 57];
						row_has_match = 1;
						row_bits_idx_w = i; // record i to check if it is identical to the previous match
					end
				end
			end
		end
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		row_bits_r <= 0;
		row_bits_idx_r <= 0;
		decode_last_flag <= 0;
	end 
	else if (state == DECODE) begin
		row_bits_r <= ((pixel_cnt & 6'b111111) == 0) ? 0 : row_bits_w;
		row_bits_idx_r <= row_bits_idx_w;
		decode_last_flag <= (sram_addr == 511) ? 1 : 0;
	end
end

// Output logic
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		pixel_cnt <= 0;
		barcode_found_cnt <= 0; 
		K_param <= 0;
		S_param <= 0;
		D_param <= 0;
		o_out_valid1_r <= 0; 
		o_out_valid2_r <= 0; 
		o_out_valid3_r <= 0;
		o_out_valid4_r <= 0;
		o_out_data1_r <= 0; 
		o_out_data2_r <= 0; 
		o_out_data3_r <= 0;
		o_out_data4_r <= 0;
		o_out_addr1_r <= 0;
		o_out_addr2_r <= 0;
		o_out_addr3_r <= 0;
		o_out_addr4_r <= 0;
	end
	else begin
		o_out_valid1_r <= 0;
		o_out_valid2_r <= 0;
		o_out_valid3_r <= 0;
		o_out_valid4_r <= 0;
		if (state == DECODE && next_state == DECODE) begin
			pixel_cnt <= pixel_cnt + 8;
			// $display("sram_addr: %d", sram_addr);
			
			if ((pixel_cnt & 6'b111111) == 0) // pixel_cnt = 0, 64, 128, ..., 4096
				if (row_has_match)
					barcode_found_cnt <= (row_bits_idx_w == row_bits_idx_r) ? (barcode_found_cnt + 1) : 1;
				else
					barcode_found_cnt <= 0;
			else
				barcode_found_cnt <= barcode_found_cnt;

			if (barcode_found_cnt == 9 && row_has_match) begin
				o_out_valid1_r <= 1; 
				o_out_valid2_r <= 1; 
				o_out_valid3_r <= 1;
				o_out_data1_r <= 8'd3;
				o_out_data2_r <= (candidate == PATTERN_K3S1D1 || candidate == PATTERN_K3S1D2) ? 8'd1 : 8'd2;
				o_out_data3_r <= (candidate == PATTERN_K3S1D1 || candidate == PATTERN_K3S2D1) ? 8'd1 : 8'd2;
				K_param <= 8'd3;
				S_param <= (candidate == PATTERN_K3S1D1 || candidate == PATTERN_K3S1D2) ? 8'd1 : 8'd2;
				D_param <= (candidate == PATTERN_K3S1D1 || candidate == PATTERN_K3S2D1) ? 8'd1 : 8'd2;
			end
			else if (pixel_cnt >= 4096) begin
				o_out_valid1_r <= 1; 
				o_out_valid2_r <= 1; 
				o_out_valid3_r <= 1;
				o_out_data1_r <= 0; 
				o_out_data2_r <= 0; 
				o_out_data3_r <= 0;
				pixel_cnt <= 0; // reset pixel_cnt to avoid overflow
			end
		end
		else if (state == CONV) begin
			if (((D_param == 2'd1 && conv_pixel_cnt >= 64) || (D_param == 2'd2 && conv_pixel_cnt >= 128))) begin // output the convolution results
				o_out_valid1_r <= (o_out_data1_w == 0 && o_out_addr1_r == 0 && !conv_addr0_flag) ? 0 : (&conv_valid_out) ? 1 : 0;
				o_out_valid2_r <= (o_out_data2_w == 0 && o_out_addr2_r == 0) ? 0 : (&conv_valid_out) ? 1 : 0;
				o_out_valid3_r <= (o_out_data3_w == 0 && o_out_addr3_r == 0) ? 0 : (&conv_valid_out) ? 1 : 0;
				o_out_valid4_r <= (o_out_data4_w == 0 && o_out_addr4_r == 0) ? 0 : (&conv_valid_out) ? 1 : 0;
				o_out_data1_r <= (&conv_valid_out) ? o_out_data1_w : 0;
				o_out_data2_r <= (&conv_valid_out) ? o_out_data2_w : 0;
				o_out_data3_r <= (&conv_valid_out) ? o_out_data3_w : 0;
				o_out_data4_r <= (&conv_valid_out) ? o_out_data4_w : 0;
				o_out_addr1_r <= (conv_start_flag) ? o_out_addr1_w : o_out_addr1_r;
				o_out_addr2_r <= (conv_start_flag) ? o_out_addr2_w : o_out_addr2_r;
				o_out_addr3_r <= (conv_start_flag) ? o_out_addr3_w : o_out_addr3_r;
				o_out_addr4_r <= (conv_start_flag) ? o_out_addr4_w : o_out_addr4_r;
			end
			else begin
				o_out_valid1_r <= 0;
				o_out_valid2_r <= 0;
				o_out_valid3_r <= 0;
				o_out_valid4_r <= 0;
			end
		end
		else begin
			o_out_valid1_r <= 0;
			o_out_valid2_r <= 0;
			o_out_valid3_r <= 0;
			o_out_valid4_r <= 0;
		end
	end
end

endmodule

module conv3x3_pipe #(
    parameter LAT = 3
)(
    input              clk,
    input              rst_n,
    input              valid_in,
    input signed [7:0] weight [0:2][0:2],
    input      [7:0]   p00, p01, p02,
    input      [7:0]   p10, p11, p12,
    input      [7:0]   p20, p21, p22,

    output reg         valid_out,
    output reg  [7:0]  conv_out
);

    // ---- Stage 1: Multiplication ----
    reg signed [15:0] mult [0:8];
    reg               valid_s1;

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s1 <= 1'b0;
            for (i = 0; i < 9; i = i + 1)
                mult[i] <= 16'd0;
        end
        else begin
            mult[0] <= weight[0][0] * $signed({1'b0, p00});
            mult[1] <= weight[0][1] * $signed({1'b0, p01});
            mult[2] <= weight[0][2] * $signed({1'b0, p02});
            mult[3] <= weight[1][0] * $signed({1'b0, p10});
            mult[4] <= weight[1][1] * $signed({1'b0, p11});
            mult[5] <= weight[1][2] * $signed({1'b0, p12});
            mult[6] <= weight[2][0] * $signed({1'b0, p20});
            mult[7] <= weight[2][1] * $signed({1'b0, p21});
            mult[8] <= weight[2][2] * $signed({1'b0, p22});
            valid_s1 <= valid_in;
        end
    end

    // ---- Stage 2: Addition + Rounding + Clamping ----
    reg signed [21:0] sum; // need more bits to avoid overflow during summation
	reg signed [15:0] rounded;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_out <= 0;
        else begin
            sum = mult[0] + mult[1] + mult[2] +
                  mult[3] + mult[4] + mult[5] +
                  mult[6] + mult[7] + mult[8];
            rounded = $signed(sum[21:7] + sum[6]);

            conv_out  <= (rounded > 255) ? 255 : ((rounded < 0) ? 0 : rounded[7:0]);
            valid_out <= valid_s1;
        end
    end

endmodule


