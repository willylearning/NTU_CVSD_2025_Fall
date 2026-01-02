module core #( // DO NOT MODIFY INTERFACE!!!
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) ( 
    input i_clk,
    input i_rst_n,

    // Testbench IOs
    output [2:0] o_status, 
    output       o_status_valid,

    // Memory IOs
    output [ADDR_WIDTH-1:0] o_addr,
    output [DATA_WIDTH-1:0] o_wdata,
    output                  o_we,
    input  [DATA_WIDTH-1:0] i_rdata
);

// FSM State Definition
parameter IDLE = 3'd0, FETCHING = 3'd1, FETCHING2 = 3'd2, DECODING = 3'd3, ALU_LOAD = 3'd4, WRITEBACK = 3'd5, PC_GEN = 3'd6, PROCESS_END = 3'd7;
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
// FSM state
reg [2:0] state, next_state;
// Instruction register
reg [DATA_WIDTH-1:0] inst_reg;
wire [6:0] opcode;
reg [2:0] inst_type;
reg [2:0] funct3;
reg [6:0] funct7;
reg [4:0] r1, r2, rd;
reg signed [DATA_WIDTH-1:0] imm;

// Program counter
reg [DATA_WIDTH-1:0] pc, next_pc;
reg pc_invalid_flag;
wire do_branch_flag;

// output status
reg [2:0] o_status_r, o_status_w;
reg o_status_valid_r, o_status_valid_w;

// Register file wires
wire signed [DATA_WIDTH-1:0] int_rdata1, int_rdata2;
wire signed [DATA_WIDTH-1:0] f_rdata1, f_rdata2;
wire int_en, f_en;
wire signed [DATA_WIDTH-1:0] wdata;

reg_file #(
    .DATA_WIDTH(DATA_WIDTH)
) int_reg_file (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .r1(r1),
    .r2(r2),
    .rd(rd),
    .wdata(wdata),
    .we(int_en),
    .rdata1(int_rdata1),
    .rdata2(int_rdata2)
);

reg_file #(
    .DATA_WIDTH(DATA_WIDTH)
) float_reg_file (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .r1(r1),
    .r2(r2),
    .rd(rd),
    .wdata(wdata),
    .we(f_en),
    .rdata1(f_rdata1),
    .rdata2(f_rdata2)
);

// ALU wires
wire floating_flag1;
wire floating_flag2;
wire signed [DATA_WIDTH-1:0] alu_in1, alu_in2;
wire signed [DATA_WIDTH-1:0] alu_out;
wire alu_invalid_flag;

alu #(
    .DATA_WIDTH(DATA_WIDTH)
) u_alu (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .r1(alu_in1),
    .r2(alu_in2),
    .imm(imm),
    .pc(pc),
    .alu_out(alu_out),
    .invalid_flag(alu_invalid_flag),
    .do_branch_flag(do_branch_flag)
);

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign opcode = inst_reg[6:0];

// alu input selection
assign floating_flag1 = (opcode == `OP_FSUB || opcode == `OP_FMUL || opcode == `OP_FCVTWS || opcode == `OP_FCLASS); // Actually, these 4 instructions use same opcode
assign floating_flag2 = (floating_flag1 || opcode == `OP_FLW || opcode == `OP_FSW); 
assign alu_in1 = floating_flag1 ? f_rdata1 : int_rdata1;
assign alu_in2 = floating_flag2 ? f_rdata2 : int_rdata2;

// register file write data and enable signal
assign wdata = (opcode == `OP_LW || opcode == `OP_FLW) ? i_rdata : alu_out; // load => wdata = i_rdata, others => wdata = alu_out
assign int_en = (state == WRITEBACK && (inst_type != `B_TYPE && inst_type != `S_TYPE)) ? 
                (!floating_flag2 || (opcode == `OP_FCVTWS && funct7 == `FUNCT7_FCVTWS) || (opcode == `OP_FCLASS && funct7 == `FUNCT7_FCLASS)) : 0;
assign f_en = (state == WRITEBACK && (inst_type != `B_TYPE && inst_type != `S_TYPE)) ? ~(!floating_flag2 || (opcode == `OP_FCVTWS && funct7 == `FUNCT7_FCVTWS) || (opcode == `OP_FCLASS && funct7 == `FUNCT7_FCLASS)) : 0;

// Output assignments
assign o_status = o_status_r;
assign o_status_valid = o_status_valid_r;
assign o_addr = (state == FETCHING) ? pc : alu_out;
assign o_wdata = (opcode == `OP_FSW) ? f_rdata2 : (opcode == `OP_SW) ? int_rdata2 : 0; // only store instruction will write to memory
assign o_we = (state == ALU_LOAD && !alu_invalid_flag && !pc_invalid_flag && (inst_type == `S_TYPE)); // load => o_we = 0, store => o_we = 1

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

// Instruction Type Decoder
always @(*) begin
    case (opcode)
        `OP_SUB, `OP_FSUB: inst_type = `R_TYPE; // opcodes of `OP_SLT, `OP_SRL same as `OP_SUB, `OP_FMUL, `OP_FCVTWS, `OP_FCLASS same as `OP_FSUB
        `OP_ADDI, `OP_LW, `OP_JALR, `OP_FLW: inst_type = `I_TYPE;
        `OP_SW, `OP_FSW: inst_type = `S_TYPE;
        `OP_BEQ: inst_type = `B_TYPE; // opcode of `OP_BLT same as `OP_BEQ
        `OP_AUIPC: inst_type = `U_TYPE;
        `OP_EOF: inst_type = `EOF_TYPE;
        default: inst_type = `INVALID_TYPE;
    endcase
end

// Instruction mapping for funct3, funct7, r1, r2, rd, imm
always @(*) begin 
    funct3 = 0;
    funct7 = 0;
    r1 = 0;
    r2 = 0;
    rd = 0;
    imm = 0;
    case (inst_type)
        `R_TYPE: begin
            funct3 = inst_reg[14:12];
            funct7 = inst_reg[31:25];
            r1 = inst_reg[19:15];
            r2 = inst_reg[24:20];
            rd = inst_reg[11:7];
            imm = 0;
        end
        `I_TYPE: begin
            funct3 = inst_reg[14:12];
            funct7 = 0;
            r1 = inst_reg[19:15];
            r2 = 0;
            rd = inst_reg[11:7];
            imm = {{20{inst_reg[31]}}, inst_reg[31:20]};
        end
        `S_TYPE: begin
            funct3 = inst_reg[14:12];
            funct7 = 0;
            r1 = inst_reg[19:15];
            r2 = inst_reg[24:20];
            rd = 0;
            imm = {{20{inst_reg[31]}}, inst_reg[31:25], inst_reg[11:7]};
        end
        `B_TYPE: begin
            funct3 = inst_reg[14:12];
            funct7 = 0;
            r1 = inst_reg[19:15];
            r2 = inst_reg[24:20];
            rd = 0;
            imm = {{20{inst_reg[31]}}, inst_reg[7], inst_reg[30:25], inst_reg[11:8], 1'b0};
        end
        `U_TYPE: begin
            funct3 = 0;
            funct7 = 0;
            r1 = 0;
            r2 = 0;
            rd = inst_reg[11:7];
            imm = {inst_reg[31:12], 12'b0};
        end
        `EOF_TYPE, `INVALID_TYPE: begin
            funct3 = 0;
            funct7 = 0;
            r1 = 0;
            r2 = 0;
            rd = 0;
            imm = 0;
        end
    endcase
end

// FSM Next State Logic
always @(*) begin
    case (state)
        IDLE: // 0
            next_state = FETCHING;
        FETCHING: // 1
            next_state = FETCHING2;
        FETCHING2: // 2, need one more cycle to get i_rdata
            next_state = DECODING;
        DECODING: begin // 3
            if (inst_type == `EOF_TYPE || inst_type == `INVALID_TYPE)
                next_state = PROCESS_END;
            else
                next_state = ALU_LOAD;
        end
        ALU_LOAD: begin // 4
            if (alu_invalid_flag) 
                next_state = PROCESS_END; // EOF, invalid instruction or alu error -> end process
            else
                next_state = WRITEBACK;
        end
        WRITEBACK: // 5
            next_state = PC_GEN;
        PC_GEN: begin // 6
            // if (inst_type == `EOF_TYPE || inst_type == `INVALID_TYPE || alu_invalid_flag || pc_invalid_flag)
            //     next_state = PROCESS_END;
            // else
            //     next_state = FETCHING;
            next_state = FETCHING;
        end
        PROCESS_END: // 7
            next_state = PROCESS_END; 
        default: 
            next_state = IDLE;
    endcase
end

// Program Counter Update
always @(*) begin
    if (state == PC_GEN) begin
        if ((opcode == `OP_BEQ || opcode == `OP_BLT) && do_branch_flag)
            next_pc = pc + imm; // if branch, $pc = $pc + imm
        else if (opcode == `OP_JALR)
            next_pc = (int_rdata1 + imm) & (~32'h1); // $pc = ($r1 + im) & (~0x1)
        else
            next_pc = pc + 4; // Next sequential instruction
    end
    else begin
        next_pc = pc; // Hold current PC
    end
    pc_invalid_flag = (next_pc >= 4096 || next_pc < 0) ? 1 : 0;
end

// o_status and o_status_valid update
always @(*) begin
    o_status_valid_w = 0;
    o_status_w = 0;
    if (state == PC_GEN) begin
        o_status_valid_w = 1;
        o_status_w = (pc_invalid_flag) ? `INVALID_TYPE : inst_type;
    end
    else if (state == ALU_LOAD && alu_invalid_flag) begin
        o_status_valid_w = 1;
        o_status_w = `INVALID_TYPE;
    end
    else if (state == DECODING && (inst_type == `EOF_TYPE || inst_type == `INVALID_TYPE)) begin
        o_status_valid_w = 1;
        o_status_w = inst_type; 
    end
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
// FSM state transition
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// Instruction register update
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        inst_reg <= 0;
    else if (state == FETCHING2)
        inst_reg <= i_rdata;
end

// Program counter update
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n)
        pc <= 0;
    else if (state == PC_GEN)
        pc <= next_pc;
end

// o_status and o_status_valid update
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_status_r <= 0;
        o_status_valid_r <= 0;
    end
    else begin
        o_status_r <= o_status_w;
        o_status_valid_r <= o_status_valid_w;   
    end
end

endmodule