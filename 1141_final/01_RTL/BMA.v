module BMA ( // Inversionless Berlekamp-Massey Algorithm
    input clk,
    input rstn,
    input BMA_start,
	input BMA_first_cycle,
	input [11*10-1:0] syndromes_flat, // S1..S8, each M bits
	input [3:0] m,
	input [2:0] t,
    output reg BMA_done,
	output [2:0] degree,
	output [5*10-1:0] sigma_out // σ0..σT
);
	wire [9:0] syndromes [0:10];
	assign syndromes[0] = syndromes_flat[11*10-1 -: 10];
	assign syndromes[1] = syndromes_flat[11*10-1-10 -: 10];
	assign syndromes[2] = syndromes_flat[11*10-1-20 -: 10];
	assign syndromes[3] = syndromes_flat[11*10-1-30 -: 10];
	assign syndromes[4] = syndromes_flat[11*10-1-40 -: 10];
	assign syndromes[5] = syndromes_flat[11*10-1-50 -: 10];
	assign syndromes[6] = syndromes_flat[11*10-1-60 -: 10];
	assign syndromes[7] = syndromes_flat[11*10-1-70 -: 10];
	assign syndromes[8] = syndromes_flat[11*10-1-80 -: 10];
	assign syndromes[9] = syndromes_flat[11*10-1-90 -: 10];
	assign syndromes[10] = syndromes_flat[11*10-1-100 -: 10];

	// sigma[0] is the coefficient of x^0, sigma[1] of x^1, ..., sigma[T] of x^T
    reg [9:0] sigma [0:4], sigma_next [0:4]; // σ^(i+1), when T = 2, sigma_next[3:4] are always 0 (unused)
	// tau[0] is the coefficient of x^0, tau[1] of x^1, ..., tau[T-1] of x^(T-1)
	reg [9:0] tau [0:3], tau_next [0:3];   // τ^(i), τ^(i+1)

	reg [2:0] D, D_next; // D
    reg [9:0] delta, delta_next; // δ
    reg [9:0] Delta, Delta_next; // Δ^(i), Δ^(i+1) (this round uses it to update σ,τ)
	reg [2:0] iteration_cnt;
	integer i;

	// assign sigma_out = sigma;
	assign degree = D;
	assign sigma_out = {sigma[0], sigma[1], sigma[2], sigma[3], sigma[4]};

	wire [9:0] p0, p1, p2, p3, p4, p5, p6, p7, p8;
	gf_mul u_s0 (.a(delta), .b(sigma[0]), .m(m), .p(p0));
	gf_mul u_s1 (.a(delta), .b(sigma[1]), .m(m), .p(p1));
	gf_mul u_s2 (.a(Delta), .b(tau[0]), .m(m), .p(p2));
	gf_mul u_s3 (.a(delta), .b(sigma[2]), .m(m), .p(p3));
	gf_mul u_s4 (.a(Delta), .b(tau[1]), .m(m), .p(p4));
	gf_mul u_s5 (.a(delta), .b(sigma[3]), .m(m), .p(p5));
	gf_mul u_s6 (.a(Delta), .b(tau[2]), .m(m), .p(p6));
	gf_mul u_s7 (.a(delta), .b(sigma[4]), .m(m), .p(p7));
	gf_mul u_s8 (.a(Delta), .b(tau[3]), .m(m), .p(p8));

	wire [9:0] p9, p10, p11, p12, p13;
	gf_mul u_d0 (.a(syndromes[4]), .b(sigma_next[0]), .m(m), .p(p9));
	gf_mul u_d1 (.a(syndromes[3]), .b(sigma_next[1]), .m(m), .p(p10));
	gf_mul u_d2 (.a(syndromes[2]), .b(sigma_next[2]), .m(m), .p(p11));
	gf_mul u_d3 (.a(syndromes[1]), .b(sigma_next[3]), .m(m), .p(p12));
	gf_mul u_d4 (.a(syndromes[0]), .b(sigma_next[4]), .m(m), .p(p13));
	
	// Compute sigma_next, Delta_next, D_next, delta_next, tau_next
	always @(*) begin
		// sigma_next[0] = par_mul_GF2_M(delta, sigma[0], m);
		// sigma_next[1] = par_mul_GF2_M(delta, sigma[1], m) ^ par_mul_GF2_M(Delta, tau[0], m);
		// sigma_next[2] = par_mul_GF2_M(delta, sigma[2], m) ^ par_mul_GF2_M(Delta, tau[1], m);
		// sigma_next[3] = par_mul_GF2_M(delta, sigma[3], m) ^ par_mul_GF2_M(Delta, tau[2], m);
		// sigma_next[4] = par_mul_GF2_M(delta, sigma[4], m) ^ par_mul_GF2_M(Delta, tau[3], m);
		sigma_next[0] = p0;
		sigma_next[1] = p1 ^ p2;
		sigma_next[2] = p3 ^ p4;
		sigma_next[3] = p5 ^ p6;
		sigma_next[4] = p7 ^ p8;

		// Delta_next = par_mul_GF2_M(syndromes[4], sigma_next[0], m) ^ par_mul_GF2_M(syndromes[3], sigma_next[1], m)
		// 					^ par_mul_GF2_M(syndromes[2], sigma_next[2], m) ^ par_mul_GF2_M(syndromes[1], sigma_next[3], m)
		// 					^ par_mul_GF2_M(syndromes[0], sigma_next[4], m);
		Delta_next = p9 ^ p10 ^ p11 ^ p12 ^ p13;
		
		if (Delta == 0 || (2*D) >= iteration_cnt + 1) begin
			D_next = D;
			delta_next = delta;
			tau_next[0] = 0;
			for (i = 1; i <= 3; i = i + 1) // for (i = 1; i < T; i = i + 1)
				tau_next[i] = tau[i-1];
		end
		else begin
			D_next = (iteration_cnt + 1) - D;
			delta_next = Delta;
			for (i = 0; i <= 3; i = i + 1) // for (i = 0; i < T; i = i + 1)
				tau_next[i] = sigma[i];
		end
	end

	always @(posedge clk) begin
		if (!rstn) begin
			sigma[0] <= 0;
			for (i = 1; i <= 4; i = i + 1)
				sigma[i] <= 0;

			tau[0] <= 0; 
			for (i = 1; i <= 3; i = i + 1)
				tau[i] <= 0;
			
			D <= 0;
			delta <= 0; 
			Delta <= 0; 
			iteration_cnt <= 0;
		end 
		else if (BMA_first_cycle) begin
			sigma[0] <= (10'd1 << (m-1)); // sigma[0] = 1
			for (i = 1; i <= 4; i = i + 1)
				sigma[i] <= 0;

			tau[0] <= (10'd1 << (m-1)); // tau[0] = 1
			for (i = 1; i <= 3; i = i + 1)
				tau[i] <= 0;
			
			D <= 0;
			delta <= (10'd1 << (m-1)); 
			Delta <= syndromes[3]; // S1
			iteration_cnt <= 0;
		end 
		else if (BMA_start && !BMA_done) begin
			for (i = 0; i <= 4; i = i + 1)
				sigma[i] <= sigma_next[i];
			for (i = 0; i <= 3; i = i + 1)
				tau[i] <= tau_next[i];
			D <= D_next;
			delta <= delta_next;
			Delta <= Delta_next;
			iteration_cnt <= (iteration_cnt < 2*t - 1) ? iteration_cnt + 1 : 0;
		end
	end

	always @(posedge clk) begin
		if (!rstn)
			BMA_done <= 0;
		else if (BMA_start && iteration_cnt == 2*t - 1) 
			BMA_done <= 1;
		else 
			BMA_done <= 0;
	end

endmodule

module chien_search  #(
    parameter integer WAY = 8   // number of roots evaluated per cycle
)(
    input  clk,
    input  rstn,
    input  search_start,
	input [5*10-1:0] sigma_in_flat, // from BMA
	input [1:0] min_flag,
	input [9:0] min1_r_idx,
	input [9:0] min2_r_idx,
	input [3:0] m,
	input [9:0] n,
	input [2:0] t,
	output reg min1_in_err_loc,
	output reg min2_in_err_loc,
    output reg search_done,
	output reg [2:0] err_cnt, // at most 4 (t = 4) errors
	output [4*10-1:0] err_loc_flat // error location number, at most 4 (t = 4)
);
	wire [9:0] sigma_in [0:4];
	assign sigma_in[0] = sigma_in_flat[5*10-1 -: 10];
	assign sigma_in[1] = sigma_in_flat[5*10-1-10 -: 10];
	assign sigma_in[2] = sigma_in_flat[5*10-1-20 -: 10];
	assign sigma_in[3] = sigma_in_flat[5*10-1-30 -: 10];
	assign sigma_in[4] = sigma_in_flat[5*10-1-40 -: 10]; 

	reg [9:0] err_loc [0:3];
	reg [9:0] search_cnt;
	wire [9:0] eval;
	reg [9:0] alpha_i, alpha_2i, alpha_3i, alpha_4i;
	reg zero_is_root;
	integer i;

	assign err_loc_flat = {err_loc[0], err_loc[1], err_loc[2], err_loc[3]};

	wire [9:0] p_s1, p_s2, p_s3, p_s4;
	gf_mul u_eval1 (.a(sigma_in[1]), .b(alpha_i),  .m(m), .p(p_s1));
	gf_mul u_eval2 (.a(sigma_in[2]), .b(alpha_2i), .m(m), .p(p_s2));
	gf_mul u_eval3 (.a(sigma_in[3]), .b(alpha_3i), .m(m), .p(p_s3));
	gf_mul u_eval4 (.a(sigma_in[4]), .b(alpha_4i), .m(m), .p(p_s4));

	// final eval
	assign eval = sigma_in[0] ^ p_s1 ^ p_s2 ^ p_s3 ^ p_s4;

	// reg [9:0] alpha_i   [0:WAY-1];
	// reg [9:0] alpha_2i  [0:WAY-1];
	// reg [9:0] alpha_3i  [0:WAY-1];
	// reg [9:0] alpha_4i  [0:WAY-1];
	// wire [9:0] p_s1 [0:WAY-1];
	// wire [9:0] p_s2 [0:WAY-1];
	// wire [9:0] p_s3 [0:WAY-1];
	// wire [9:0] p_s4 [0:WAY-1];
	// wire [9:0] eval [0:WAY-1];
	// genvar k;
	// generate
	// 	for (k = 0; k < WAY; k = k + 1) begin : gen_eval
	// 		gf_mul u_eval1 (.a(sigma_in[1]), .b(alpha_i[k]),  .m(m), .p(p_s1[k]));
	// 		gf_mul u_eval2 (.a(sigma_in[2]), .b(alpha_2i[k]), .m(m), .p(p_s2[k]));
	// 		gf_mul u_eval3 (.a(sigma_in[3]), .b(alpha_3i[k]), .m(m), .p(p_s3[k]));
	// 		gf_mul u_eval4 (.a(sigma_in[4]), .b(alpha_4i[k]), .m(m), .p(p_s4[k]));
	// 		assign eval[k] = sigma_in[0] ^ p_s1[k] ^ p_s2[k] ^ p_s3[k] ^ p_s4[k];
	// 	end
	// endgenerate

	wire [9:0] p_ai, p_a2i, p_a3i, p_a4i;
	wire [9:0] alpha_mul1 = (10'd1 << (m-2));   // α^1
	wire [9:0] alpha_mul2 = (10'd1 << (m-3));   // α^2
	wire [9:0] alpha_mul3 = (10'd1 << (m-4));   // α^3
	wire [9:0] alpha_mul4 = (10'd1 << (m-5));   // α^4

	gf_mul u_alpha1 (.a(alpha_i),  .b(alpha_mul1), .m(m), .p(p_ai));
	gf_mul u_alpha2 (.a(alpha_2i), .b(alpha_mul2), .m(m), .p(p_a2i));
	gf_mul u_alpha3 (.a(alpha_3i), .b(alpha_mul3), .m(m), .p(p_a3i));
	gf_mul u_alpha4 (.a(alpha_4i), .b(alpha_mul4), .m(m), .p(p_a4i));

	// wire [9:0] p_ai   [0:WAY-1];
	// wire [9:0] p_a2i  [0:WAY-1];
	// wire [9:0] p_a3i  [0:WAY-1];
	// wire [9:0] p_a4i  [0:WAY-1];
	// wire [9:0] alpha_mul1 = (10'd1 << (m-2));   // α^1
	// wire [9:0] alpha_mul2 = (10'd1 << (m-3));   // α^2
	// wire [9:0] alpha_mul3 = (10'd1 << (m-4));   // α^3
	// wire [9:0] alpha_mul4 = (10'd1 << (m-5));   // α^4
	// generate
	// 	for (k = 0; k < WAY; k = k + 1) begin : gen_alpha
	// 		gf_mul u_alpha1 (.a(alpha_i[k]),  .b(alpha_mul1), .m(m), .p(p_ai[k]));
	// 		gf_mul u_alpha2 (.a(alpha_2i[k]), .b(alpha_mul2), .m(m), .p(p_a2i[k]));
	// 		gf_mul u_alpha3 (.a(alpha_3i[k]), .b(alpha_mul3), .m(m), .p(p_a3i[k]));
	// 		gf_mul u_alpha4 (.a(alpha_4i[k]), .b(alpha_mul4), .m(m), .p(p_a4i[k]));
	// 	end
	// endgenerate

	wire find_min = (min_flag == 2'd1 && (n - search_cnt) == min2_r_idx) ||
					(min_flag == 2'd2 && (n - search_cnt) == min1_r_idx) ||
					(min_flag == 2'd3 && ((n - search_cnt) == min1_r_idx || (n - search_cnt) == min2_r_idx));

	always @(posedge clk) begin
		if (!rstn) begin
			for (i = 0; i < 4; i = i + 1)
				err_loc[i] <= 10'd1023;
			search_cnt <= 0;
			alpha_i  <= 0;
			alpha_2i <= 0;
			alpha_3i <= 0;
			alpha_4i <= 0;
			// for (i = 0; i < 4; i = i + 1) begin
			// 	alpha_i[i]  <= 0;
			// 	alpha_2i[i] <= 0;
			// 	alpha_3i[i] <= 0;
			// 	alpha_4i[i] <= 0;
			// end
			err_cnt <= 0;
			search_done <= 0;
			zero_is_root <= 0;
			min1_in_err_loc <= 0;
			min2_in_err_loc <= 0;
		end
		else if (search_start) begin
			for (i = 0; i < 4; i = i + 1)
				err_loc[i] <= 10'd1023;
			search_cnt <= 0;
			alpha_i  <= (10'd1 << (m-1)); // α^0 = 1
			alpha_2i <= (10'd1 << (m-1)); // α^0 = 1
			alpha_3i <= (10'd1 << (m-1)); // α^0 = 1
			alpha_4i <= (10'd1 << (m-1)); // α^0 = 1
			// alpha_i[0] <= (10'd1 << (m-1));
			// alpha_2i[0] <= (10'd1 << (m-1));
			// alpha_3i[0] <= (10'd1 << (m-1));
			// alpha_4i[0] <= (10'd1 << (m-1));
			// alpha_i[1] <= (10'd1 << (m-2));  // α^1
			// alpha_2i[1] <= (10'd1 << (m-3)); // α^2
			// alpha_3i[1] <= (10'd1 << (m-4)); // α^3
			// alpha_4i[1] <= (10'd1 << (m-5)); // α^4
			// alpha_i[2] <= (10'd1 << (m-3));  // α^2
			// alpha_2i[2] <= (10'd1 << (m-5)); // α^4
			// alpha_3i[2] <= (m == 6) ? 10'b110000 : (m == 8) ? 10'b00000010 : 10'b0000001000; // α^6
			// alpha_4i[2] <= (m == 6) ? 10'b001100 : (m == 8) ? 10'b10111000 : 10'b0000000010; // α^8
			// alpha_i[3] <= (10'd1 << (m-4)); // α^3
			// alpha_2i[3] <= (m == 6) ? 10'b110000 : (m == 8) ? 10'b00000010 : 10'b0000001000; // α^6
			// alpha_3i[3] <= (m == 6) ? 10'b000110 : (m == 8) ? 10'b01011100 : 10'b0000000001; // α^9
			// alpha_4i[3] <= (m == 6) ? 10'b101000 : (m == 8) ? 10'b10110011 : 10'b0010010000; // α^12

			err_cnt <= 0;
			search_done <= 0;
			zero_is_root <= 0;
			min1_in_err_loc <= 0;
			min2_in_err_loc <= 0;
		end
		else if (eval == 0 && !search_done) begin // For i = 1 to n-1, if σ(α^i) == 0, then 63-i is an error location number
			// Corner case: for i = 0, σ(α^0) == 0, then 0 is an error location number
			zero_is_root <= (search_cnt == 0) ? 1 : zero_is_root;

			if (find_min) begin
				for (i = 0; i < 4; i = i + 1)
					err_loc[i] <= err_loc[i]; // do not update err_loc if it matches min locations

				case (min_flag)
					2'd0: begin 
						min1_in_err_loc <= 0; 
						min2_in_err_loc <= 0;
					end
					2'd1: begin
						min1_in_err_loc <= 0;
						min2_in_err_loc <= 1;
					end
					2'd2: begin
						min1_in_err_loc <= 1;
						min2_in_err_loc <= 0;
					end
					2'd3: begin
						if ((n - search_cnt) == min1_r_idx) begin
							min1_in_err_loc <= 1;
							min2_in_err_loc <= min2_in_err_loc;
						end
						else begin // (n - search_cnt) == min2_r_idx
							min1_in_err_loc <= min1_in_err_loc;
							min2_in_err_loc <= 1;
						end
					end
				endcase
			end
			else if (zero_is_root) begin // 0 must be placed at err_loc[0], so other roots can only be placed at err_loc[1], err_loc[2], err_loc[3]
				err_loc[1] <= n - search_cnt;
				for (i = 2; i < 4; i = i + 1)
					err_loc[i] <= err_loc[i-1];
			end
			else begin
				err_loc[0] <= (search_cnt == 0) ? 0 : (n - search_cnt);
				for (i = 1; i < 4; i = i + 1)
					err_loc[i] <= err_loc[i-1];
			end	
			
			search_cnt <= search_cnt + 1;
			alpha_i  <= p_ai;  // α^i * α = α^(i+1)
			alpha_2i <= p_a2i; // α^(2i) * α^2 = α^(2(i+1))
			alpha_3i <= p_a3i; // α^(3i) * α^3 = α^(3(i+1))
			alpha_4i <= p_a4i; // α^(4i) * α^4 = α^(4(i+1))
			err_cnt <= err_cnt + 1;
			search_done <= (err_cnt == t-1 || search_cnt == n-1) ? 1 : 0;
		end
		else begin
			search_cnt <= search_cnt + 1;
			alpha_i  <= p_ai;  // α^i * α = α^(i+1)
			alpha_2i <= p_a2i; // α^(2i) * α^2 = α^(2(i+1))
			alpha_3i <= p_a3i; // α^(3i) * α^3 = α^(3(i+1))
			alpha_4i <= p_a4i; // α^(4i) * α^4 = α^(4(i+1))
			search_done <= (search_cnt == n-1) ? 1 : search_done;
		end
	end
endmodule

module gf_mul (
    input  [9:0] a,
    input  [9:0] b,
    input  [3:0] m, // runtime select: 6, 8, or 10
    output [9:0] p
);
    // ------------- GF(2^6) multiplier -------------
    wire [5:0] gf6_p;

    assign gf6_p = ({6{b[5]}} & a[5:0]) 
					^ ({6{b[4]}} & {a[0], a[5] ^ a[0], a[4], a[3], a[2], a[1]}) 
					^ ({6{b[3]}} & {a[1], a[0] ^ a[1], a[5] ^ a[0], a[4], a[3], a[2]})
					^ ({6{b[2]}} & {a[2], a[1] ^ a[2], a[0] ^ a[1], a[5] ^ a[0], a[4], a[3]}) 
					^ ({6{b[1]}} & {a[3], a[2] ^ a[3], a[1] ^ a[2], a[0] ^ a[1], a[5] ^ a[0], a[4]}) 
					^ ({6{b[0]}} & {a[4], a[3] ^ a[4], a[2] ^ a[3], a[1] ^ a[2], a[0] ^ a[1], a[5] ^ a[0]});

    // Extend to 10 bits
    wire [9:0] gf6_p_ext = {4'b0, gf6_p};

    // ------------- GF(2^8) multiplier -------------
    wire [7:0] gf8_row [0:7];
    wire [7:0] gf8_p;

	// row[0] = a * α^0
    assign gf8_row[0] = a[7:0];
	// row[1] = a * α^1
	assign gf8_row[1] = {a[0], a[7], a[6] ^ a[0], a[5] ^ a[0], a[4] ^ a[0], a[3], a[2], a[1]};
	// row[2] = a * α^2
	assign gf8_row[2] = {a[1], a[0], a[7] ^ a[1], a[6] ^ a[0] ^ a[1], a[5] ^ a[0] ^ a[1], a[4] ^ a[0], a[3], a[2]};
	// row[3] = a * α^3 
	assign gf8_row[3] = {a[2], a[1], a[0] ^ a[2], a[7] ^ a[1] ^ a[2], a[6] ^ a[0] ^ a[1] ^ a[2], 
							a[5] ^ a[0] ^ a[1], a[4] ^ a[0], a[3]};
	// row[4] = a * α^4 
	assign gf8_row[4] = {a[3], a[2], a[1] ^ a[3], a[0] ^ a[2] ^ a[3], a[7] ^ a[1] ^ a[2] ^ a[3], 
							a[6] ^ a[0] ^ a[1] ^ a[2], a[5] ^ a[0] ^ a[1], a[4] ^ a[0]};
	// row[5] = a * α^5 
	assign gf8_row[5] = {a[4] ^ a[0], a[3], a[2] ^ a[4] ^ a[0], a[1] ^ a[3] ^ a[4] ^ a[0], a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[0], 
							a[7] ^ a[1] ^ a[2] ^ a[3], a[6] ^ a[0] ^ a[1] ^ a[2], a[5] ^ a[0] ^ a[1]};
	// row[6] = a * α^6 
	assign gf8_row[6] = {a[5] ^ a[0] ^ a[1], a[4] ^ a[0], a[3] ^ a[5] ^ a[0] ^ a[1], a[2] ^ a[4] ^ a[0] ^ a[5] ^ a[0] ^ a[1], a[1] ^ a[3] ^ a[4] ^ a[0] ^ a[5] ^ a[0] ^ a[1], 
							a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[0], a[7] ^ a[1] ^ a[2] ^ a[3], a[6] ^ a[0] ^ a[1] ^ a[2]};
	// row[7] = a * α^7 
	assign gf8_row[7] = {a[6] ^ a[0] ^ a[1] ^ a[2], a[5] ^ a[0] ^ a[1], a[4] ^ a[0] ^ a[6] ^ a[0] ^ a[1] ^ a[2], a[3] ^ a[5] ^ a[0] ^ a[1] ^ a[6] ^ a[0] ^ a[1] ^ a[2], 
							a[2] ^ a[4] ^ a[0] ^ a[5] ^ a[0] ^ a[1] ^ a[6] ^ a[0] ^ a[1] ^ a[2], 
							a[1] ^ a[3] ^ a[4] ^ a[0] ^ a[5] ^ a[0] ^ a[1], a[0] ^ a[2] ^ a[3] ^ a[4] ^ a[0], a[7] ^ a[1] ^ a[2] ^ a[3]};

	assign gf8_p = ({8{b[7]}} & gf8_row[0]) ^ ({8{b[6]}} & gf8_row[1]) ^ ({8{b[5]}} & gf8_row[2])
					^ ({8{b[4]}} & gf8_row[3]) ^ ({8{b[3]}} & gf8_row[4]) ^ ({8{b[2]}} & gf8_row[5])
					^ ({8{b[1]}} & gf8_row[6]) ^ ({8{b[0]}} & gf8_row[7]);


	wire [9:0] gf8_p_ext = {2'b0, gf8_p};

    // ------------- GF(2^10) multiplier -------------
    wire [9:0] gf10_row [0:9];
    wire [9:0] gf10_p;

	// row[0] = a * α^0
    assign gf10_row[0] = a;
	// row[1] = a * α^1
    assign gf10_row[1] = {a[0], a[9], a[8], a[7] ^ a[0], a[6], a[5], a[4], a[3], a[2], a[1]};
	// row[2] = a * α^2
    assign gf10_row[2] = {a[1], a[0], a[9], a[8] ^ a[1], a[7] ^ a[0], a[6], a[5], a[4], a[3], a[2]};
	// row[3] = a * α^3
    assign gf10_row[3] = {a[2], a[1], a[0], a[9] ^ a[2], a[8] ^ a[1], a[7] ^ a[0], a[6], a[5], a[4], a[3]};
	// row[4] = a * α^4
    assign gf10_row[4] = {a[3], a[2], a[1], a[0] ^ a[3], a[9] ^ a[2], a[8] ^ a[1], a[7] ^ a[0], a[6], a[5], a[4]};
	// row[5] = a * α^5
    assign gf10_row[5] = {a[4], a[3], a[2], a[1] ^ a[4], a[0] ^ a[3], a[9] ^ a[2], a[8] ^ a[1], a[7] ^ a[0], a[6], a[5]};
	// row[6] = a * α^6
    assign gf10_row[6] = {a[5], a[4], a[3], a[2] ^ a[5], a[1] ^ a[4], a[0] ^ a[3], a[9] ^ a[2], a[8] ^ a[1], a[7] ^ a[0], a[6]};
	// row[7] = a * α^7
    assign gf10_row[7] = {a[6], a[5], a[4], a[3] ^ a[6], a[2] ^ a[5], a[1] ^ a[4], a[0] ^ a[3], a[9] ^ a[2], a[8] ^ a[1], a[7] ^ a[0]};
	// row[8] = a * α^8
    assign gf10_row[8] = {a[7] ^ a[0], a[6], a[5], a[4] ^ a[7] ^ a[0], a[3] ^ a[6], a[2] ^ a[5], a[1] ^ a[4], a[0] ^ a[3], a[9] ^ a[2], a[8] ^ a[1]};
	// row[9] = a * α^9
    assign gf10_row[9] = {a[8] ^ a[1], a[7] ^ a[0], a[6], a[5] ^ a[8] ^ a[1], a[4] ^ a[7] ^ a[0], a[3] ^ a[6], a[2] ^ a[5], a[1] ^ a[4], a[0] ^ a[3], a[9] ^ a[2]};

	assign gf10_p = ({10{b[9]}} & gf10_row[0]) ^ ({10{b[8]}} & gf10_row[1]) ^ ({10{b[7]}} & gf10_row[2])
					^ ({10{b[6]}} & gf10_row[3]) ^ ({10{b[5]}} & gf10_row[4]) ^ ({10{b[4]}} & gf10_row[5])
					^ ({10{b[3]}} & gf10_row[6]) ^ ({10{b[2]}} & gf10_row[7]) ^ ({10{b[1]}} & gf10_row[8]) ^ ({10{b[0]}} & gf10_row[9]);

    assign p = (m == 6) ? gf6_p_ext :
        	   (m == 8) ? gf8_p_ext : gf10_p;

endmodule