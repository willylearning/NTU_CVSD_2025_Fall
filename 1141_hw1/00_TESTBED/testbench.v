/********************************************************************
* Filename: testbench.v
* Authors:
*     Po-Hao Tseng
* Description:
*     testbench for hw1 of CVSD 2025 Fall
* Parameters:
*
* Note:
*
* Review History:
*     2025.08.18             Po-Hao Tseng
*********************************************************************/

`timescale 1ns/10ps
`define PERIOD    10.0
`define MAX_CYCLE 100000
`define RST_DELAY 2.0

`ifdef I0
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST0_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST0_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I1
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST1_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST1_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I2
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST2_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST2_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I3
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST3_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST3_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I4
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST4_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST4_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I5
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST5_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST5_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I6
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST6_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST6_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I7
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST7_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST7_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I8
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST8_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST8_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif I9
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST9_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST9_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`elsif MY_I0
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST0_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST0_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I1
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST1_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST1_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I2
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST2_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST2_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I3
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST3_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST3_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I4
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST4_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST4_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I5
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST5_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST5_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I6
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST6_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST6_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I7
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST7_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST7_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I8
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST8_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST8_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_I9
    `define VDATA  "../00_TESTBED/pattern/MY_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INST9_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INST9_O.dat"
    `define PAT_LEN 1000
    `define SEQ_LEN 1500
`elsif MY_MIX
    `define VDATA  "../00_TESTBED/pattern/MY_MIX_VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/MY_INSTMIX_I.dat"
    `define ODATA  "../00_TESTBED/pattern/MY_INSTMIX_O.dat"
    `define PAT_LEN 1024
    `define SEQ_LEN 1560
`else
    `define VDATA  "../00_TESTBED/pattern/VALID.dat"
    `define IDATA  "../00_TESTBED/pattern/INST0_I.dat"
    `define ODATA  "../00_TESTBED/pattern/INST0_O.dat"
    `define SEQ_LEN 60
    `define PAT_LEN 40
`endif


module testbench #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
) ();

    // Ports
    wire              clk;
    wire              rst_n;
    reg               in_valid;
    reg  [INST_W-1:0] inst;
    reg  [DATA_W-1:0] idata_a;
    reg  [DATA_W-1:0] idata_b;

    wire              busy;
    wire              out_valid;
    wire [DATA_W-1:0] odata;

    // TB variables
    reg                        valid_seq   [0:`SEQ_LEN-1];
    reg  [INST_W+2*DATA_W-1:0] input_data  [0:`PAT_LEN-1];
    reg  [         DATA_W-1:0] golden_data [0:`PAT_LEN-1];
    reg  [         DATA_W-1:0] out_ram     [0:`PAT_LEN-1];

    integer input_end, output_end, test_end;
    integer i, j, k;
    integer correct, error;

    initial begin
        $readmemb(`VDATA, valid_seq);
        $readmemb(`IDATA, input_data);
        $readmemb(`ODATA, golden_data);
    end

    clk_gen u_clk_gen (
        .clk   (clk  ),
        .rst   (     ),
        .rst_n (rst_n)
    );

    alu u_alu (
        .i_clk       (clk      ),
        .i_rst_n     (rst_n    ),
        .i_in_valid  (in_valid ),
        .o_busy      (busy     ),
        .i_inst      (inst     ),
        .i_data_a    (idata_a  ),
        .i_data_b    (idata_b  ),
        .o_out_valid (out_valid),
        .o_data      (odata    )
    );

    initial begin
       $fsdbDumpfile("alu.fsdb");
       $fsdbDumpvars(0, testbench, "+mda");
    end

    // Input
    initial begin
        input_end = 0;

        // reset
        wait (rst_n === 1'b0);
        in_valid =  1'b0;
        inst     =  4'b0;
        idata_a  = 16'b0;
        idata_b  = 16'b0;
        wait (rst_n === 1'b1);

        // start
        @(posedge clk);

        // loop
        i = 0; j = 0;
        while (i < `SEQ_LEN && j < `PAT_LEN) begin
            @(negedge clk);
            if (valid_seq[i]) begin
                if (!busy) begin
                    in_valid = 1'b1;
                    inst     = input_data[j][2*DATA_W +: INST_W];
                    idata_a  = input_data[j][  DATA_W +: DATA_W];
                    idata_b  = input_data[j][       0 +: DATA_W];
                    j = j+1;

                    i = i+1;
                end
                else begin
                    in_valid =  1'b0;
                    inst     =  4'bx;
                    idata_a  = 16'bx;
                    idata_b  = 16'bx;
                end
            end
            else begin
                in_valid =  1'b0;
                inst     =  4'bx;
                idata_a  = 16'bx;
                idata_b  = 16'bx;

                i = i+1;
            end
            @(posedge clk);
        end

        // final
        @(negedge clk);
        in_valid =  1'b0;
        inst     =  4'b0;
        idata_a  = 16'b0;
        idata_b  = 16'b0;

        input_end = 1;
    end

    // Output
    initial begin
        output_end = 0;

        // reset
        wait (rst_n === 1'b0);
        #(0.1 * `PERIOD);
        if (
            (busy      !== 1'b0           && busy      !== 1'b1          ) ||
            (out_valid !== 1'b0           && out_valid !== 1'b1          ) ||
            (odata     !== {DATA_W{1'b0}} && odata     !== {DATA_W{1'b1}})
        ) begin
            $display("Reset: Error! Output not reset to 0 or 1");
        end
        wait (rst_n === 1'b1);

        // start
        @(posedge clk);

        // loop
        k = 0;
        while (k < `PAT_LEN) begin
            @(negedge clk);
            if (out_valid === 1) begin
                out_ram[k] = odata;
                k = k+1;
            end
            @(posedge clk);
        end

        // final
        @(negedge clk);
        output_end = 1;
    end

    // Result
    initial begin
        wait (input_end && output_end);

        $display("Compute finished, start validating result...");
        validate();
        $display("Simulation finish");
        # (2 * `PERIOD);
        $finish;
    end

    integer errors, total_errors;
    task validate; begin
        total_errors = 0;
        $display("===============================================================================");
        $display("Instruction: %b", input_data[0][2*DATA_W +: INST_W]);
        $display("===============================================================================");

        errors = 0;
        for(i = 0; i < `PAT_LEN; i = i + 1)
            if(golden_data[i] !== out_ram[i]) begin
                $display("[ERROR  ]   [%d] Your Result:%16b Golden:%16b", i, out_ram[i], golden_data[i]);
                errors = errors + 1;
            end
            else begin
                $display("[CORRECT]   [%d] Your Result:%16b Golden:%16b", i, out_ram[i], golden_data[i]);
            end
        if(errors == 0)
            $display("Data             [PASS]");
        else
            $display("Data             [FAIL]");
		total_errors = total_errors + errors;
            
        if(total_errors == 0)
            $display(">>> Congratulation! All result are correct");
        else
            $display(">>> There are %d errors QQ", total_errors);
            
        $display("===============================================================================");
    end
    endtask

endmodule


module clk_gen (
    output reg clk,
    output reg rst,
    output reg rst_n
);

    always #(`PERIOD / 2.0) clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b0; rst_n = 1'b1; #(              0.25  * `PERIOD);
        rst = 1'b1; rst_n = 1'b0; #((`RST_DELAY - 0.25) * `PERIOD);
        rst = 1'b0; rst_n = 1'b1; #(         `MAX_CYCLE * `PERIOD);
        $display("Error! Time limit exceeded!");
        $finish;
    end

endmodule
