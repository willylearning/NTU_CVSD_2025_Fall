module alu #(
    parameter DATA_WIDTH = 32
) (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input      signed [DATA_WIDTH-1:0] r1,
    input      signed [DATA_WIDTH-1:0] r2,
    input      signed [DATA_WIDTH-1:0] imm,
    input             [DATA_WIDTH-1:0] pc,
    output reg signed [DATA_WIDTH-1:0] alu_out,
    output invalid_flag,
    output reg do_branch_flag
);

    reg signed [DATA_WIDTH:0] tmp_result; // need 33 bits to check overflow 
    reg int_overflow_flag;
    reg INF_NaN_flag;
    reg f_overflow_underflow_flag;
    reg unknown_addr_flag;

    assign invalid_flag = int_overflow_flag | INF_NaN_flag | unknown_addr_flag | f_overflow_underflow_flag;

    always @(*) begin
        tmp_result = 0;
        alu_out = 0;
        int_overflow_flag = 0;
        INF_NaN_flag = 0;
        f_overflow_underflow_flag = 0;
        unknown_addr_flag = 0;
        do_branch_flag = 0;
        if (opcode == `OP_SUB && funct3 == `FUNCT3_SUB && funct7 == `FUNCT7_SUB) begin
            tmp_result = r1 - r2; // $rd = $r1 - $r2 
            // check if overflow happens
            int_overflow_flag = (tmp_result > 32'sh7FFFFFFF || tmp_result < 32'sh80000000) ? 1'b1 : 1'b0;

            alu_out = tmp_result[DATA_WIDTH-1:0];
        end
        else if (opcode == `OP_ADDI && funct3 == `FUNCT3_ADDI) begin
            tmp_result = r1 + imm; // $rd = $r1 + imm
            // check if overflow happens
            int_overflow_flag = (tmp_result > 32'sh7FFFFFFF || tmp_result < 32'sh80000000) ? 1'b1 : 1'b0;

            alu_out = tmp_result[DATA_WIDTH-1:0];
        end
        else if (opcode == `OP_LW && funct3 == `FUNCT3_LW) begin
            tmp_result = r1 + imm; // $rd = Mem[$r1 + imm]
            // check if output address are mapped to unknown address in memory
            unknown_addr_flag = (tmp_result > 8191 || tmp_result < 4096) ? 1 : 0;

            alu_out = tmp_result[DATA_WIDTH-1:0];
        end
        else if (opcode == `OP_SW && funct3 == `FUNCT3_SW) begin
            tmp_result = r1 + imm; // Mem[$r1 + imm] = $r2
            // check if output address are mapped to unknown address in memory
            unknown_addr_flag = (tmp_result > 8191 || tmp_result < 4096) ? 1 : 0;

            alu_out = tmp_result[DATA_WIDTH-1:0];
        end
        else if (opcode == `OP_BEQ && funct3 == `FUNCT3_BEQ) begin
            do_branch_flag = (r1 == r2) ? 1 : 0;
            alu_out = (r1 == r2) ? 1 : 0; // if ($r1 == $r2), $pc = $pc + imm; else, $pc = $pc + 4
        end
        else if (opcode == `OP_BLT && funct3 == `FUNCT3_BLT) begin
            do_branch_flag = (r1 < r2) ? 1 : 0;
            alu_out = (r1 < r2) ? 1 : 0; // if ($r1 < $r2), $pc = $pc + imm; else, $pc = $pc + 4
        end
        else if (opcode == `OP_JALR && funct3 == `FUNCT3_JALR) begin
            alu_out = pc + 4; // $rd = $pc + 4, pc = ($r1 + imm) & (~0x1)
        end
        else if (opcode == `OP_AUIPC) begin
            alu_out = pc + imm; // $rd = $pc + (im << 12), imm << 12 is done in core.v
        end
        else if (opcode == `OP_SLT && funct3 == `FUNCT3_SLT && funct7 == `FUNCT7_SLT) begin
            alu_out = (r1 < r2) ? 1 : 0; // if ($r1<$r2), $rd = 1; else, $rd = 0
        end
        else if (opcode == `OP_SRL && funct3 == `FUNCT3_SRL && funct7 == `FUNCT7_SRL) begin
            alu_out = $unsigned(r1) >> $unsigned(r2); // $rd = $r1 >> $r2 (Unsigned Operation)
        end
        else if (opcode == `OP_FSUB && funct3 == `FUNCT3_FSUB && funct7 == `FUNCT7_FSUB) begin
            INF_NaN_flag = (is_INF(r1) | is_INF(r2) | is_NaN(r1) | is_NaN(r2));
            alu_out = f_sub_out(r1, r2); // $fd = $fr1 - $fr2
            // check if the result overflows/underflows
            f_overflow_underflow_flag = (alu_out[30:23] == 8'd255 || alu_out[30:23] == 8'd0) ? 1 : 0;
        end
        else if (opcode == `OP_FMUL && funct3 == `FUNCT3_FMUL && funct7 == `FUNCT7_FMUL) begin
            INF_NaN_flag = (is_INF(r1) | is_INF(r2) | is_NaN(r1) | is_NaN(r2));
            alu_out = f_mul_out(r1, r2); // $fd = $f1 * $f2
            // check if the result overflows/underflows
            f_overflow_underflow_flag = (alu_out[30:23] == 8'd255 || alu_out[30:23] == 8'd0) ? 1 : 0; 
        end
        else if (opcode == `OP_FCVTWS && funct3 == `FUNCT3_FCVTWS && funct7 == `FUNCT7_FCVTWS) begin
            INF_NaN_flag = (is_INF(r1) | is_INF(r2) | is_NaN(r1) | is_NaN(r2));
            {f_overflow_underflow_flag, alu_out} = fcvt_w_s_out(r1); // $rd = s32f32($f1)
        end
        else if (opcode == `OP_FLW && funct3 == `FUNCT3_FLW) begin
            tmp_result = r1 + imm; // $fd = Mem[$r1 + imm]
            // check if output address are mapped to unknown address in memory
            unknown_addr_flag = (tmp_result > 8191 || tmp_result < 4096) ? 1 : 0;

            alu_out = tmp_result[DATA_WIDTH-1:0];
        end
        else if (opcode == `OP_FSW && funct3 == `FUNCT3_FSW) begin
            tmp_result = r1 + imm; // Mem[$r1 + imm] = $f2
            // check if output address are mapped to unknown address in memory
            unknown_addr_flag = (tmp_result > 8191 || tmp_result < 4096) ? 1 : 0;

            alu_out = tmp_result[DATA_WIDTH-1:0];
        end
        else if (opcode == `OP_FCLASS && funct3 == `FUNCT3_FCLASS && funct7 == `FUNCT7_FCLASS) begin
            // check the class of floating-point number
            if (is_INF(r1)) // -INF : bit[0] = 1, +INF : bit[7] = 1
                alu_out = (r1[31] == 1'b1) ? 32'b00000000000000000000000000000001 : 32'b00000000000000000000000010000000; 
            else if (is_NaN(r1)) // if (r1[22] == 1'b1) then quiet NaN : bit[9] = 1, else signaling NaN : bit[8] = 1
                alu_out = (r1[22] == 1'b1) ? 32'b00000000000000000000001000000000 : 32'b00000000000000000000000100000000; 
            else if (is_subnormal(r1)) // neg subnormal : bit[2] = 1, pos subnormal : bit[5] = 1
                alu_out = (r1[31] == 1'b1) ? 32'b00000000000000000000000000000100 : 32'b00000000000000000000000000100000; 
            else if (is_zero(r1)) // neg zero : bit[3] = 1, pos zero : bit[4] = 1
                alu_out = (r1[31] == 1'b1) ? 32'b00000000000000000000000000001000 : 32'b00000000000000000000000000010000; 
            else // neg normal : bit[1] = 1, positive normal : bit[6] = 1
                alu_out = (r1[31] == 1'b1) ? 32'b00000000000000000000000000000010 : 32'b00000000000000000000000001000000; 
        end
    end

    function automatic is_INF; // s = 1; e = 255; m = 0
        input [DATA_WIDTH-1:0] r;
        begin
            is_INF = (r[30:23] == 8'd255 && r[22:0] == 23'd0) ? 1'b1 : 1'b0;
        end
    endfunction

    function automatic is_NaN; // e = 255; m != 0
        input [DATA_WIDTH-1:0] r;
        begin
            is_NaN = (r[30:23] == 8'd255 && r[22:0] != 23'd0) ? 1'b1 : 1'b0;
        end
    endfunction

    function automatic is_subnormal; // e = 0; m != 0
        input [DATA_WIDTH-1:0] r;
        begin
            is_subnormal = (r[30:23] == 8'd0 && r[22:0] != 23'd0) ? 1'b1 : 1'b0;
        end
    endfunction

    function automatic is_zero;
        input [DATA_WIDTH-1:0] r;
        begin
            is_zero = (r[30:0] == 31'd0) ? 1'b1 : 1'b0;
        end
    endfunction

    function automatic [DATA_WIDTH-1:0] f_sub_out; // $fd = $f1 - $f2
        input [DATA_WIDTH-1:0] r1, r2; 
        // Don't need to check INF/NaN here, which is invalid operation that will be checked before calling this function
        // max of e = 254, min of e = 0 => subnormal numbers or zero
        reg s1, s2; // sign
        reg [7:0] e1, e2; // exponent
        reg [276:0] m1, m2; // at least 1 + 23 + 253 = 277 bits, include leading one (actually 1.m1 and 1.m2)
        reg [276:0] aligned_m1, aligned_m2;
        reg sign_res;
        reg [277:0] mant_res; // one extra bit for overflow
        reg [277:0] normalized_mant_res;
        reg [22:0] final_mant_res;
        reg [8:0] exp_res;
        reg [8:0] final_exp_res; // one extra bit for overflow
        reg [8:0] clz; // count leading zeros
        reg found_one;
        integer i;
        reg guard, round, sticky;
        begin
            // check if r1 or r2 is zero
            if (is_zero(r1) && is_zero(r2)) begin
                f_sub_out = 32'b00000000_00000000_00000000_00000000; // +0
            end
            else if (is_zero(r1) & ~is_zero(r2)) begin
                f_sub_out = {~r2[31], r2[30:0]}; // -r2
            end
            else if (~is_zero(r1) & is_zero(r2)) begin
                f_sub_out = r1; // r1
            end
            else if (r1 == r2) begin // set the result of fsub and fmul to +0 if the arithmetic result is 0
                f_sub_out = 32'b00000000_00000000_00000000_00000000; // +0
            end
            else begin
                // get s, e, m
                s1 = r1[31];
                e1 = is_subnormal(r1) ? 8'd1 : r1[30:23]; // if subnormal number, set e1 to 1 for alignment purpose
                m1 = is_subnormal(r1) ? {1'b0, r1[22:0], 253'd0} : {1'b1, r1[22:0], 253'd0}; // if subnormal number, no leading one

                s2 = ~r2[31]; // negate for subtraction
                e2 = is_subnormal(r2) ? 8'd1 : r2[30:23]; // if subnormal number, set e2 to 1 for alignment purpose
                m2 = is_subnormal(r2) ? {1'b0, r2[22:0], 253'd0} : {1'b1, r2[22:0], 253'd0}; // subnormal vs normal

                // align exponents with the larger one => right shift the smaller one's mantissa
                aligned_m1 = m1;
                aligned_m2 = m2;
                if (e1 > e2) 
                    aligned_m2 = m2 >> (e1 - e2);
                else if (e2 > e1)
                    aligned_m1 = m1 >> (e2 - e1);

                // get mant_res
                exp_res = (e1 >= e2) ? e1 : e2;
                if (s1 == s2) begin // do addition directly
                    mant_res = aligned_m1 + aligned_m2;
                    sign_res = s1;
                end 
                else begin // do subtraction
                    if (aligned_m1 >= aligned_m2) begin
                        mant_res = aligned_m1 - aligned_m2;
                        sign_res = s1;
                    end 
                    else begin
                        mant_res = aligned_m2 - aligned_m1;
                        sign_res = s2;
                    end
                end

                // normalize the result
                if (mant_res[277] == 1'b1) begin
                    // overflow: mant_res needs to right shift 1 bit
                    normalized_mant_res = mant_res >> 1;
                    final_exp_res = exp_res + 1;

                    // check if final result overflows or not
                    if (final_exp_res >= 255) begin 
                        final_exp_res = 255;
                        final_mant_res = 23'd0;
                    end
                    else begin
                        // Round to Nearest Even
                        guard = normalized_mant_res[253]; // LSB of mantissa
                        round = normalized_mant_res[252]; // MSB of remaining bits
                        sticky = |normalized_mant_res[251:0]; // OR of the rest remaining bits
                        if (round && (sticky || guard)) begin
                            final_mant_res = normalized_mant_res[275:253] + 1;
                        end
                        else begin
                            final_mant_res = normalized_mant_res[275:253];
                        end
                    end
                end 
                else begin
                    // count leading zeros
                    clz = 9'd276; // Default value if all bits are zero
                    found_one = 1'b0;
                    begin : clz_loop
                        for (i = 276; i >= 0; i = i - 1) begin
                            if (found_one == 1'b0) begin
                                if (mant_res[i] == 1'b1) begin
                                    clz = 276 - i;
                                    found_one = 1'b1;
                                end
                            end
                        end
                    end

                    normalized_mant_res = mant_res << clz;
                    final_exp_res = exp_res - clz;

                    // check if underflow/overflow happens
                    if (final_exp_res >= 255) begin // overflow
                        final_exp_res = 255;
                        final_mant_res = 23'd0;
                    end
                    else if (final_exp_res < 1) begin // underflow
                        final_exp_res = 0;
                        final_mant_res = 23'd0;
                    end
                    else begin
                        // Round to Nearest Even
                        guard = normalized_mant_res[253]; // LSB of mantissa
                        round = normalized_mant_res[252]; // MSB of remaining bits
                        sticky = |normalized_mant_res[251:0]; // OR of the rest remaining bits
                        if (round && (sticky || guard)) begin
                            final_mant_res = normalized_mant_res[275:253] + 1;
                        end
                        else begin
                            final_mant_res = normalized_mant_res[275:253];
                        end
                    end
                end

                f_sub_out = {sign_res, final_exp_res[7:0], final_mant_res};
            end
        end
    endfunction

    function automatic [DATA_WIDTH-1:0] f_mul_out; // $fd = $f1 * $f2
        input [DATA_WIDTH-1:0] r1, r2; 
        // Don't need to check INF/NaN here, which is invalid operation that will be checked before calling this function
        // max of e = 254, min of e = 0 => subnormal numbers or zero
        reg s1, s2; // sign
        reg [7:0] e1, e2; // exponent
        reg [23:0] m1, m2; // 1 + 23 bits, include leading one (actually 1.m1 and 1.m2)
        reg [23:0] aligned_m1, aligned_m2;
        reg sign_res;
        reg [48:0] mant_res; // (x.m1) × (x.m2) -> (24 bits) × (24 bits) = 48 bits, one extra bit for if res = 1x.m then need right shift
        reg [47:0] mant_mul;
        reg [48:0] normalized_mant_res;
        reg [22:0] final_mant_res;
        reg [7:0] exp_res;
        reg [8:0] final_exp_res; // one extra bit for overflow
        reg [5:0] clz; // count leading zeros
        reg found_one;
        integer i;
        reg guard, round, sticky;
        begin
            if (is_zero(r1) | is_zero(r2)) begin // set the result of fsub and fmul to +0 if the arithmetic result is 0
                f_mul_out = 32'b00000000_00000000_00000000_00000000; // +0
            end
            else begin
                // get s, e, m
                s1 = r1[31];
                e1 = is_subnormal(r1) ? 8'd1 : r1[30:23]; // if subnormal number, set e1 to 1 for alignment purpose
                m1 = is_subnormal(r1) ? {1'b0, r1[22:0]} : {1'b1, r1[22:0]}; // if subnormal number, no leading one

                s2 = r2[31];
                e2 = is_subnormal(r2) ? 8'd1 : r2[30:23]; // if subnormal number, set e2 to 1 for alignment purpose
                m2 = is_subnormal(r2) ? {1'b0, r2[22:0]} : {1'b1, r2[22:0]}; // if subnormal number, no leading one

                // get mant_res
                sign_res = s1 ^ s2;
                exp_res = e1 + e2 - 8'd127; // subtract bias
                mant_mul = m1 * m2;
                mant_res = {mant_mul, 1'b0}; // append 0 in the end for if res = 1x.m then need right shift
                // mant_res = {m1 * m2, 1'b0}; // wrong result !

                if (mant_res[48] == 1'b1) begin
                    // overflow: mant_res needs to right shift 1 bit
                    normalized_mant_res = mant_res >> 1;
                    final_exp_res = exp_res + 1;

                    // check if final result overflows or not
                    if (final_exp_res >= 255) begin
                        final_exp_res = 255;
                        final_mant_res = 23'd0;
                    end
                    else begin
                        // Round to Nearest Even
                        guard = normalized_mant_res[24]; // LSB of mantissa
                        round = normalized_mant_res[23]; // MSB of remaining bits
                        sticky = |normalized_mant_res[22:0]; // OR of the rest remaining bits
                        if (round && (sticky || guard)) begin
                            final_mant_res = normalized_mant_res[46:24] + 1;
                        end
                        else begin
                            final_mant_res = normalized_mant_res[46:24];
                        end
                    end
                end 
                else begin
                    // count leading zeros
                    clz = 6'd47; // Default value if all bits are zero
                    found_one = 1'b0;
                    begin : clz_loop
                        for (i = 47; i >= 0; i = i - 1) begin
                            if (found_one == 1'b0) begin
                                if (mant_res[i] == 1'b1) begin
                                    clz = 47 - i;
                                    found_one = 1'b1;
                                end
                            end
                        end
                    end

                    normalized_mant_res = mant_res << clz;
                    final_exp_res = exp_res - clz;

                    // check if underflow/overflow happens
                    if (final_exp_res >= 255) begin // overflow
                        final_exp_res = 255;
                        final_mant_res = 23'd0;
                    end
                    else if (final_exp_res < 1) begin // underflow
                        final_exp_res = 0;
                        final_mant_res = 23'd0;
                    end
                    else begin
                        // Round to Nearest Even
                        guard = normalized_mant_res[24]; // LSB of mantissa
                        round = normalized_mant_res[23]; // MSB of remaining bits
                        sticky = |normalized_mant_res[22:0]; // OR of the rest remaining bits
                        if (round && (sticky || guard)) begin
                            final_mant_res = normalized_mant_res[46:24] + 1;
                        end
                        else begin
                            final_mant_res = normalized_mant_res[46:24];
                        end
                    end
                end
                f_mul_out = {sign_res, final_exp_res[7:0], final_mant_res};
            end
        end
    endfunction

    function automatic [DATA_WIDTH:0] fcvt_w_s_out; // $rd = s32f32($f1), return {overflow_flag, int_result}
        input [DATA_WIDTH-1:0] r1; 
        // Don't need to check INF/NaN here, which is invalid operation that will be checked before calling this function
        reg s1; // sign
        reg [7:0] e1; // exponent
        reg [32:0] m1; // 1 + 23 bits, include leading one (actually 1.m1)
        reg signed [31:0] int_result;
        reg overflow_flag;
        reg [7:0] shift_amount;
        reg guard, round, sticky;
        reg [32:0] sticky_mask;
        reg [32:0] int_part_temp;
        begin
            s1 = r1[31];
            e1 = r1[30:23];
            m1 = {1'b1, r1[22:0], 9'd0}; // append 9 zeros in the end for max shift amount = 30

            overflow_flag = 0;
            int_result = 0; 
            if (e1 == 8'd255) begin // INF or NaN -> invalid, will be checked before calling this function
                int_result = 0; 
            end
            else if (e1 == 8'd0) begin // zero or subnormal number
                int_result = 0;
            end
            else begin // normal number
                if (e1 > 127) begin
                    shift_amount = e1 - 127;
                    if (shift_amount == 31 && s1 == 1 && m1 == 33'b1_00000000_00000000_00000000_00000000) begin
                        // -2147483648, the only valid overflow case
                        int_result = 32'sb10000000_00000000_00000000_00000000;
                    end
                    else if (shift_amount > 30) begin // must overflow
                        overflow_flag = 1;
                    end
                    else begin
                        // Round to Nearest Even
                        guard = m1[32 - shift_amount]; // LSB of integer part
                        round = m1[32 - shift_amount - 1]; // MSB of remaining bits
                        sticky_mask = (1'b1 << (32 - shift_amount - 1)) - 1; 
                        // sticky = |m1[(32 - shift_amount - 2) : 0]; // OR of the rest remaining bits
                        sticky = |(m1 & sticky_mask); // OR of the rest remaining bits

                        int_part_temp = m1 >> (32 - shift_amount);
                        if (round && (sticky || guard)) begin
                            // int_result = (s1 == 0) ? (m1[32 -: (shift_amount + 1)] + 1) : -(m1[32 -: (shift_amount + 1)] + 1);
                            int_result = (s1 == 0) ? (int_part_temp + 1) : -(int_part_temp + 1);
                        end
                        else begin
                            int_result = (s1 == 0) ? int_part_temp : -int_part_temp;
                        end
                    end
                end
                else if (e1 < 127) begin
                    shift_amount = 127 - e1;
                    int_result = 0;
                    // There are only two cases that can round up to int_result = 1 or -1
                    // 1. e1 = 126, s1 = 0, 1.m1 = 1.1xxx -> 1
                    // 2. e1 = 126, s1 = 1, 1.m1 = 1.1xxx -> -1
                    if (shift_amount == 1 && m1[32:31] == 2'b11) begin
                        int_result = (s1 == 0) ? 32'd1 : -32'd1;
                    end
                end
                else begin // e1 = 127
                    if (m1[31] == 1'b1) begin // 1.m1 = 1.1xxx
                        int_result = (s1 == 0) ? 32'd2 : -32'd2;
                    end
                    else begin
                        int_result = (s1 == 0) ? 32'd1 : -32'd1;
                    end
                end
            end 
            fcvt_w_s_out = {overflow_flag, int_result};
        end
    endfunction
endmodule