module reg_file #(
    parameter DATA_WIDTH = 32
) (
    input         i_clk,
    input         i_rst_n,
    input  [4:0]  r1,  
    input  [4:0]  r2,
    input  [4:0]  rd,
    input signed [DATA_WIDTH-1:0] wdata,
    input         we, // write enable
    output signed [DATA_WIDTH-1:0] rdata1,
    output signed [DATA_WIDTH-1:0] rdata2
);

    // 32 signed 32-bit registers
    reg signed [DATA_WIDTH-1:0] mem_reg [0:31];

    integer i;
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                mem_reg[i] <= 32'd0;
        end
        else if (we) begin
            mem_reg[rd] <= wdata;
        end
    end

    // Read
    assign rdata1  = mem_reg[r1];
    assign rdata2  = mem_reg[r2];

endmodule
