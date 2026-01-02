// DO NOT MODIFY THIS FILE
// status definition
`define R_TYPE 0
`define I_TYPE 1
`define S_TYPE 2
`define B_TYPE 3
`define U_TYPE 4
`define INVALID_TYPE 5
`define EOF_TYPE 6

// opcode definition
`define OP_SUB    7'b0110011
`define OP_ADDI   7'b0010011
`define OP_LW     7'b0000011
`define OP_SW     7'b0100011
`define OP_BEQ    7'b1100011
`define OP_BLT    7'b1100011
`define OP_JALR   7'b1100111
`define OP_AUIPC  7'b0010111
`define OP_SLT    7'b0110011
`define OP_SRL    7'b0110011
`define OP_FSUB   7'b1010011
`define OP_FMUL   7'b1010011
`define OP_FCVTWS 7'b1010011
`define OP_FLW    7'b0000111
`define OP_FSW    7'b0100111
`define OP_FCLASS 7'b1010011
`define OP_EOF    7'b1110011

// funct7 definition
`define FUNCT7_SUB    7'b0100000
`define FUNCT7_SLT    7'b0000000
`define FUNCT7_SRL    7'b0000000
`define FUNCT7_FSUB   7'b0000100
`define FUNCT7_FMUL   7'b0001000
`define FUNCT7_FCVTWS 7'b1100000
`define FUNCT7_FCLASS 7'b1110000

// funct3 definition
`define FUNCT3_SUB    3'b000
`define FUNCT3_ADDI   3'b000
`define FUNCT3_LW     3'b010
`define FUNCT3_SW     3'b010
`define FUNCT3_BEQ    3'b000
`define FUNCT3_BLT    3'b100
`define FUNCT3_JALR   3'b000
`define FUNCT3_SLT    3'b010
`define FUNCT3_SRL    3'b101
`define FUNCT3_FSUB   3'b000
`define FUNCT3_FMUL   3'b000
`define FUNCT3_FCVTWS 3'b000
`define FUNCT3_FLW    3'b010
`define FUNCT3_FSW    3'b010
`define FUNCT3_FCLASS 3'b000

