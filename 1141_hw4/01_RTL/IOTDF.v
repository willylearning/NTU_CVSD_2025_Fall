`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
    input          clk;
    input          rst;
    input          in_en;
    input  [7:0]   iot_in;
    input  [2:0]   fn_sel;
    output         busy;
    output         valid;
    output [127:0] iot_out;

    localparam ENCRYPT = 1, DECRYPT = 2, CRC_GEN = 3, SORTING = 4;

    reg [127:0] iot_data;
    reg [3:0] counter;
    reg first_data_in_flag;
    reg valid_r;
    // reg busy_r;
    reg [127:0] iot_out_r;

     // assign busy = busy_r;
    assign busy = 0;
    assign valid = valid_r;
    assign iot_out = iot_out_r;

    // Encrypt/Decrypt wires and regs
    wire decrypt_mode;
    wire [127:0] des_out;
    wire des_done;

    assign decrypt_mode = (fn_sel == DECRYPT);

    // CRC Generator wires and regs
    reg [127:0] iot_data_crc;
    reg [10:0] dividend;
    reg [2:0] remainder_r, remainder_w;

    // Sorting wires and regs
    wire [127:0] sorting_out;

    // Input Data Register (Collect 128-bit data)
    always @(posedge clk or posedge rst) begin
        if (rst) 
            iot_data <= 0;
        else if (in_en) 
            iot_data <= {iot_in, iot_data[127:8]};  // fetch 8-bit input data per cycle
    end

    // Input Data Register for CRC
    always @(posedge clk or posedge rst) begin
        if (rst) 
            iot_data_crc <= 0;
        else if (in_en && counter == 15) 
            iot_data_crc <= {iot_in, iot_data[127:8]}; // latch the 128-bit data loaded from previous 16 cycles
    end

    // Round Counter
    always @(posedge clk or posedge rst) begin
        if (rst)
            counter <= 0;
        else if (in_en)
            counter <= counter + 1; // When counter == 15, counter + 1 -> 0 due to overflow
    end

    // Update first_data_in_flag
    always @(posedge clk or posedge rst) begin
        if (rst)
            first_data_in_flag <= 0;
        else if (counter == 15)
            first_data_in_flag <= 1; // set high when the first 128-bit data is fully received
    end

    // Update valid_r 
    always @(posedge clk or posedge rst) begin
        if (rst) 
            valid_r <= 0;
        else if (((fn_sel == ENCRYPT) || (fn_sel == DECRYPT)) && des_done) 
            valid_r <= 1;
        else if ((fn_sel == CRC_GEN) && first_data_in_flag && (counter == 15)) 
            valid_r <= 1; 
        else if ((fn_sel == SORTING) && first_data_in_flag && (counter == 0)) 
            valid_r <= 1; 
        else 
            valid_r <= 0;
    end

    // Update iot_out_r
    always @(posedge clk or posedge rst) begin
        if (rst)
            iot_out_r <= 0;
        else if (((fn_sel == ENCRYPT) || (fn_sel == DECRYPT)) && des_done)
            iot_out_r <= des_out;
        else if ((fn_sel == CRC_GEN) && first_data_in_flag && (counter == 15))
            iot_out_r <= {125'd0, remainder_w};
        else if ((fn_sel == SORTING) && first_data_in_flag && (counter == 0))
            iot_out_r <= sorting_out;
    end

    // ---------------------------------------------------------------------------
    // CRC generator logic
    // ---------------------------------------------------------------------------
    // Prepare dividend for CRC calculation
    always @(*) begin
        if (first_data_in_flag) begin
            if (counter == 0) 
                dividend = iot_data_crc[127:117];
            else if (counter == 15)
                dividend = {remainder_r, iot_data_crc[4:0], 3'd0};
            else
                dividend = {remainder_r, iot_data_crc[117 - 8*counter +: 8]};
        end
        else begin
            dividend = 0;
        end
    end

    // Update remainder_r
    always @(posedge clk or posedge rst) begin
        if (rst)
            remainder_r <= 0;
        else
            remainder_r <= remainder_w;
    end
    
    // Instantiate DES core
    EnDecrypt u_des_core (
        .clk          (clk),
        .rst          (rst),
        .first_data_in_flag (first_data_in_flag),
        .decrypt_mode (decrypt_mode),
        // .round (counter),
        .iot_data_crc (iot_data_crc),
        .data_in      (iot_data), // data_in[127:64] is main key, data_in[63:0] is plaintext
        .data_out     (des_out),  // data_out[127:64] is main key, data_out[63:0] is ciphertext
        .done         (des_done)
    );

    // Instantiate CRC generator
    CRC_Gen u_crc_gen (
        .data_in (dividend), 
        .crc_out (remainder_w)
    );

    // Instantiate Sorting module
    Sorting u_sorting (
        .clk       (clk),
        .rst       (rst),
        .counter   (counter),
        .in_en     (in_en),
        .data_in   (iot_in),
        .data_out  (sorting_out)
    );
endmodule

module CRC_Gen (
    input  [10:0] data_in,
    output [2:0]  crc_out  // 3-bit CRC remainder (checksum)
);
    // Generator polynomial = x^3 + x^2 + 1
    // By LFSR method
    assign crc_out[2] = data_in[10] ^ data_in[9] ^ data_in[6]  ^ data_in[4] ^ data_in[3]  ^ data_in[2];

    assign crc_out[1] = data_in[8]  ^ data_in[6] ^ data_in[5]  ^ data_in[4] ^ data_in[1];

    assign crc_out[0] = data_in[10] ^ data_in[7] ^ data_in[5]  ^ data_in[4] ^ data_in[3]  ^ data_in[0];

endmodule

module Sorting (
    input        clk,
    input        rst,
    input [3:0]  counter,
    input        in_en,
    input [7:0]  data_in,        // 當前 8-bit IoT 資料
    output reg [127:0] data_out  // 排序後 16-byte 結果
);
    // Insertion sort in descending order
    integer i;

    reg [16:0] bit_array;  // 17 bits, 最後一個bit固定為1

    // Combinational comparator bit array
    always @(*) begin
        if (in_en && counter != 0) begin
            bit_array[16] = 1;
            for (i = 15; i >= 0; i = i - 1)
                bit_array[i] = (data_in < data_out[i*8 +: 8]) ? 1 : 0;
        end
        else begin
            bit_array = {1'b1, 16'd0};
        end
    end

    // Sequential insertion logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
        end
        else if (in_en) begin
            if (counter == 0) begin
                data_out <= {data_in, 120'd0};
            end
            else begin
                for (i = 16; i > 0; i = i - 1) begin
                    if (bit_array[i -: 2] == 2'b10)
                        data_out[(i-1)*8 +: 8] <= data_in;
                    else if (bit_array[i -: 2] == 2'b11)
                        data_out[(i-1)*8 +: 8] <= data_out[(i-1)*8 +: 8];
                    else
                        data_out[(i-1)*8 +: 8] <= data_out[i*8 +: 8];
                end
            end
        end
    end
endmodule

