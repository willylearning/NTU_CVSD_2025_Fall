module alu #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                      i_clk,
    input                      i_rst_n,

    input                      i_in_valid,
    output                     o_busy,
    input         [INST_W-1:0] i_inst,
    input  signed [DATA_W-1:0] i_data_a,
    input  signed [DATA_W-1:0] i_data_b,

    output                     o_out_valid,
    output        [DATA_W-1:0] o_data
);
    // Parameters
    parameter RESET = 2'b00, READY = 2'b01, CALC  = 2'b10, DONE  = 2'b11;

// Wires & Regs
    // FSM state
    reg [1:0] state, next_state;
    // Input
    reg [INST_W-1:0] i_inst_r, i_inst_w;
    reg signed [DATA_W-1:0] i_data_a_r, i_data_a_w;
    reg signed [DATA_W-1:0] i_data_b_r, i_data_b_w;
    // Output
    reg o_busy_r, o_busy_w;
    reg o_out_valid_r, o_out_valid_w;
    reg [DATA_W-1:0] o_data_r, o_data_w;
    // matrix_input_cnt
    reg [3:0] matrix_input_cnt;
    reg [3:0] matrix_output_cnt;

    // FSM state transition
    always @(*) begin
        case (state)
            RESET: next_state = READY;
            READY: next_state = i_in_valid ? CALC : READY;
            CALC:  next_state = DONE;
            DONE:  begin 
                if (i_inst_r == 4'b1001 && matrix_input_cnt == 4'd8 && matrix_output_cnt <= 4'd7)
                    next_state = DONE; // Stay in DONE state to receive more input for Matrix Transpose
                else
                    next_state = READY;
            end
        endcase
    end

    // o_busy_r & o_out_valid_r
    always @(*) begin
        case (state)
            RESET: begin
                o_busy_w = 0;
                o_out_valid_w = 0;
            end
            READY: begin
                // o_busy_w = 0; // Set low if ready for next input data
                o_busy_w = i_in_valid; // i_in_valid will be randomly pulled high only if o_busy is low
                o_out_valid_w = 0;
            end
            CALC: begin
                o_busy_w = 1; // Set high to pause input sequence
                o_out_valid_w = 1; // Set high if ready to output result
                if (i_inst_r == 4'b1001) begin
                    o_out_valid_w = 0; // Do not output result until all 8 rows are received 
                end
                // else begin  
                //     o_out_valid_w = 1; // Set high if ready to output result
                // end
            end
            DONE: begin
                // o_busy_w = 1;
                if (i_inst_r == 4'b1001 && matrix_input_cnt == 4'd8 && matrix_output_cnt >= 4'd0 && matrix_output_cnt < 4'd8) begin
                    o_out_valid_w = 1; // Set high if ready to output result
                    o_busy_w = 1;
                end
                else begin
                    o_out_valid_w = 0;
                    o_busy_w = 0; // Set low if ready for next input data
                end
            end
        endcase
    end

    localparam signed ONE_SIXTH = 16'd171; // (1/6) * 2^10 = 171
    localparam signed ONE_HUNDRED_TWENTIETH = 16'd9; // (1/120) * 2^10 = 9

    // Instructions
    integer i, j;
    // For signed addition & subtraction
    reg signed [DATA_W:0] add_result; // need one more bit for overflow detection
    reg signed [DATA_W:0] sub_result; // need one more bit for overflow detection
    // For signed MAC
    reg signed [36:0] data_acc, next_data_acc; // Q16.20, need one more bit for overflow detection
    reg signed [36:0] mac_result; // Q16.20, need one more bit for overflow detection
    reg signed [27:0] tmp; // Q16.10, need one more bit for overflow detection
    // For Taylor expansion of sin function
    reg signed [31:0] a2;   // Q12.20
    reg signed [47:0] a3;   // Q18.30
    reg signed [79:0] a5;   // Q30.50
    reg signed [63:0] term3; // Q18.30 * Q6.10 = Q24.40
    reg signed [95:0] term5; // Q30.50 * Q6.10 = Q36.60
    reg signed [95:0] i_data_a_aligned; // Q36.60
    reg signed [95:0] term3_aligned; // Q36.60
    reg signed [96:0] sin_a; // Q36.60, need one more bit for overflow detection
    reg signed [47:0] sin_a_rounded; // need one more bit for overflow detection
    // For LRCW
    reg [4:0] cpop;
    // For Right Rotation
    reg [2*DATA_W-1:0] concatenated;
    // For Count Leading Zeros
    reg [4:0] clz;
    reg found_one;
    // For Matrix Transpose
    reg [15:0] output_matrix [0:7]; // output 8 rows of 16 bits each

    always @(*) begin
        o_data_w = 0;
        next_data_acc = data_acc;
        case (i_inst_r)
            4'b0000: begin // Signed Addition
                // reg signed [DATA_W:0] add_result; // need one more bit for overflow detection
                add_result = i_data_a_r + i_data_b_r;
                // Saturation
                if (add_result > 32767) // positive overflow -> maximum = 2^15 - 1
                    o_data_w = 32767; 
                else if (add_result < -32768) // negative overflow -> minimum = -2^15
                    o_data_w = -32768; 
                else
                    o_data_w = add_result[DATA_W-1:0];
            end
            4'b0001: begin // Signed Subtraction
                // reg signed [DATA_W:0] sub_result; // need one more bit for overflow detection
                sub_result = i_data_a_r - i_data_b_r;
                // Saturation
                if (sub_result > 32767) // positive overflow -> maximum
                    o_data_w = 32767; 
                else if (sub_result < -32768) // negative overflow -> minimum
                    o_data_w = -32768; 
                else
                    o_data_w = sub_result[DATA_W-1:0];
            end
            4'b0010: begin // Signed MAC
                // reg signed [36:0] data_acc, next_data_acc; // Q16.20
                // reg signed [36:0] mac_result; // Q16.20
                // reg signed [27:0] tmp; // need one more bit for overflow detection
                next_data_acc = data_acc + i_data_a_r * i_data_b_r; 
                mac_result = next_data_acc;
            
                // Saturation for next_data_acc
                if (next_data_acc > 36'sh7_FFFF_FFFF)
                    next_data_acc = 36'sh7_FFFF_FFFF;
                else if (next_data_acc < 36'sh8_0000_0000)
                    next_data_acc = 36'sh8_0000_0000;

                // Rounding to nearest, round Q16.20 to Q16.10
                tmp = $signed(mac_result[36:10] + mac_result[9]); // if (mac_result[9] == 1'b1) then round up
                
                // Saturation
                if (tmp >= 32767)
                    o_data_w = 32767;
                else if (tmp <= -32768)
                    o_data_w = -32768;
                else
                    o_data_w = $signed(tmp[15:0]); 
            end
            4'b0011: begin // Taylor Expansion of Sin Function
                // i_data_a_r is Q6.10
                // reg signed [31:0] a2;   // Q12.20
                // reg signed [47:0] a3;   // Q18.30
                // reg signed [79:0] a5;   // Q30.50
                // reg signed [63:0] term3; // Q18.30 * Q6.10 = Q24.40
                // reg signed [95:0] term5; // Q30.50 * Q6.10 = Q36.60
                // reg signed [95:0] i_data_a_aligned; // Q36.60
                // reg signed [95:0] term3_aligned; // Q36.60
                // reg signed [96:0] sin_a; // Q36.60, need one more bit for overflow detection
                // reg signed [47:0] sin_a_rounded; // need one more bit for overflow detection

                a2 = i_data_a_r * i_data_a_r; // Q12.20
                a3 = a2 * i_data_a_r; // Q18.30
                a5 = a3 * a2; // Q30.50

                term3 = a3 * ONE_SIXTH; 
                term5 = a5 * ONE_HUNDRED_TWENTIETH; 
                i_data_a_aligned = {{30{i_data_a_r[15]}}, i_data_a_r, {50{1'b0}}}; // Q36.60
                term3_aligned = {{12{term3[63]}}, term3, {20{1'b0}}}; // Q36.60

                sin_a = i_data_a_aligned - term3_aligned + term5; // Q37.60

                // Rounding to nearest, round Q37.60 to Q30.10
                sin_a_rounded = $signed(sin_a[96:50] + sin_a[49]); // if (sin_a[49] == 1'b1) then round up

                // Saturation
                if (sin_a_rounded >= 32767)
                    o_data_w = 32767;
                else if (sin_a_rounded <= -32768)
                    o_data_w = -32768;
                else
                    o_data_w = $signed(sin_a_rounded[15:0]);
            end
            4'b0100: begin // Binary to Gray Code
                for (i = 0; i < DATA_W-1; i = i + 1) begin
                    o_data_w[i] = i_data_a_r[i+1] ^ i_data_a_r[i];
                end
                o_data_w[DATA_W-1] = i_data_a_r[DATA_W-1];
            end
            4'b0101: begin // LRCW
                // reg [4:0] cpop;
                cpop = i_data_a_r[0] + i_data_a_r[1] + i_data_a_r[2] + i_data_a_r[3] +
                       i_data_a_r[4] + i_data_a_r[5] + i_data_a_r[6] + i_data_a_r[7] +
                       i_data_a_r[8] + i_data_a_r[9] + i_data_a_r[10] + i_data_a_r[11] +
                       i_data_a_r[12] + i_data_a_r[13] + i_data_a_r[14] + i_data_a_r[15];
                for (i = 0; i < DATA_W; i = i + 1) begin
                    if (i < DATA_W - cpop)
                        o_data_w[i + cpop] = i_data_b_r[i]; // Left rotation's part
                    else
                        o_data_w[i - (DATA_W - cpop)] = ~i_data_b_r[i]; // Complement-on-warp part
                end
            end
            4'b0110: begin // Right Rotation
                // reg [2*DATA_W-1:0] concatenated;
                concatenated = {i_data_a_r, i_data_a_r};
                if (i_data_b_r >= DATA_W)
                    o_data_w = i_data_a_r; 
                else
                    o_data_w = concatenated[i_data_b_r[3:0] +: DATA_W];
            end
            4'b0111: begin // Count Leading Zeros
                // reg [4:0] clz;
                clz = 5'd16; // Default value if all bits are zero
                found_one = 1'b0;
                begin : clz_loop
                    for (i = 15; i >= 0; i = i - 1) begin
                        if (found_one == 1'b0) begin
                            if (i_data_a_r[i] == 1'b1) begin
                                clz = 15 - i;
                                found_one = 1'b1;
                            end
                        end
                    end
                end
                o_data_w = clz;
            end
            4'b1000: begin // Reverse Match4
                for (i = 0; i < 13; i = i + 1) begin
                    o_data_w[i] = (i_data_a_r[i +: 4] == i_data_b_r[(15-i) -: 4]);
                end
            end
            4'b1001: begin // Matrix Transpose
                // reg [15:0] output_matrix [0:7]; // output 8 rows of 16 bits each
                if (state == DONE && matrix_input_cnt == 4'd8) begin
                    o_data_w = (matrix_output_cnt < 4'd8) ? output_matrix[matrix_output_cnt[2:0]] : 0;
                end
                else begin
                    o_data_w = 0;
                end
            end
            default: begin
                o_data_w = 0;
            end
        endcase
    end

    // Sequential logic for state
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state <= RESET;
        end
        else begin
            state <= next_state;
        end
    end

    // Sequential logic for input 
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            i_inst_r <= 0;
            i_data_a_r <= 0;
            i_data_b_r <= 0;
        end
        else begin
            i_inst_r <= (state == READY && i_in_valid) ? i_inst : i_inst_r;
            i_data_a_r <= (state == READY && i_in_valid) ? i_data_a : i_data_a_r;
            i_data_b_r <= (state == READY && i_in_valid) ? i_data_b : i_data_b_r;
        end
    end

    // Sequential logic for output
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_busy_r <= 0;
            o_out_valid_r <= 0;
            o_data_r <= 0;
        end
        else begin
            o_busy_r <= o_busy_w;
            o_out_valid_r <= o_out_valid_w;
            o_data_r <= o_data_w;
            // o_data_r <= (matrix_input_cnt == 4'd8) ? output_matrix[matrix_output_cnt] : o_data_w;
        end
    end

    // Sequential logic for data_acc
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            data_acc <= 0;
        end
        else begin
            data_acc <= (state == CALC && i_inst_r == 4'b0010) ? next_data_acc : data_acc;
            // data_acc <= next_data_acc;
        end
    end

    // Sequential logic for matrix_input_cnt
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            matrix_input_cnt <= 0;
        end
        else if (state == CALC && i_inst_r == 4'b1001) begin
            matrix_input_cnt <= matrix_input_cnt + 1;
        end
        else if (state == DONE && matrix_output_cnt == 4'd8) begin // Reset counter after outputting all 8 rows
            matrix_input_cnt <= 0;
        end
    end

    // Sequential logic for matrix_output_cnt
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            matrix_output_cnt <= 0;
        end
        else if (state == DONE && matrix_input_cnt == 4'd8 && matrix_output_cnt < 4'd8) begin
            matrix_output_cnt <= matrix_output_cnt + 1;
        end
        else if (state == DONE && matrix_input_cnt == 4'd8 && matrix_output_cnt == 4'd8) begin
            matrix_output_cnt <= 0;
        end
    end

    // Sequential logic for output_matrix
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                output_matrix[i] <= 0;
        end
        else if (state == CALC && i_inst_r == 4'b1001) begin
            // output_matrix[0][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[15:14];
            // output_matrix[1][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[13:12];
            // output_matrix[2][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[11:10];
            // output_matrix[3][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[9:8];
            // output_matrix[4][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[7:6];
            // output_matrix[5][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[5:4];
            // output_matrix[6][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[3:2];
            // output_matrix[7][15 - matrix_input_cnt*2 -: 2] = i_data_a_r[1:0];
            for (i = 0; i < 8; i = i + 1) begin
                output_matrix[i][15 - matrix_input_cnt*2 -: 2] <= i_data_a_r[(15 - i*2) -: 2];
            end
        end
    end

    // Output assignment 
    assign o_busy = o_busy_r;
    assign o_out_valid = o_out_valid_r;
    assign o_data = o_data_r;

endmodule
