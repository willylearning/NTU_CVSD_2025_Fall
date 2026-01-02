`timescale 1ns/1ps

module bch(
	input clk,
	input rstn,
	input mode,
	input [1:0] code,
	input set,
	input [63:0] idata,
	output ready,
	output finish,
	output [9:0] odata
);

	localparam [2:0] S_IDLE      	 = 3'd0;
	localparam [2:0] S_SYNDROME_CALC = 3'd1;
	localparam [2:0] S_SOFT_WAIT	 = 3'd2;
	localparam [2:0] S_BMA			 = 3'd3;
	localparam [2:0] S_SEARCH		 = 3'd4;
	localparam [2:0] S_CORRELATION	 = 3'd5;
	localparam [2:0] S_OUTPUT		 = 3'd6;

	localparam CORR_CALC_PER_CYCLE = 32;
	localparam COST_MAX = 1023;

	reg [2:0] state, state_next;

	reg [7:0] idata_count;
	reg ready_r;
	assign ready = ready_r;

	// reg [7:0] llr_mem [1023:0];
	reg [6:0] llr_mem [1023:0];
	reg [7:0] llr_sign_bit;
	reg mode_r; // 0: hard-decision decoding, 1: soft-decision decoding
	reg [1:0] code_r; // 1: (63,45), 2: (255,239), 3: (1023,983)
	wire [9:0] n = (code_r == 1) ? 10'd63 : (code_r == 2) ? 10'd255 : 10'd1023;
	wire [3:0] m = (code_r == 1) ? 4'd6 : (code_r == 2) ? 4'd8 : 4'd10;
	wire [2:0] t = (code_r == 3) ? 3'd4 : 3'd2;
	integer i;

	wire [9:0] ALPHA_8 = (m == 6) ? 10'b0000001100 : (m == 8) ? 10'b0010111000 : 10'b0000000010;

	reg [9:0] odata_r;
	reg [2:0] odata_cnt;
	reg finish_r;
	assign odata = odata_r;
	assign finish = finish_r;

	// Syndrome calculation
	reg [7:0] r_data_in;
	wire [9:0] syndrome_out_alpha;
	wire [9:0] syndrome_out_alpha2;
	wire [9:0] syndrome_out_alpha3;
	wire [9:0] syndrome_out_alpha4;
	wire [9:0] syndrome_out_alpha5;
	wire [9:0] syndrome_out_alpha6;
	wire [9:0] syndrome_out_alpha7;
	wire [9:0] syndrome_out_alpha8;
	wire syndrome_calc_start = (state == S_SYNDROME_CALC && idata_count == 0);

	// Calculate min1 and min2 
	reg [6:0] w0 [0:7], w1 [0:7], w2 [0:5], w3 [0:2];
	reg [2:0] w0_idx [0:7], w1_idx [0:7], w2_idx [0:5], w3_idx [0:2];
	reg [6:0] w4;
	reg [2:0] w4_idx;
	reg [6:0] min1, min1_next, min1_tmp;
	reg [6:0] min2, min2_next, min2_tmp;
	reg [2:0] min1_tmp_idx;
	reg [2:0] min2_tmp_idx;
	reg [9:0] min1_r_idx, min1_r_idx_next;
	reg [9:0] min2_r_idx, min2_r_idx_next;
	reg [9:0] min1_alpha_power_tmp;
	reg [9:0] min2_alpha_power_tmp;
	reg [9:0] min1_alpha_power, min1_alpha_power_next;
	reg [9:0] min2_alpha_power, min2_alpha_power_next;
	// wire [9:0] min1_alpha_power_times_a8 = par_mul_GF2_M(min1_alpha_power, ALPHA_8, m); // multiply by α^8
	// wire [9:0] min2_alpha_power_times_a8 = par_mul_GF2_M(min2_alpha_power, ALPHA_8, m); // multiply by α^8
	// wire [9:0] min1_alpha_power_soft = par_mul_GF2_M(min1_alpha_power_tmp, min1_alpha_power, m); 
	// wire [9:0] min2_alpha_power_soft = par_mul_GF2_M(min2_alpha_power_tmp, min2_alpha_power, m); 

	wire [9:0] alpha_power [0:7];
	assign alpha_power[0] = (m == 6) ? 10'b100000 : (m == 8) ? 10'b10000000 : 10'b1000000000;
	assign alpha_power[1] = (m == 6) ? 10'b010000 : (m == 8) ? 10'b01000000 : 10'b0100000000;
	assign alpha_power[2] = (m == 6) ? 10'b001000 : (m == 8) ? 10'b00100000 : 10'b0010000000;
	assign alpha_power[3] = (m == 6) ? 10'b000100 : (m == 8) ? 10'b00010000 : 10'b0001000000;
	assign alpha_power[4] = (m == 6) ? 10'b000010 : (m == 8) ? 10'b00001000 : 10'b0000100000;
	assign alpha_power[5] = (m == 6) ? 10'b000001 : (m == 8) ? 10'b00000100 : 10'b0000010000;
	assign alpha_power[6] = (m == 6) ? 10'b110000 : (m == 8) ? 10'b00000010 : 10'b0000001000;
	assign alpha_power[7] = (m == 6) ? 10'b011000 : (m == 8) ? 10'b00000001 : 10'b0000000100;

	wire [9:0] p_min1_a8;
	wire [9:0] p_min2_a8;
	wire [9:0] p_min1_soft;
	wire [9:0] p_min2_soft;
	wire [9:0] min1_alpha_power_times_a8 = p_min1_a8; // multiply by α^8
	wire [9:0] min2_alpha_power_times_a8 = p_min2_a8; // multiply by α^8
	wire [9:0] min1_alpha_power_soft = p_min1_soft; 
	wire [9:0] min2_alpha_power_soft = p_min2_soft; 

	gf_mul u_min1_a8 (.a(min1_alpha_power), .b(ALPHA_8), .m(m), .p(p_min1_a8));
	gf_mul u_min2_a8 (.a(min2_alpha_power), .b(ALPHA_8), .m(m), .p(p_min2_a8));
	gf_mul u_min1_soft (.a(min1_alpha_power_tmp), .b(min1_alpha_power), .m(m), .p(p_min1_soft));
	gf_mul u_min2_soft (.a(min2_alpha_power_tmp), .b(min2_alpha_power), .m(m), .p(p_min2_soft));
	
	// BMA and Chien Search
	reg BMA_start;
	wire BMA_done, BMA_done_f1, BMA_done_f2, BMA_done_f3;
	wire BMA_first_cycle = (state == S_BMA && !BMA_start);
	wire [1:0] min_flag;

	// reg [9:0] S [0:7];
	// reg  [8*10-1:0] S, S_f1, S_f2, S_f3; // S_f1, S_f2, S_f3 are for S^min2, S^min1, S^min2^min1
	reg  [11*10-1:0] S, S_f1, S_f2, S_f3;
	wire [5*10-1:0] sigma, sigma_f1, sigma_f2, sigma_f3;
	wire [2:0] D, D_f1, D_f2, D_f3;
	
	reg output_1023;
	wire min1_in_err_loc, min2_in_err_loc;
	wire min1_in_err_loc_f1, min2_in_err_loc_f1;
	wire min1_in_err_loc_f2, min2_in_err_loc_f2;
	wire min1_in_err_loc_f3, min2_in_err_loc_f3;
	
	wire search_done, search_done_f1, search_done_f2, search_done_f3;
	wire search_done_all = search_done & search_done_f1 & search_done_f2 & search_done_f3;
	wire [2:0] err_cnt, err_cnt_f1, err_cnt_f2, err_cnt_f3;
	wire [4*10-1:0] err_loc_flat, err_loc_flat_f1, err_loc_flat_f2, err_loc_flat_f3;
	wire [9:0] err_loc [0:3], err_loc_f1 [0:3], err_loc_f2 [0:3], err_loc_f3 [0:3];
	assign err_loc[0] = err_loc_flat[4*10-1 -: 10];
	assign err_loc[1] = err_loc_flat[4*10-1-10 -: 10];
	assign err_loc[2] = err_loc_flat[4*10-1-20 -: 10];
	assign err_loc[3] = err_loc_flat[4*10-1-30 -: 10];
	assign err_loc_f1[0] = err_loc_flat_f1[4*10-1 -: 10];
	assign err_loc_f1[1] = err_loc_flat_f1[4*10-1-10 -: 10];
	assign err_loc_f1[2] = err_loc_flat_f1[4*10-1-20 -: 10];
	assign err_loc_f1[3] = err_loc_flat_f1[4*10-1-30 -: 10];
	assign err_loc_f2[0] = err_loc_flat_f2[4*10-1 -: 10];
	assign err_loc_f2[1] = err_loc_flat_f2[4*10-1-10 -: 10];
	assign err_loc_f2[2] = err_loc_flat_f2[4*10-1-20 -: 10];
	assign err_loc_f2[3] = err_loc_flat_f2[4*10-1-30 -: 10];
	assign err_loc_f3[0] = err_loc_flat_f3[4*10-1 -: 10];
	assign err_loc_f3[1] = err_loc_flat_f3[4*10-1-10 -: 10];
	assign err_loc_f3[2] = err_loc_flat_f3[4*10-1-20 -: 10];
	assign err_loc_f3[3] = err_loc_flat_f3[4*10-1-30 -: 10];

	reg [2:0] err_cnt_soft;
	reg [9:0] err_loc_soft [0:3];

	wire decode_fail = ((err_cnt != D) || (D > t));
	wire decode_fail_f1 = ((err_cnt_f1 != D_f1) || (D_f1 > t));
	wire decode_fail_f2 = ((err_cnt_f2 != D_f2) || (D_f2 > t));
	wire decode_fail_f3 = ((err_cnt_f3 != D_f3) || (D_f3 > t));
	wire only_p1 = (!decode_fail & decode_fail_f1 & decode_fail_f2 & decode_fail_f3);
	wire only_p2 = (decode_fail & !decode_fail_f1 & decode_fail_f2 & decode_fail_f3);
	wire only_p3 = (decode_fail & decode_fail_f1 & !decode_fail_f2 & decode_fail_f3);
	wire only_p4 = (decode_fail & decode_fail_f1 & decode_fail_f2 & !decode_fail_f3);
	wire early_select = (only_p1 | only_p2 | only_p3 | only_p4);

	// Correlation calculation
	reg [9:0] corr_cost, corr_cost_next;
	reg [9:0] corr_cost_f1, corr_cost_f1_next;
	reg [9:0] corr_cost_f2, corr_cost_f2_next;
	reg [9:0] corr_cost_f3, corr_cost_f3_next;
	reg [9:0] corr_sum_tmp, corr_sum_tmp_f1, corr_sum_tmp_f2, corr_sum_tmp_f3;

	// reg [9:0] correlation_cnt;
	reg [10:0] correlation_cnt;
	reg corr_bit, corr_bit_f1, corr_bit_f2, corr_bit_f3;
	// wire hit_original = (err_loc[0] == correlation_cnt || err_loc[1] == correlation_cnt || err_loc[2] == correlation_cnt || err_loc[3] == correlation_cnt);
	// wire hit_f1 = (err_loc_f1[0] == correlation_cnt || err_loc_f1[1] == correlation_cnt || err_loc_f1[2] == correlation_cnt || err_loc_f1[3] == correlation_cnt
	// 				|| (min2_in_err_loc_f1 && min2_r_idx == correlation_cnt));
	// wire hit_f2 = (err_loc_f2[0] == correlation_cnt || err_loc_f2[1] == correlation_cnt || err_loc_f2[2] == correlation_cnt || err_loc_f2[3] == correlation_cnt
	// 				|| (min1_in_err_loc_f2 && min1_r_idx == correlation_cnt));
	// wire hit_f3 = (err_loc_f3[0] == correlation_cnt || err_loc_f3[1] == correlation_cnt || err_loc_f3[2] == correlation_cnt || err_loc_f3[3] == correlation_cnt
	// 				|| (min1_in_err_loc_f3 && min1_r_idx == correlation_cnt) || (min2_in_err_loc_f3 && min2_r_idx == correlation_cnt));
	// wire hit_min2 = (min2_r_idx == correlation_cnt);
	// wire hit_min1 = (min1_r_idx == correlation_cnt);

	wire hit_original [0:CORR_CALC_PER_CYCLE-1];
	wire hit_f1       [0:CORR_CALC_PER_CYCLE-1];
	wire hit_f2       [0:CORR_CALC_PER_CYCLE-1];
	wire hit_f3       [0:CORR_CALC_PER_CYCLE-1];
	wire hit_min1     [0:CORR_CALC_PER_CYCLE-1];
	wire hit_min2     [0:CORR_CALC_PER_CYCLE-1];

	genvar j;
	generate
		for (j = 0; j < CORR_CALC_PER_CYCLE; j = j + 1) begin : GEN_HIT_FLAGS
			// ---------- original ----------
			assign hit_original[j] = (err_loc[0] == correlation_cnt + j) || (err_loc[1] == correlation_cnt + j) || (err_loc[2] == correlation_cnt + j) 
									 || (err_loc[3] == correlation_cnt + j);

			// ---------- f1 ----------
			assign hit_f1[j] = (err_loc_f1[0] == correlation_cnt + j) || (err_loc_f1[1] == correlation_cnt + j) || (err_loc_f1[2] == correlation_cnt + j) 
								|| (err_loc_f1[3] == correlation_cnt + j) || (min2_in_err_loc_f1 && (min2_r_idx == correlation_cnt + j));

			// ---------- f2 ----------
			assign hit_f2[j] = (err_loc_f2[0] == correlation_cnt + j) || (err_loc_f2[1] == correlation_cnt + j) || (err_loc_f2[2] == correlation_cnt + j) 
								|| (err_loc_f2[3] == correlation_cnt + j) || (min1_in_err_loc_f2 && (min1_r_idx == correlation_cnt + j));
			// ---------- f3 ----------
			assign hit_f3[j] = (err_loc_f3[0] == correlation_cnt + j) || (err_loc_f3[1] == correlation_cnt + j) || (err_loc_f3[2] == correlation_cnt + j) 
								|| (err_loc_f3[3] == correlation_cnt + j) || (min1_in_err_loc_f3 && (min1_r_idx == correlation_cnt + j)) || (min2_in_err_loc_f3 && (min2_r_idx == correlation_cnt + j));
			
			// ---------- min index hits ----------
			assign hit_min1[j] = (min1_r_idx == correlation_cnt + j);
			assign hit_min2[j] = (min2_r_idx == correlation_cnt + j);
		end
	endgenerate

	reg [9:0] min12;
	reg [1:0] idx12;
	reg [9:0] min34;
	reg [1:0] idx34;
	reg [1:0] corr_cost_min_idx; // 0 = p1 (original), 1 = p2 (f1), 2 = p3 (f2), 3 = p4 (f3)

	reg need_min1, need_min2;
	reg done_min1, done_min2;
	reg done_err_loc_soft;
	wire output_min1 = (need_min1 && !done_min1 && (done_err_loc_soft || min1_r_idx < err_loc_soft[odata_cnt]));
	wire output_min2 = (need_min2 && !done_min2 && (done_err_loc_soft || min2_r_idx < err_loc_soft[odata_cnt]));
	wire output_done_soft = (done_err_loc_soft || err_cnt_soft == 0) && (need_min1 ? done_min1 : 1'b1) && (need_min2 ? done_min2 : 1'b1);
	
	// Latch syndromes for both hard and soft decision decoding
	always @(posedge clk) begin
		if (!rstn) 
			S <= 0;
		else if (state == S_SYNDROME_CALC && idata_count == ((n + 1) >> 3)) 
			S <= {10'd0, 10'd0, 10'd0, syndrome_out_alpha, syndrome_out_alpha2, syndrome_out_alpha3, syndrome_out_alpha4, syndrome_out_alpha5, syndrome_out_alpha6, syndrome_out_alpha7, syndrome_out_alpha8};
		else if (BMA_start)  // shift left by 10 bits each cycle for BMA calculation
			S[109:10] <= S[99:0];
	end

	// Latch S_f1, S_f2, S_f3 for soft decision decoding
	always @(posedge clk) begin
		if (!rstn) begin
			S_f1 <= 0;
			S_f2 <= 0;
			S_f3 <= 0;
		end
		else if (state == S_SOFT_WAIT) begin
			case (idata_count)
				0: begin
					S_f1[109:80] <= 0;
					S_f2[109:80] <= 0;
					S_f3[109:80] <= 0;
					S_f1[79:70] <= S[79:70] ^ min2_alpha_power;
					S_f2[79:70] <= S[79:70] ^ min1_alpha_power;
					S_f3[79:70] <= S[79:70] ^ (min1_alpha_power ^ min2_alpha_power);
				end
				1: begin
					S_f1[69:60] <= S[69:60] ^ min2_alpha_power_soft;
					S_f2[69:60] <= S[69:60] ^ min1_alpha_power_soft;
					S_f3[69:60] <= S[69:60] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
				2: begin
					S_f1[59:50] <= S[59:50] ^ min2_alpha_power_soft;
					S_f2[59:50] <= S[59:50] ^ min1_alpha_power_soft;
					S_f3[59:50] <= S[59:50] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
				3: begin
					S_f1[49:40] <= S[49:40] ^ min2_alpha_power_soft;
					S_f2[49:40] <= S[49:40] ^ min1_alpha_power_soft;
					S_f3[49:40] <= S[49:40] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
				4: begin
					S_f1[39:30] <= S[39:30] ^ min2_alpha_power_soft;
					S_f2[39:30] <= S[39:30] ^ min1_alpha_power_soft;
					S_f3[39:30] <= S[39:30] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
				5: begin
					S_f1[29:20] <= S[29:20] ^ min2_alpha_power_soft;
					S_f2[29:20] <= S[29:20] ^ min1_alpha_power_soft;
					S_f3[29:20] <= S[29:20] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
				6: begin
					S_f1[19:10] <= S[19:10] ^ min2_alpha_power_soft;
					S_f2[19:10] <= S[19:10] ^ min1_alpha_power_soft;
					S_f3[19:10] <= S[19:10] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
				7: begin
					S_f1[9:0] <= S[9:0] ^ min2_alpha_power_soft;
					S_f2[9:0] <= S[9:0] ^ min1_alpha_power_soft;
					S_f3[9:0] <= S[9:0] ^ (min1_alpha_power_soft ^ min2_alpha_power_soft);
				end
			endcase
		end
		else if (BMA_start) begin // shift left by 10 bits each cycle for BMA calculation
			S_f1[109:10] <= S_f1[99:0];
			S_f2[109:10] <= S_f2[99:0];
			S_f3[109:10] <= S_f3[99:0];
		end
	end
	
	// Raise BMA_start signal when state is S_BMA 
	always @(posedge clk) begin
		if (!rstn) 
			BMA_start <= 1'b0;
		else if (state == S_BMA && state_next == S_BMA) 
			BMA_start <= 1'b1;
		else 
			BMA_start <= 1'b0;
	end

	// Raise output_1023 when S == 0 after BMA is done
	always @(posedge clk) begin
		if (!rstn) 
			output_1023 <= 1'b0;
		else if (state == S_IDLE) 
			output_1023 <= 1'b0;
		else if (BMA_first_cycle)
			output_1023 <= (S == 0);
	end

//============================================
//              Module Instantiations
//============================================
	S1_calc u_S1_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha));
	S2_calc u_S2_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha2));
	S3_calc u_S3_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha3));
	S4_calc u_S4_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha4));
	S5_calc u_S5_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha5));
	S6_calc u_S6_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha6));
	S7_calc u_S7_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha7));
	S8_calc u_S8_calc(.clk(clk), .rstn(rstn), .r_data(r_data_in), .syndrome_calc_start(syndrome_calc_start), .code(code_r), .syndrome_out(syndrome_out_alpha8));

	BMA u_bma (.clk(clk), .rstn(rstn), .BMA_start(BMA_start), .BMA_first_cycle(BMA_first_cycle), .syndromes_flat(S), .m(m), .t(t), .BMA_done(BMA_done), .degree(D), .sigma_out(sigma));
	BMA u_bma_f1 (.clk(clk), .rstn(rstn), .BMA_start(BMA_start), .BMA_first_cycle(BMA_first_cycle), .syndromes_flat(S_f1), .m(m), .t(t), .BMA_done(BMA_done_f1), .degree(D_f1), .sigma_out(sigma_f1));
	BMA u_bma_f2 (.clk(clk), .rstn(rstn), .BMA_start(BMA_start), .BMA_first_cycle(BMA_first_cycle), .syndromes_flat(S_f2), .m(m), .t(t), .BMA_done(BMA_done_f2), .degree(D_f2), .sigma_out(sigma_f2));
	BMA u_bma_f3 (.clk(clk), .rstn(rstn), .BMA_start(BMA_start), .BMA_first_cycle(BMA_first_cycle), .syndromes_flat(S_f3), .m(m), .t(t), .BMA_done(BMA_done_f3), .degree(D_f3), .sigma_out(sigma_f3));

	chien_search u_search (.clk(clk), .rstn(rstn), .search_start(BMA_done), .sigma_in_flat(sigma), .min1_r_idx(min1_r_idx), .min2_r_idx(min2_r_idx), .min_flag(2'd0),
							.m(m), .n(n), .t(t), .min1_in_err_loc(min1_in_err_loc), .min2_in_err_loc(min2_in_err_loc), .search_done(search_done), .err_cnt(err_cnt), .err_loc_flat(err_loc_flat));
	chien_search u_search_f1 (.clk(clk), .rstn(rstn), .search_start(BMA_done_f1), .sigma_in_flat(sigma_f1), .min1_r_idx(min1_r_idx), .min2_r_idx(min2_r_idx), .min_flag(2'd1),
							.m(m), .n(n), .t(t), .min1_in_err_loc(min1_in_err_loc_f1), .min2_in_err_loc(min2_in_err_loc_f1), .search_done(search_done_f1), .err_cnt(err_cnt_f1), .err_loc_flat(err_loc_flat_f1));
	chien_search u_search_f2 (.clk(clk), .rstn(rstn), .search_start(BMA_done_f2), .sigma_in_flat(sigma_f2), .min1_r_idx(min1_r_idx), .min2_r_idx(min2_r_idx), .min_flag(2'd2),
							.m(m), .n(n), .t(t), .min1_in_err_loc(min1_in_err_loc_f2), .min2_in_err_loc(min2_in_err_loc_f2), .search_done(search_done_f2), .err_cnt(err_cnt_f2), .err_loc_flat(err_loc_flat_f2));
	chien_search u_search_f3 (.clk(clk), .rstn(rstn), .search_start(BMA_done_f3), .sigma_in_flat(sigma_f3), .min1_r_idx(min1_r_idx), .min2_r_idx(min2_r_idx), .min_flag(2'd3),
							.m(m), .n(n), .t(t), .min1_in_err_loc(min1_in_err_loc_f3), .min2_in_err_loc(min2_in_err_loc_f3), .search_done(search_done_f3), .err_cnt(err_cnt_f3), .err_loc_flat(err_loc_flat_f3));

//============================================
//              Combinational Blocks
//============================================
	// FSM logic
	always @(*) begin
		case (state)
			S_IDLE: 
				state_next = (set) ? S_SYNDROME_CALC : S_IDLE;
			S_SYNDROME_CALC: 
				state_next = (idata_count == ((n + 1) >> 3) && !ready_r) ? (mode_r == 0 ? S_BMA : S_SOFT_WAIT) : S_SYNDROME_CALC;
			S_SOFT_WAIT: 
				state_next = ((idata_count == 7) || (t == 2 && idata_count == 3)) ? S_BMA : S_SOFT_WAIT;
			S_BMA:
				state_next = (output_1023) ? S_OUTPUT : (BMA_done ? S_SEARCH : S_BMA);
			S_SEARCH:
				state_next = (mode_r == 0) ? (search_done ? S_OUTPUT : S_SEARCH) : (search_done_all ? S_CORRELATION : S_SEARCH);
			S_CORRELATION:
				state_next = ((correlation_cnt >= n) || early_select) ? S_OUTPUT : S_CORRELATION;
			S_OUTPUT:
				state_next = ((mode_r == 0) && (output_1023 || odata_cnt == err_cnt - 1)) || ((mode_r == 1) && (output_1023 || output_done_soft)) ? S_IDLE : S_OUTPUT;
			default:
				state_next = S_IDLE;
		endcase
	end

	// Generate r_data_in, if llr >= 0, r_data_in = 0; else r_data_in = 1
	always @(*) begin
		r_data_in[7] = (llr_sign_bit[7] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[6] = (llr_sign_bit[6] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[5] = (llr_sign_bit[5] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[4] = (llr_sign_bit[4] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[3] = (llr_sign_bit[3] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[2] = (llr_sign_bit[2] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[1] = (llr_sign_bit[1] == 1'b0) ? 1'b0 : 1'b1;
		r_data_in[0] = (llr_sign_bit[0] == 1'b0) ? 1'b0 : 1'b1;
	end

	// Find two smallest values in llr_mem every cycle for soft decision decoding
	always @(*) begin
		w0[0] = (idata_count == 1) ? 7'd127 : llr_mem[7]; // When idata_count == 1, it's LLR0 (don't care), set w0[0] to max positive value
		w0_idx[0] = 7;
		for (i = 1; i < 8; i = i + 1) begin
			w0[i] = llr_mem[7-i];
			w0_idx[i] = 7 - i;
		end

		// Sorting network with total 13 comparators to find two smallest values among 8 llr values
		// Stage 1: compare (w0[0], w0[2]), (w0[1], w0[3]), (w0[4], w0[6]), (w0[5], w0[7])
		{w1[0], w1_idx[0]} = (w0[0] < w0[2])  ? {w0[0], w0_idx[0]} : {w0[2], w0_idx[2]};
		{w1[1], w1_idx[1]} = (w0[1] < w0[3])  ? {w0[1], w0_idx[1]} : {w0[3], w0_idx[3]};
		{w1[2], w1_idx[2]} = (w0[0] >= w0[2]) ? {w0[0], w0_idx[0]} : {w0[2], w0_idx[2]};
		{w1[3], w1_idx[3]} = (w0[1] >= w0[3]) ? {w0[1], w0_idx[1]} : {w0[3], w0_idx[3]};
		{w1[4], w1_idx[4]} = (w0[4] < w0[6])  ? {w0[4], w0_idx[4]} : {w0[6], w0_idx[6]};
		{w1[5], w1_idx[5]} = (w0[5] < w0[7])  ? {w0[5], w0_idx[5]} : {w0[7], w0_idx[7]};
		{w1[6], w1_idx[6]} = (w0[4] >= w0[6]) ? {w0[4], w0_idx[4]} : {w0[6], w0_idx[6]};
		{w1[7], w1_idx[7]} = (w0[5] >= w0[7]) ? {w0[5], w0_idx[5]} : {w0[7], w0_idx[7]};
		
		// Stage 2: compare (w1[0], w1[4]), (w1[1], w1[5]), (w1[2], w1[6]), (w1[3], w1[7]), but only need to keep track of above 6 bits
		{w2[0], w2_idx[0]} = (w1[0] < w1[4])  ? {w1[0], w1_idx[0]} : {w1[4], w1_idx[4]};
		{w2[1], w2_idx[1]} = (w1[1] < w1[5])  ? {w1[1], w1_idx[1]} : {w1[5], w1_idx[5]};
		{w2[2], w2_idx[2]} = (w1[2] < w1[6])  ? {w1[2], w1_idx[2]} : {w1[6], w1_idx[6]};
		{w2[3], w2_idx[3]} = (w1[3] < w1[7])  ? {w1[3], w1_idx[3]} : {w1[7], w1_idx[7]};
		{w2[4], w2_idx[4]} = (w1[0] >= w1[4]) ? {w1[0], w1_idx[0]} : {w1[4], w1_idx[4]};
		{w2[5], w2_idx[5]} = (w1[1] >= w1[5]) ? {w1[1], w1_idx[1]} : {w1[5], w1_idx[5]};

		// Stage 3: compare (w2[0], w2[1]), (w2[2], w2[3]), (w2[4], w2[5]), but only need to keep track of above 4 bits
		{min1_tmp, min1_tmp_idx} = (w2[0] < w2[1]) ? {w2[0], w2_idx[0]} : {w2[1], w2_idx[1]}; // the smallest value is determined here
		{w3[0], w3_idx[0]} = (w2[0] >= w2[1]) ? {w2[0], w2_idx[0]} : {w2[1], w2_idx[1]};
		{w3[1], w3_idx[1]} = (w2[2] < w2[3]) ? {w2[2], w2_idx[2]} : {w2[3], w2_idx[3]};
		{w3[2], w3_idx[2]} = (w2[4] < w2[5]) ? {w2[4], w2_idx[4]} : {w2[5], w2_idx[5]};

		// Stage 4: compare (w3[0], w3[1], w3[2])
		{w4, w4_idx} = (w3[1] < w3[2]) ? {w3[1], w3_idx[1]} : {w3[2], w3_idx[2]};
		{min2_tmp, min2_tmp_idx} = (w3[0] < w4) ? {w3[0], w3_idx[0]} : {w4, w4_idx}; // the second smallest value is determined here

		// Update min1_next, min2_next, min1_alpha_power_next, min2_alpha_power_next, min1_sign_next, min2_sign_next
		if (min1_tmp <= min1) begin
			min1_next = min1_tmp;
			min1_alpha_power_next = alpha_power[min1_tmp_idx];
			min1_r_idx_next = min1_tmp_idx;
			min2_next = (min2_tmp <= min1) ? min2_tmp : min1;
			min2_alpha_power_next = (min2_tmp <= min1) ? alpha_power[min2_tmp_idx] : min1_alpha_power_times_a8;
			min2_r_idx_next = (min2_tmp <= min1) ? min2_tmp_idx : min1_r_idx + 10'd8;
		end
		else begin
			min1_next = min1;
			min1_alpha_power_next = min1_alpha_power_times_a8; // min1_alpha_power_times_a8 = min1_alpha_power * α^8
			min1_r_idx_next = min1_r_idx + 10'd8;
			min2_next = (min1_tmp <= min2) ? min1_tmp : min2;
			min2_alpha_power_next = (min1_tmp <= min2) ? alpha_power[min1_tmp_idx] : min2_alpha_power_times_a8;
			min2_r_idx_next = (min1_tmp <= min2) ? min1_tmp_idx : min2_r_idx + 10'd8;
		end
	end
	
	// Calculate correlation values for original, f1, f2, f3 cases
	always @(*) begin
		corr_bit = 0;
		corr_bit_f1 = 0;
		corr_bit_f2 = 0;
		corr_bit_f3 = 0;
		corr_sum_tmp = 0;
		corr_sum_tmp_f1 = 0;
		corr_sum_tmp_f2 = 0;
		corr_sum_tmp_f3 = 0;
		
		for (i = 0; i < CORR_CALC_PER_CYCLE; i = i + 1) begin
			corr_bit = hit_original[i]; // original case
			corr_bit_f1 = hit_min2[i] ^ hit_f1[i]; // f1 flipped case
			corr_bit_f2 = hit_min1[i] ^ hit_f2[i]; // f2 flipped case
			corr_bit_f3 = (hit_min1[i] | hit_min2[i]) ^ hit_f3[i]; // f3 flipped case

			corr_sum_tmp = corr_bit ? (corr_sum_tmp + llr_mem[i]) : corr_sum_tmp;
			corr_sum_tmp_f1 = corr_bit_f1 ? (corr_sum_tmp_f1 + llr_mem[i]) : corr_sum_tmp_f1;
			corr_sum_tmp_f2 = corr_bit_f2 ? (corr_sum_tmp_f2 + llr_mem[i]) : corr_sum_tmp_f2;
			corr_sum_tmp_f3 = corr_bit_f3 ? (corr_sum_tmp_f3 + llr_mem[i]) : corr_sum_tmp_f3;
		end

		corr_cost_next = corr_cost + corr_sum_tmp;
		corr_cost_f1_next = corr_cost_f1 + corr_sum_tmp_f1;
		corr_cost_f2_next = corr_cost_f2 + corr_sum_tmp_f2;
		corr_cost_f3_next = corr_cost_f3 + corr_sum_tmp_f3;
	end

	// Sort correlation costs to find the test pattern with the lowest correlation cost (highest correlation value)
	always @(*) begin
		min12 = (corr_cost < corr_cost_f1) ? corr_cost : corr_cost_f1;
		idx12 = (corr_cost < corr_cost_f1) ? 2'd0 : 2'd1;

		min34 = (corr_cost_f2 < corr_cost_f3) ? corr_cost_f2 : corr_cost_f3;
		idx34 = (corr_cost_f2 < corr_cost_f3) ? 2'd2 : 2'd3;

		if (only_p1)
			corr_cost_min_idx = 2'd0;
		else if (only_p2)
			corr_cost_min_idx = 2'd1;
		else if (only_p3)
			corr_cost_min_idx = 2'd2;
		else if (only_p4)
			corr_cost_min_idx = 2'd3;
		else
			corr_cost_min_idx = (min12 < min34) ? idx12 : idx34;
	end

//============================================
//              Sequential Blocks
//============================================
	// Update state
	always @(posedge clk) begin
		if (!rstn) 
			state <= S_IDLE;
		else 
			state <= state_next;
	end

	// Latch mode and code
	always @(posedge clk) begin
		if (!rstn) begin
			mode_r <= 0;
			code_r <= 0;
		end 
		else if (set) begin
			mode_r <= mode;
			code_r <= code;
		end
	end

	// Update ready_r and idata_count
	always @(posedge clk) begin
		if (!rstn) begin
			ready_r <= 0;
			idata_count <= 0;
		end 
		else if (state == S_SYNDROME_CALC) begin
			ready_r <= (idata_count < ((n + 1) >> 3) - 1);
			idata_count <= (ready_r) ? idata_count + 1'b1 : 0; // (idata_count < ((n + 1) >> 3)) ? idata_count + 1'b1 : 0;
		end
		else if (state == S_SOFT_WAIT) begin
			idata_count <= (idata_count < 7) ? idata_count + 1'b1 : 0;
		end
	end

	// Update llr_mem
	always @(posedge clk) begin
		if (!rstn) begin
			llr_sign_bit <= 8'd0;
			for (i = 0; i <= 1023; i = i + 1)
				llr_mem[i] <= 0;
		end 
		else if (state == S_IDLE) begin
			llr_sign_bit <= 8'd0;
			for (i = 0; i <= 1023; i = i + 1)
				llr_mem[i] <= 0;
		end
		else if (state == S_SYNDROME_CALC && ready_r) begin
			llr_sign_bit <= {idata[63], idata[55], idata[47], idata[39], idata[31], idata[23], idata[15], idata[7]};

			// Load new 8 llr absolute values into llr_mem[7:0]
			llr_mem[7] <= idata[63] ? (~idata[62:56] + 1'b1) : idata[62:56];
			llr_mem[6] <= idata[55] ? (~idata[54:48] + 1'b1) : idata[54:48];
			llr_mem[5] <= idata[47] ? (~idata[46:40] + 1'b1) : idata[46:40];
			llr_mem[4] <= idata[39] ? (~idata[38:32] + 1'b1) : idata[38:32];
			llr_mem[3] <= idata[31] ? (~idata[30:24] + 1'b1) : idata[30:24];
			llr_mem[2] <= idata[23] ? (~idata[22:16] + 1'b1) : idata[22:16];
			llr_mem[1] <= idata[15] ? (~idata[14:8]  + 1'b1) : idata[14:8];
			llr_mem[0] <= idata[7]  ? (~idata[6:0]   + 1'b1) : idata[6:0];

			// Shift llr_mem[1015:0] to llr_mem[1023:8]
			for (i = 1023; i >= 8; i = i - 1)
            	llr_mem[i] <= llr_mem[i-8];
		end
		else if (state == S_CORRELATION) begin
			// // Shift llr_mem[1023:1] to llr_mem[1022:0]
			// for (i = 1023; i >= 1; i = i - 1)
			// 	llr_mem[i-1] <= llr_mem[i];

			// Shift 8 elements, llr_mem[1023:8] to llr_mem[1015:0]
			for (i = 1023; i >= CORR_CALC_PER_CYCLE; i = i - 1)
				llr_mem[i-CORR_CALC_PER_CYCLE] <= llr_mem[i];
		end
	end

	// Update min1, min2, min1_alpha_power, min2_alpha_power
	always @(posedge clk) begin
		if (!rstn) begin
			min1 <= 8'd127; // initialize to max positive value
			min1_alpha_power <= 0;
			min1_r_idx <= 0;
			min2 <= 8'd127;
			min2_alpha_power <= 0;
			min2_r_idx <= 0;
		end 
		else if (state == S_SYNDROME_CALC && idata_count == 0) begin
			min1 <= 8'd127; // initialize to max positive value
			min1_alpha_power <= 0;
			min1_r_idx <= 0;
			min2 <= 8'd127;
			min2_alpha_power <= 0;
			min2_r_idx <= 0;
		end
		else if (state == S_SYNDROME_CALC && idata_count != 0) begin
			min1 <= min1_next;
			min1_alpha_power <= min1_alpha_power_next;
			min1_r_idx <= min1_r_idx_next;
			min2 <= min2_next;
			min2_alpha_power <= min2_alpha_power_next;
			min2_r_idx <= min2_r_idx_next;
		end
	end

	// Update min1_alpha_power_tmp, min2_alpha_power_tmp for calculating S_f1, S_f2, S_f3
	always @(posedge clk) begin
		if (!rstn) begin
			min1_alpha_power_tmp <= 0;
			min2_alpha_power_tmp <= 0;
		end 
		else if (state == S_IDLE) begin
			min1_alpha_power_tmp <= 0;
			min2_alpha_power_tmp <= 0;
		end 
		else if (state == S_SOFT_WAIT) begin
			min1_alpha_power_tmp <= (idata_count == 0) ? min1_alpha_power : min1_alpha_power_soft;
			min2_alpha_power_tmp <= (idata_count == 0) ? min2_alpha_power : min2_alpha_power_soft;
		end
	end

	// Update corr_cost, corr_cost_f1, corr_cost_f2, corr_cost_f3, correlation_cnt
	always @(posedge clk) begin
		if (!rstn) begin
			corr_cost <= COST_MAX;
			corr_cost_f1 <= COST_MAX;
			corr_cost_f2 <= COST_MAX;
			corr_cost_f3 <= COST_MAX;
			correlation_cnt <= 10'd0;
		end 
		else if (state == S_IDLE) begin
			corr_cost <= COST_MAX;
			corr_cost_f1 <= COST_MAX;
			corr_cost_f2 <= COST_MAX;
			corr_cost_f3 <= COST_MAX;
			correlation_cnt <= 10'd0;
		end 
		else if (state == S_CORRELATION) begin
			// Decode fail cases: err_cnt != D || D > t
			corr_cost <= (decode_fail) ? COST_MAX : corr_cost_next; // if decode fail, set corr_cost to the larges (COST_MAX)
			corr_cost_f1 <= (decode_fail_f1) ? COST_MAX : corr_cost_f1_next;
			corr_cost_f2 <= (decode_fail_f2) ? COST_MAX : corr_cost_f2_next;
			corr_cost_f3 <= (decode_fail_f3) ? COST_MAX : corr_cost_f3_next;
			correlation_cnt <= (correlation_cnt >= n) ? correlation_cnt : (correlation_cnt + CORR_CALC_PER_CYCLE);
		end
	end

	// Update err_loc_soft, need_min1, need_min2 based on corr_cost_min_idx
	always @(posedge clk) begin
		if (!rstn) begin	
			err_cnt_soft <= 0;
			for (i = 0; i <= 3; i = i + 1)
				err_loc_soft[i] <= 0;
			need_min1 <= 0;
			need_min2 <= 0;
		end 
		else if (state == S_IDLE) begin
			err_cnt_soft <= 0;
			for (i = 0; i <= 3; i = i + 1)
				err_loc_soft[i] <= 0;
			need_min1 <= 0;
			need_min2 <= 0;
		end
		else if (state == S_CORRELATION && ((correlation_cnt >= n) || early_select)) begin
			// $display("corr_cost_min_idx = %d", corr_cost_min_idx);
			case (corr_cost_min_idx)
				2'd0: begin
					err_cnt_soft <= err_cnt;
					for (i = 0; i <= 3; i = i + 1)
						err_loc_soft[i] <= err_loc[i];
					need_min1 <= 0;
					need_min2 <= 0;
				end
				2'd1: begin
					err_cnt_soft <= (min2_in_err_loc_f1) ? err_cnt_f1 - 1 : err_cnt_f1;
					for (i = 0; i <= 3; i = i + 1)
						err_loc_soft[i] <= err_loc_f1[i];
					need_min1 <= 0;
					need_min2 <= !min2_in_err_loc_f1;
				end
				2'd2: begin
					err_cnt_soft <= (min1_in_err_loc_f2) ? err_cnt_f2 - 1 : err_cnt_f2;
					for (i = 0; i <= 3; i = i + 1)
						err_loc_soft[i] <= err_loc_f2[i];
					need_min1 <= !min1_in_err_loc_f2;
					need_min2 <= 0;
				end
				2'd3: begin
					err_cnt_soft <= (err_cnt_f3 - ((min1_in_err_loc_f3 ? 1 : 0) + (min2_in_err_loc_f3 ? 1 : 0)));
					for (i = 0; i <= 3; i = i + 1)
						err_loc_soft[i] <= err_loc_f3[i];
					need_min1 <= !min1_in_err_loc_f3;
					need_min2 <= !min2_in_err_loc_f3;
				end
			endcase
		end
	end

	// Update odata_r, odata_cnt and finish_r
	always @(posedge clk) begin
		if (!rstn) begin
			done_min1 <= 0;
			done_min2 <= 0;
			done_err_loc_soft <= 0;
			odata_r <= 0;
			odata_cnt <= 0;
			finish_r <= 0;
		end 
		if (state == S_OUTPUT) begin
			if (mode_r == 1'b0) begin // hard decision decoding
				if (output_1023) begin // no error
					odata_r <= 1023; 
					finish_r <= 1;
				end
				else begin
					odata_r <= err_loc[odata_cnt];
					odata_cnt <= (odata_cnt == err_cnt - 1) ? odata_cnt : odata_cnt + 1; // odata_cnt can't exceed err_cnt - 1
					finish_r <= 1;
				end
			end
			else begin // soft decision decoding
				if (output_1023) begin // no error 
					// $display("corr_cost_min_idx");
					odata_r <= 1023; 
					done_err_loc_soft <= 1;
					finish_r <= 1;
				end
				else if (output_min1 && output_min2) begin
					if (min1_r_idx < min2_r_idx) begin
						odata_r <= min1_r_idx;
						done_min1 <= 1;
						finish_r <= 1;
					end
					else begin
						odata_r <= min2_r_idx;
						done_min2 <= 1;
						finish_r <= 1;
					end
				end
				else if (output_min1) begin
					odata_r <= min1_r_idx;
					done_min1 <= 1;
					finish_r <= 1;
				end
				else if (output_min2) begin
					odata_r <= min2_r_idx;
					done_min2 <= 1;
					finish_r <= 1;
				end
				else begin
					odata_r <= err_loc_soft[odata_cnt];
					odata_cnt <= (odata_cnt == err_cnt_soft - 1) ? odata_cnt : odata_cnt + 1; // odata_cnt can't exceed err_cnt_soft - 1
					done_err_loc_soft <= (odata_cnt == err_cnt_soft - 1) ? 1 : 0;
					finish_r <= (!output_done_soft) ? 1 : 0;
				end
			end
		end
		else begin
			done_min1 <= 0;
			done_min2 <= 0;
			done_err_loc_soft <= 0;
			odata_r <= 0;
			odata_cnt <= 0;
			finish_r <= 0;
		end 
	end

endmodule