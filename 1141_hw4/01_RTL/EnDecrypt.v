module EnDecrypt (
    input          clk,
    input          rst,
    input          first_data_in_flag,
    input          decrypt_mode,       // 0: Encrypt, 1: Decrypt
    // input    [3:0] round,
    input  [127:0] iot_data_crc,   
    input  [127:0] data_in,            // data_in[127:64] is main key, data_in[63:0] is plaintext
    output [127:0] data_out,           // data_out[127:64] is main key, data_out[63:0] is ciphertext
    output         done
);
    // reg [63:0] plaintext;
    wire [63:0] ciphertext;
    wire [63:0] init_permutation_out;

    reg [3:0] round; // round = 0~15
    wire [55:0] first_cipher_key;
    reg [55:0] cipher_key_w, cipher_key_r;                   
    reg [31:0] L_r, R_r, L_s, R_s; // left and right halves of data
    reg [47:0] K_round;            // current sub-key K
    reg [31:0] F_out; // F function output
    reg done_r;

    assign first_cipher_key = PC1(data_in[127:64]);
    assign init_permutation_out = init_permutation(data_in[63:0]);

    assign ciphertext = final_permutation({L_s ^ F_out, R_s}); // In the next cycle of round = 15, the correct ciphertext is assigned
    assign data_out = {iot_data_crc[127:64], ciphertext};
    assign done = done_r;

//------------------------------------------------------
// Combinational Logic
//------------------------------------------------------
    always @(*) begin
        //------------------------------------------------------
        // Sub-key Generator
        //------------------------------------------------------
        // If encrypt => circular shift left, else if decrypt => circular shift right
        // For encryption, circular left shift one bit in rounds {1,2,9,16} and two bit in all other rounds
        // For decryption, no shift in round {1}, circular right shift one bit in rounds {2,9,16} and two bit in all other rounds
        if (round == 0)
            cipher_key_w = (!decrypt_mode) ? {first_cipher_key[54:28], first_cipher_key[55], first_cipher_key[26:0], first_cipher_key[27]} : first_cipher_key;
        else if (round == 1 || round == 8 || round == 15) 
            cipher_key_w = (!decrypt_mode) ? {cipher_key_r[54:28], cipher_key_r[55], cipher_key_r[26:0], cipher_key_r[27]} : {cipher_key_r[28], cipher_key_r[55:29], cipher_key_r[0], cipher_key_r[27:1]};
        else
            cipher_key_w = (!decrypt_mode) ? {cipher_key_r[53:28], cipher_key_r[55:54], cipher_key_r[25:0], cipher_key_r[27:26]} : {cipher_key_r[29:28], cipher_key_r[55:30], cipher_key_r[1:0], cipher_key_r[27:2]};

        // Generate sub-key K for current round
        K_round = PC2(cipher_key_w);

        //------------------------------------------------------
        // Details Of Each Round
        //------------------------------------------------------
        L_s = (round == 0) ? init_permutation_out[63:32] : L_r;
        R_s = (round == 0) ? init_permutation_out[31:0] : R_r;
        // {L_s, R_s} = (round == 0) ? init_permutation(data_in[63:0]) : {L_r, R_r};
    end

    F_function u_f(.R(R_s), .K(K_round), .F(F_out));

//------------------------------------------------------
// Sequential Logic
//------------------------------------------------------
    // Update round, L_r, R_r, cipher_key_r, done_r, plaintext
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            cipher_key_r <= 0;
            L_r <= 0; 
            R_r <= 0;
            done_r <= 0;
        end 
        else begin
            round <= (first_data_in_flag) ? round + 1 : round; // 15 + 1 -> 0 due to overflow
            cipher_key_r <= cipher_key_w;
            // L_r <= (round == 15) ? L_s ^ F_out : R_s;
            // R_r <= (round == 15) ? R_s : L_s ^ F_out;
            L_r <= R_s;
            R_r <= L_s ^ F_out;
            done_r <= (round == 14);
        end
    end

    //------------------------------------------------------
    // LUT
    //------------------------------------------------------
    // Initial Permutation LUT
    function automatic [63:0] init_permutation;
        input [63:0] plaintext;
        begin
            init_permutation = {
                plaintext[6],  plaintext[14], plaintext[22], plaintext[30], plaintext[38], plaintext[46], plaintext[54], plaintext[62],
                plaintext[4],  plaintext[12], plaintext[20], plaintext[28], plaintext[36], plaintext[44], plaintext[52], plaintext[60],
                plaintext[2],  plaintext[10], plaintext[18], plaintext[26], plaintext[34], plaintext[42], plaintext[50], plaintext[58],
                plaintext[0],  plaintext[8],  plaintext[16], plaintext[24], plaintext[32], plaintext[40], plaintext[48], plaintext[56],
                plaintext[7],  plaintext[15], plaintext[23], plaintext[31], plaintext[39], plaintext[47], plaintext[55], plaintext[63],
                plaintext[5],  plaintext[13], plaintext[21], plaintext[29], plaintext[37], plaintext[45], plaintext[53], plaintext[61],
                plaintext[3],  plaintext[11], plaintext[19], plaintext[27], plaintext[35], plaintext[43], plaintext[51], plaintext[59],
                plaintext[1],  plaintext[9],  plaintext[17], plaintext[25], plaintext[33], plaintext[41], plaintext[49], plaintext[57]
            };
        end
    endfunction

    // Final Permutation LUT
    function automatic [63:0] final_permutation;
        input [63:0] data_in;
        begin
            final_permutation = {
                data_in[24], data_in[56], data_in[16], data_in[48], data_in[8],  data_in[40], data_in[0],  data_in[32],
                data_in[25], data_in[57], data_in[17], data_in[49], data_in[9],  data_in[41], data_in[1],  data_in[33],
                data_in[26], data_in[58], data_in[18], data_in[50], data_in[10], data_in[42], data_in[2],  data_in[34],
                data_in[27], data_in[59], data_in[19], data_in[51], data_in[11], data_in[43], data_in[3],  data_in[35],
                data_in[28], data_in[60], data_in[20], data_in[52], data_in[12], data_in[44], data_in[4],  data_in[36],
                data_in[29], data_in[61], data_in[21], data_in[53], data_in[13], data_in[45], data_in[5],  data_in[37],
                data_in[30], data_in[62], data_in[22], data_in[54], data_in[14], data_in[46], data_in[6],  data_in[38],
                data_in[31], data_in[63], data_in[23], data_in[55], data_in[15], data_in[47], data_in[7],  data_in[39]
            };
        end
    endfunction

    // PC1 LUT
    function automatic [55:0] PC1;
        input [63:0] key_in;
        begin
            PC1 = {
                key_in[7],  key_in[15], key_in[23], key_in[31], key_in[39], key_in[47], key_in[55], key_in[63],
                key_in[6],  key_in[14], key_in[22], key_in[30], key_in[38], key_in[46], key_in[54], key_in[62],
                key_in[5],  key_in[13], key_in[21], key_in[29], key_in[37], key_in[45], key_in[53], key_in[61],
                key_in[4],  key_in[12], key_in[20], key_in[28], key_in[1],  key_in[9],  key_in[17], key_in[25],
                key_in[33], key_in[41], key_in[49], key_in[57], key_in[2],  key_in[10], key_in[18], key_in[26],
                key_in[34], key_in[42], key_in[50], key_in[58], key_in[3],  key_in[11], key_in[19], key_in[27],
                key_in[35], key_in[43], key_in[51], key_in[59], key_in[36], key_in[44], key_in[52], key_in[60]
            };
        end
    endfunction

    // PC2 LUT
    function automatic [47:0] PC2;
        input [55:0] key_in;
        begin
            PC2 = {
                key_in[42], key_in[39], key_in[45], key_in[32], key_in[55], key_in[51], key_in[53], key_in[28],
                key_in[41], key_in[50], key_in[35], key_in[46], key_in[33], key_in[37], key_in[44], key_in[52],
                key_in[30], key_in[48], key_in[40], key_in[49], key_in[29], key_in[36], key_in[43], key_in[54],
                key_in[15], key_in[4],  key_in[25], key_in[19], key_in[9],  key_in[1],  key_in[26], key_in[16],
                key_in[5],  key_in[11], key_in[23], key_in[8],  key_in[12], key_in[7],  key_in[17], key_in[0],
                key_in[22], key_in[3],  key_in[10], key_in[14], key_in[6],  key_in[20], key_in[27], key_in[24]
            };
        end
    endfunction
endmodule

// F function module
module F_function (
    input  [31:0] R,        // right half (32-bit)
    input  [47:0] K,        // subkey (48-bit)
    output [31:0] F         // result after S-boxes + P-permutation
);
    // Expansion and XOR with sub-key K
    wire [47:0] E = {R[0],  R[31], R[30], R[29], R[28], R[27],
                     R[28], R[27], R[26], R[25], R[24], R[23],
                     R[24], R[23], R[22], R[21], R[20], R[19],
                     R[20], R[19], R[18], R[17], R[16], R[15],
                     R[16], R[15], R[14], R[13], R[12], R[11],
                     R[12], R[11], R[10], R[9],  R[8],  R[7],
                     R[8],  R[7],  R[6],  R[5],  R[4],  R[3],
                     R[4],  R[3],  R[2],  R[1],  R[0],  R[31]};

    wire [47:0] X  = E ^ K;

    // Slice into 8 groups of 6-bit for S-boxes
    wire [5:0] S1_in = X[47:42];
    wire [5:0] S2_in = X[41:36];
    wire [5:0] S3_in = X[35:30];
    wire [5:0] S4_in = X[29:24];
    wire [5:0] S5_in = X[23:18];
    wire [5:0] S6_in = X[17:12];
    wire [5:0] S7_in = X[11:6];
    wire [5:0] S8_in = X[5:0];

    wire [3:0] S1_out, S2_out, S3_out, S4_out, S5_out, S6_out, S7_out, S8_out;

    // S-box layer
    S_boxes u_sboxes(
        .S1_in(S1_in), .S2_in(S2_in), .S3_in(S3_in), .S4_in(S4_in), .S5_in(S5_in), .S6_in(S6_in), .S7_in(S7_in), .S8_in(S8_in),
        .S1_out(S1_out), .S2_out(S2_out), .S3_out(S3_out), .S4_out(S4_out), .S5_out(S5_out), .S6_out(S6_out), .S7_out(S7_out), .S8_out(S8_out)
    );

    // Use P LUT to obtain F function output
    wire [31:0] S_concat = {S1_out, S2_out, S3_out, S4_out, S5_out, S6_out, S7_out, S8_out};
    assign F = {S_concat[16], S_concat[25], S_concat[12], S_concat[11], S_concat[3],  S_concat[20], S_concat[4],  S_concat[15],
                S_concat[31], S_concat[17], S_concat[9],  S_concat[6],  S_concat[27], S_concat[14], S_concat[1],  S_concat[22],
                S_concat[30], S_concat[24], S_concat[8],  S_concat[18], S_concat[0],  S_concat[5],  S_concat[29], S_concat[23],
                S_concat[13], S_concat[19], S_concat[2],  S_concat[26], S_concat[10], S_concat[21], S_concat[28], S_concat[7]};
endmodule

// S1 ~ S8 LUT
module S_boxes(
    input [5:0] S1_in,
    input [5:0] S2_in,
    input [5:0] S3_in,
    input [5:0] S4_in,
    input [5:0] S5_in,
    input [5:0] S6_in,
    input [5:0] S7_in,
    input [5:0] S8_in,
    output reg [3:0] S1_out,
    output reg [3:0] S2_out,
    output reg [3:0] S3_out,
    output reg [3:0] S4_out,
    output reg [3:0] S5_out,
    output reg [3:0] S6_out,
    output reg [3:0] S7_out,
    output reg [3:0] S8_out
);

    // S1
    always @(*) begin
        case (S1_in)
            6'd0: S1_out = 4'd14;
            6'd1: S1_out = 4'd0;
            6'd2: S1_out = 4'd4;
            6'd3: S1_out = 4'd15;
            6'd4: S1_out = 4'd13;
            6'd5: S1_out = 4'd7;
            6'd6: S1_out = 4'd1;
            6'd7: S1_out = 4'd4;
            6'd8: S1_out = 4'd2;
            6'd9: S1_out = 4'd14;
            6'd10: S1_out = 4'd15;
            6'd11: S1_out = 4'd2;
            6'd12: S1_out = 4'd11;
            6'd13: S1_out = 4'd13;
            6'd14: S1_out = 4'd8;
            6'd15: S1_out = 4'd1;
            6'd16: S1_out = 4'd3;
            6'd17: S1_out = 4'd10;
            6'd18: S1_out = 4'd10;
            6'd19: S1_out = 4'd6;
            6'd20: S1_out = 4'd6;
            6'd21: S1_out = 4'd12;
            6'd22: S1_out = 4'd12;
            6'd23: S1_out = 4'd11;
            6'd24: S1_out = 4'd5;
            6'd25: S1_out = 4'd9;
            6'd26: S1_out = 4'd9;
            6'd27: S1_out = 4'd5;
            6'd28: S1_out = 4'd0;
            6'd29: S1_out = 4'd3;
            6'd30: S1_out = 4'd7;
            6'd31: S1_out = 4'd8;
            6'd32: S1_out = 4'd4;
            6'd33: S1_out = 4'd15;
            6'd34: S1_out = 4'd1;
            6'd35: S1_out = 4'd12;
            6'd36: S1_out = 4'd14;
            6'd37: S1_out = 4'd8;
            6'd38: S1_out = 4'd8;
            6'd39: S1_out = 4'd2;
            6'd40: S1_out = 4'd13;
            6'd41: S1_out = 4'd4;
            6'd42: S1_out = 4'd6;
            6'd43: S1_out = 4'd9;
            6'd44: S1_out = 4'd2;
            6'd45: S1_out = 4'd1;
            6'd46: S1_out = 4'd11;
            6'd47: S1_out = 4'd7;
            6'd48: S1_out = 4'd15;
            6'd49: S1_out = 4'd5;
            6'd50: S1_out = 4'd12;
            6'd51: S1_out = 4'd11;
            6'd52: S1_out = 4'd9;
            6'd53: S1_out = 4'd3;
            6'd54: S1_out = 4'd7;
            6'd55: S1_out = 4'd14;
            6'd56: S1_out = 4'd3;
            6'd57: S1_out = 4'd10;
            6'd58: S1_out = 4'd10;
            6'd59: S1_out = 4'd0;
            6'd60: S1_out = 4'd5;
            6'd61: S1_out = 4'd6;
            6'd62: S1_out = 4'd0;
            6'd63: S1_out = 4'd13;
        endcase
    end

    // S2
    always @(*) begin
        case (S2_in)
            6'd0: S2_out = 4'd15;
            6'd1: S2_out = 4'd3;
            6'd2: S2_out = 4'd1;
            6'd3: S2_out = 4'd13;
            6'd4: S2_out = 4'd8;
            6'd5: S2_out = 4'd4;
            6'd6: S2_out = 4'd14;
            6'd7: S2_out = 4'd7;
            6'd8: S2_out = 4'd6;
            6'd9: S2_out = 4'd15;
            6'd10: S2_out = 4'd11;
            6'd11: S2_out = 4'd2;
            6'd12: S2_out = 4'd3;
            6'd13: S2_out = 4'd8;
            6'd14: S2_out = 4'd4;
            6'd15: S2_out = 4'd14;
            6'd16: S2_out = 4'd9;
            6'd17: S2_out = 4'd12;
            6'd18: S2_out = 4'd7;
            6'd19: S2_out = 4'd0;
            6'd20: S2_out = 4'd2;
            6'd21: S2_out = 4'd1;
            6'd22: S2_out = 4'd13;
            6'd23: S2_out = 4'd10;
            6'd24: S2_out = 4'd12;
            6'd25: S2_out = 4'd6;
            6'd26: S2_out = 4'd0;
            6'd27: S2_out = 4'd9;
            6'd28: S2_out = 4'd5;
            6'd29: S2_out = 4'd11;
            6'd30: S2_out = 4'd10;
            6'd31: S2_out = 4'd5;
            6'd32: S2_out = 4'd0;
            6'd33: S2_out = 4'd13;
            6'd34: S2_out = 4'd14;
            6'd35: S2_out = 4'd8;
            6'd36: S2_out = 4'd7;
            6'd37: S2_out = 4'd10;
            6'd38: S2_out = 4'd11;
            6'd39: S2_out = 4'd1;
            6'd40: S2_out = 4'd10;
            6'd41: S2_out = 4'd3;
            6'd42: S2_out = 4'd4;
            6'd43: S2_out = 4'd15;
            6'd44: S2_out = 4'd13;
            6'd45: S2_out = 4'd4;
            6'd46: S2_out = 4'd1;
            6'd47: S2_out = 4'd2;
            6'd48: S2_out = 4'd5;
            6'd49: S2_out = 4'd11;
            6'd50: S2_out = 4'd8;
            6'd51: S2_out = 4'd6;
            6'd52: S2_out = 4'd12;
            6'd53: S2_out = 4'd7;
            6'd54: S2_out = 4'd6;
            6'd55: S2_out = 4'd12;
            6'd56: S2_out = 4'd9;
            6'd57: S2_out = 4'd0;
            6'd58: S2_out = 4'd3;
            6'd59: S2_out = 4'd5;
            6'd60: S2_out = 4'd2;
            6'd61: S2_out = 4'd14;
            6'd62: S2_out = 4'd15;
            6'd63: S2_out = 4'd9;
        endcase
    end

    // S3
    always @(*) begin
        case (S3_in)
            6'd0: S3_out = 4'd10;
            6'd1: S3_out = 4'd13;
            6'd2: S3_out = 4'd0;
            6'd3: S3_out = 4'd7;
            6'd4: S3_out = 4'd9;
            6'd5: S3_out = 4'd0;
            6'd6: S3_out = 4'd14;
            6'd7: S3_out = 4'd9;
            6'd8: S3_out = 4'd6;
            6'd9: S3_out = 4'd3;
            6'd10: S3_out = 4'd3;
            6'd11: S3_out = 4'd4;
            6'd12: S3_out = 4'd15;
            6'd13: S3_out = 4'd6;
            6'd14: S3_out = 4'd5;
            6'd15: S3_out = 4'd10;
            6'd16: S3_out = 4'd1;
            6'd17: S3_out = 4'd2;
            6'd18: S3_out = 4'd13;
            6'd19: S3_out = 4'd8;
            6'd20: S3_out = 4'd12;
            6'd21: S3_out = 4'd5;
            6'd22: S3_out = 4'd7;
            6'd23: S3_out = 4'd14;
            6'd24: S3_out = 4'd11;
            6'd25: S3_out = 4'd12;
            6'd26: S3_out = 4'd4;
            6'd27: S3_out = 4'd11;
            6'd28: S3_out = 4'd2;
            6'd29: S3_out = 4'd15;
            6'd30: S3_out = 4'd8;
            6'd31: S3_out = 4'd1;
            6'd32: S3_out = 4'd13;
            6'd33: S3_out = 4'd1;
            6'd34: S3_out = 4'd6;
            6'd35: S3_out = 4'd10;
            6'd36: S3_out = 4'd4;
            6'd37: S3_out = 4'd13;
            6'd38: S3_out = 4'd9;
            6'd39: S3_out = 4'd0;
            6'd40: S3_out = 4'd8;
            6'd41: S3_out = 4'd6;
            6'd42: S3_out = 4'd15;
            6'd43: S3_out = 4'd9;
            6'd44: S3_out = 4'd3;
            6'd45: S3_out = 4'd8;
            6'd46: S3_out = 4'd0;
            6'd47: S3_out = 4'd7;
            6'd48: S3_out = 4'd11;
            6'd49: S3_out = 4'd4;
            6'd50: S3_out = 4'd1;
            6'd51: S3_out = 4'd15;
            6'd52: S3_out = 4'd2;
            6'd53: S3_out = 4'd14;
            6'd54: S3_out = 4'd12;
            6'd55: S3_out = 4'd3;
            6'd56: S3_out = 4'd5;
            6'd57: S3_out = 4'd11;
            6'd58: S3_out = 4'd10;
            6'd59: S3_out = 4'd5;
            6'd60: S3_out = 4'd14;
            6'd61: S3_out = 4'd2;
            6'd62: S3_out = 4'd7;
            6'd63: S3_out = 4'd12;
        endcase
    end

    // S4
    always @(*) begin
        case (S4_in)
            6'd0: S4_out = 4'd7;
            6'd1: S4_out = 4'd13;
            6'd2: S4_out = 4'd13;
            6'd3: S4_out = 4'd8;
            6'd4: S4_out = 4'd14;
            6'd5: S4_out = 4'd11;
            6'd6: S4_out = 4'd3;
            6'd7: S4_out = 4'd5;
            6'd8: S4_out = 4'd0;
            6'd9: S4_out = 4'd6;
            6'd10: S4_out = 4'd6;
            6'd11: S4_out = 4'd15;
            6'd12: S4_out = 4'd9;
            6'd13: S4_out = 4'd0;
            6'd14: S4_out = 4'd10;
            6'd15: S4_out = 4'd3;
            6'd16: S4_out = 4'd1;
            6'd17: S4_out = 4'd4;
            6'd18: S4_out = 4'd2;
            6'd19: S4_out = 4'd7;
            6'd20: S4_out = 4'd8;
            6'd21: S4_out = 4'd2;
            6'd22: S4_out = 4'd5;
            6'd23: S4_out = 4'd12;
            6'd24: S4_out = 4'd11;
            6'd25: S4_out = 4'd1;
            6'd26: S4_out = 4'd12;
            6'd27: S4_out = 4'd10;
            6'd28: S4_out = 4'd4;
            6'd29: S4_out = 4'd14;
            6'd30: S4_out = 4'd15;
            6'd31: S4_out = 4'd9;
            6'd32: S4_out = 4'd10;
            6'd33: S4_out = 4'd3;
            6'd34: S4_out = 4'd6;
            6'd35: S4_out = 4'd15;
            6'd36: S4_out = 4'd9;
            6'd37: S4_out = 4'd0;
            6'd38: S4_out = 4'd0;
            6'd39: S4_out = 4'd6;
            6'd40: S4_out = 4'd12;
            6'd41: S4_out = 4'd10;
            6'd42: S4_out = 4'd11;
            6'd43: S4_out = 4'd1;
            6'd44: S4_out = 4'd7;
            6'd45: S4_out = 4'd13;
            6'd46: S4_out = 4'd13;
            6'd47: S4_out = 4'd8;
            6'd48: S4_out = 4'd15;
            6'd49: S4_out = 4'd9;
            6'd50: S4_out = 4'd1;
            6'd51: S4_out = 4'd4;
            6'd52: S4_out = 4'd3;
            6'd53: S4_out = 4'd5;
            6'd54: S4_out = 4'd14;
            6'd55: S4_out = 4'd11;
            6'd56: S4_out = 4'd5;
            6'd57: S4_out = 4'd12;
            6'd58: S4_out = 4'd2;
            6'd59: S4_out = 4'd7;
            6'd60: S4_out = 4'd8;
            6'd61: S4_out = 4'd2;
            6'd62: S4_out = 4'd4;
            6'd63: S4_out = 4'd14;
        endcase
    end

    // S5
    always @(*) begin
        case (S5_in)
            6'd0: S5_out = 4'd2;
            6'd1: S5_out = 4'd14;
            6'd2: S5_out = 4'd12;
            6'd3: S5_out = 4'd11;
            6'd4: S5_out = 4'd4;
            6'd5: S5_out = 4'd2;
            6'd6: S5_out = 4'd1;
            6'd7: S5_out = 4'd12;
            6'd8: S5_out = 4'd7;
            6'd9: S5_out = 4'd4;
            6'd10: S5_out = 4'd10;
            6'd11: S5_out = 4'd7;
            6'd12: S5_out = 4'd11;
            6'd13: S5_out = 4'd13;
            6'd14: S5_out = 4'd6;
            6'd15: S5_out = 4'd1;
            6'd16: S5_out = 4'd8;
            6'd17: S5_out = 4'd5;
            6'd18: S5_out = 4'd5;
            6'd19: S5_out = 4'd0;
            6'd20: S5_out = 4'd3;
            6'd21: S5_out = 4'd15;
            6'd22: S5_out = 4'd15;
            6'd23: S5_out = 4'd10;
            6'd24: S5_out = 4'd13;
            6'd25: S5_out = 4'd3;
            6'd26: S5_out = 4'd0;
            6'd27: S5_out = 4'd9;
            6'd28: S5_out = 4'd14;
            6'd29: S5_out = 4'd8;
            6'd30: S5_out = 4'd9;
            6'd31: S5_out = 4'd6;
            6'd32: S5_out = 4'd4;
            6'd33: S5_out = 4'd11;
            6'd34: S5_out = 4'd2;
            6'd35: S5_out = 4'd8;
            6'd36: S5_out = 4'd1;
            6'd37: S5_out = 4'd12;
            6'd38: S5_out = 4'd11;
            6'd39: S5_out = 4'd7;
            6'd40: S5_out = 4'd10;
            6'd41: S5_out = 4'd1;
            6'd42: S5_out = 4'd13;
            6'd43: S5_out = 4'd14;
            6'd44: S5_out = 4'd7;
            6'd45: S5_out = 4'd2;
            6'd46: S5_out = 4'd8;
            6'd47: S5_out = 4'd13;
            6'd48: S5_out = 4'd15;
            6'd49: S5_out = 4'd6;
            6'd50: S5_out = 4'd9;
            6'd51: S5_out = 4'd15;
            6'd52: S5_out = 4'd12;
            6'd53: S5_out = 4'd0;
            6'd54: S5_out = 4'd5;
            6'd55: S5_out = 4'd9;
            6'd56: S5_out = 4'd6;
            6'd57: S5_out = 4'd10;
            6'd58: S5_out = 4'd3;
            6'd59: S5_out = 4'd4;
            6'd60: S5_out = 4'd0;
            6'd61: S5_out = 4'd5;
            6'd62: S5_out = 4'd14;
            6'd63: S5_out = 4'd3;
        endcase
    end
    
    // S6
    always @(*) begin
        case (S6_in)
            6'd0: S6_out = 4'd12;
            6'd1: S6_out = 4'd10;
            6'd2: S6_out = 4'd1;
            6'd3: S6_out = 4'd15;
            6'd4: S6_out = 4'd10;
            6'd5: S6_out = 4'd4;
            6'd6: S6_out = 4'd15;
            6'd7: S6_out = 4'd2;
            6'd8: S6_out = 4'd9;
            6'd9: S6_out = 4'd7;
            6'd10: S6_out = 4'd2;
            6'd11: S6_out = 4'd12;
            6'd12: S6_out = 4'd6;
            6'd13: S6_out = 4'd9;
            6'd14: S6_out = 4'd8;
            6'd15: S6_out = 4'd5;
            6'd16: S6_out = 4'd0;
            6'd17: S6_out = 4'd6;
            6'd18: S6_out = 4'd13;
            6'd19: S6_out = 4'd1;
            6'd20: S6_out = 4'd3;
            6'd21: S6_out = 4'd13;
            6'd22: S6_out = 4'd4;
            6'd23: S6_out = 4'd14;
            6'd24: S6_out = 4'd14;
            6'd25: S6_out = 4'd0;
            6'd26: S6_out = 4'd7;
            6'd27: S6_out = 4'd11;
            6'd28: S6_out = 4'd5;
            6'd29: S6_out = 4'd3;
            6'd30: S6_out = 4'd11;
            6'd31: S6_out = 4'd8;
            6'd32: S6_out = 4'd9;
            6'd33: S6_out = 4'd4;
            6'd34: S6_out = 4'd14;
            6'd35: S6_out = 4'd3;
            6'd36: S6_out = 4'd15;
            6'd37: S6_out = 4'd2;
            6'd38: S6_out = 4'd5;
            6'd39: S6_out = 4'd12;
            6'd40: S6_out = 4'd2;
            6'd41: S6_out = 4'd9;
            6'd42: S6_out = 4'd8;
            6'd43: S6_out = 4'd5;
            6'd44: S6_out = 4'd12;
            6'd45: S6_out = 4'd15;
            6'd46: S6_out = 4'd3;
            6'd47: S6_out = 4'd10;
            6'd48: S6_out = 4'd7;
            6'd49: S6_out = 4'd11;
            6'd50: S6_out = 4'd0;
            6'd51: S6_out = 4'd14;
            6'd52: S6_out = 4'd4;
            6'd53: S6_out = 4'd1;
            6'd54: S6_out = 4'd10;
            6'd55: S6_out = 4'd7;
            6'd56: S6_out = 4'd1;
            6'd57: S6_out = 4'd6;
            6'd58: S6_out = 4'd13;
            6'd59: S6_out = 4'd0;
            6'd60: S6_out = 4'd11;
            6'd61: S6_out = 4'd8;
            6'd62: S6_out = 4'd6;
            6'd63: S6_out = 4'd13;
        endcase
    end

    // S7
    always @(*) begin
        case (S7_in)
            6'd0: S7_out = 4'd4;
            6'd1: S7_out = 4'd13;
            6'd2: S7_out = 4'd11;
            6'd3: S7_out = 4'd0;
            6'd4: S7_out = 4'd2;
            6'd5: S7_out = 4'd11;
            6'd6: S7_out = 4'd14;
            6'd7: S7_out = 4'd7;
            6'd8: S7_out = 4'd15;
            6'd9: S7_out = 4'd4;
            6'd10: S7_out = 4'd0;
            6'd11: S7_out = 4'd9;
            6'd12: S7_out = 4'd8;
            6'd13: S7_out = 4'd1;
            6'd14: S7_out = 4'd13;
            6'd15: S7_out = 4'd10;
            6'd16: S7_out = 4'd3;
            6'd17: S7_out = 4'd14;
            6'd18: S7_out = 4'd12;
            6'd19: S7_out = 4'd3;
            6'd20: S7_out = 4'd9;
            6'd21: S7_out = 4'd5;
            6'd22: S7_out = 4'd7;
            6'd23: S7_out = 4'd12;
            6'd24: S7_out = 4'd5;
            6'd25: S7_out = 4'd2;
            6'd26: S7_out = 4'd10;
            6'd27: S7_out = 4'd15;
            6'd28: S7_out = 4'd6;
            6'd29: S7_out = 4'd8;
            6'd30: S7_out = 4'd1;
            6'd31: S7_out = 4'd6;
            6'd32: S7_out = 4'd1;
            6'd33: S7_out = 4'd6;
            6'd34: S7_out = 4'd4;
            6'd35: S7_out = 4'd11;
            6'd36: S7_out = 4'd11;
            6'd37: S7_out = 4'd13;
            6'd38: S7_out = 4'd13;
            6'd39: S7_out = 4'd8;
            6'd40: S7_out = 4'd12;
            6'd41: S7_out = 4'd1;
            6'd42: S7_out = 4'd3;
            6'd43: S7_out = 4'd4;
            6'd44: S7_out = 4'd7;
            6'd45: S7_out = 4'd10;
            6'd46: S7_out = 4'd14;
            6'd47: S7_out = 4'd7;
            6'd48: S7_out = 4'd10;
            6'd49: S7_out = 4'd9;
            6'd50: S7_out = 4'd15;
            6'd51: S7_out = 4'd5;
            6'd52: S7_out = 4'd6;
            6'd53: S7_out = 4'd0;
            6'd54: S7_out = 4'd8;
            6'd55: S7_out = 4'd15;
            6'd56: S7_out = 4'd0;
            6'd57: S7_out = 4'd14;
            6'd58: S7_out = 4'd5;
            6'd59: S7_out = 4'd2;
            6'd60: S7_out = 4'd9;
            6'd61: S7_out = 4'd3;
            6'd62: S7_out = 4'd2;
            6'd63: S7_out = 4'd12;
        endcase
    end

    // S8
    always @(*) begin
        case (S8_in)
            6'd0: S8_out = 4'd13;
            6'd1: S8_out = 4'd1;
            6'd2: S8_out = 4'd2;
            6'd3: S8_out = 4'd15;
            6'd4: S8_out = 4'd8;
            6'd5: S8_out = 4'd13;
            6'd6: S8_out = 4'd4;
            6'd7: S8_out = 4'd8;
            6'd8: S8_out = 4'd6;
            6'd9: S8_out = 4'd10;
            6'd10: S8_out = 4'd15;
            6'd11: S8_out = 4'd3;
            6'd12: S8_out = 4'd11;
            6'd13: S8_out = 4'd7;
            6'd14: S8_out = 4'd1;
            6'd15: S8_out = 4'd4;
            6'd16: S8_out = 4'd10;
            6'd17: S8_out = 4'd12;
            6'd18: S8_out = 4'd9;
            6'd19: S8_out = 4'd5;
            6'd20: S8_out = 4'd3;
            6'd21: S8_out = 4'd6;
            6'd22: S8_out = 4'd14;
            6'd23: S8_out = 4'd11;
            6'd24: S8_out = 4'd5;
            6'd25: S8_out = 4'd0;
            6'd26: S8_out = 4'd0;
            6'd27: S8_out = 4'd14;
            6'd28: S8_out = 4'd12;
            6'd29: S8_out = 4'd9;
            6'd30: S8_out = 4'd7;
            6'd31: S8_out = 4'd2;
            6'd32: S8_out = 4'd7;
            6'd33: S8_out = 4'd2;
            6'd34: S8_out = 4'd11;
            6'd35: S8_out = 4'd1;
            6'd36: S8_out = 4'd4;
            6'd37: S8_out = 4'd14;
            6'd38: S8_out = 4'd1;
            6'd39: S8_out = 4'd7;
            6'd40: S8_out = 4'd9;
            6'd41: S8_out = 4'd4;
            6'd42: S8_out = 4'd12;
            6'd43: S8_out = 4'd10;
            6'd44: S8_out = 4'd14;
            6'd45: S8_out = 4'd8;
            6'd46: S8_out = 4'd2;
            6'd47: S8_out = 4'd13;
            6'd48: S8_out = 4'd0;
            6'd49: S8_out = 4'd15;
            6'd50: S8_out = 4'd6;
            6'd51: S8_out = 4'd12;
            6'd52: S8_out = 4'd10;
            6'd53: S8_out = 4'd9;
            6'd54: S8_out = 4'd13;
            6'd55: S8_out = 4'd0;
            6'd56: S8_out = 4'd15;
            6'd57: S8_out = 4'd3;
            6'd58: S8_out = 4'd3;
            6'd59: S8_out = 4'd5;
            6'd60: S8_out = 4'd5;
            6'd61: S8_out = 4'd6;
            6'd62: S8_out = 4'd8;
            6'd63: S8_out = 4'd11;
        endcase
    end

endmodule