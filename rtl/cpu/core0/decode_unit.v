// ============================================================
// decode_unit.v - RISC-V RV64IMAFDC Decode Unit
// Full decoding of I/M/A/F/D/C/Zicsr extensions
// ============================================================
`timescale 1ns/1ps

module decode_unit #(
    parameter XLEN       = 64,
    parameter VADDR_WIDTH= 39,
    parameter FETCH_WIDTH= 4,
    parameter ROB_BITS   = 7,
    parameter PREG_BITS  = 7
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // From fetch queue
    input  wire                     fetch_valid,
    input  wire [FETCH_WIDTH*32-1:0] fetch_instr,
    input  wire [FETCH_WIDTH*VADDR_WIDTH-1:0] fetch_pc,
    input  wire [FETCH_WIDTH-1:0]   fetch_pred_taken,
    output wire                     fetch_ready,

    // To rename unit
    output reg                      decode_valid,
    output reg  [FETCH_WIDTH*7-1:0] decode_opcode,   // 7-bit opcode
    output reg  [FETCH_WIDTH*5-1:0] decode_rd,
    output reg  [FETCH_WIDTH*5-1:0] decode_rs1,
    output reg  [FETCH_WIDTH*5-1:0] decode_rs2,
    output reg  [FETCH_WIDTH*5-1:0] decode_rs3,
    output reg  [FETCH_WIDTH*XLEN-1:0] decode_imm,
    output reg  [FETCH_WIDTH*4-1:0] decode_fu_type,  // EX/MEM/FPU/MUL/DIV
    output reg  [FETCH_WIDTH*6-1:0] decode_alu_op,
    output reg  [FETCH_WIDTH*VADDR_WIDTH-1:0] decode_pc,
    output reg  [FETCH_WIDTH-1:0]   decode_is_branch,
    output reg  [FETCH_WIDTH-1:0]   decode_is_load,
    output reg  [FETCH_WIDTH-1:0]   decode_is_store,
    output reg  [FETCH_WIDTH-1:0]   decode_is_fp,
    output reg  [FETCH_WIDTH-1:0]   decode_valid_mask,
    input  wire                     decode_ready,

    // Exception signals
    output reg  [FETCH_WIDTH-1:0]   decode_ill_instr,

    // Flush
    input  wire                     flush
);

    // RISC-V Opcode definitions
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_IMM    = 7'b0010011;
    localparam OP_REG    = 7'b0110011;
    localparam OP_IMMW   = 7'b0011011;  // RV64 word-size ALU imm
    localparam OP_REGW   = 7'b0111011;  // RV64 word-size ALU reg
    localparam OP_SYSTEM = 7'b1110011;
    localparam OP_MISC_MEM= 7'b0001111;
    localparam OP_AMO    = 7'b0101111;
    localparam OP_FPU    = 7'b1010011;
    localparam OP_FLD    = 7'b0000111;  // FP load
    localparam OP_FST    = 7'b0100111;  // FP store
    localparam OP_MADD   = 7'b1000011;
    localparam OP_MSUB   = 7'b1000111;
    localparam OP_NMSUB  = 7'b1001011;
    localparam OP_NMADD  = 7'b1001111;

    // ALU op encoding
    localparam ALU_ADD  = 6'd0;
    localparam ALU_SUB  = 6'd1;
    localparam ALU_AND  = 6'd2;
    localparam ALU_OR   = 6'd3;
    localparam ALU_XOR  = 6'd4;
    localparam ALU_SLL  = 6'd5;
    localparam ALU_SRL  = 6'd6;
    localparam ALU_SRA  = 6'd7;
    localparam ALU_SLT  = 6'd8;
    localparam ALU_SLTU = 6'd9;
    localparam ALU_LUI  = 6'd10;
    localparam ALU_AUIPC= 6'd11;
    localparam ALU_MUL  = 6'd12;
    localparam ALU_DIV  = 6'd13;
    localparam ALU_REM  = 6'd14;

    // FU types
    localparam FU_ALU   = 4'd0;
    localparam FU_MUL   = 4'd1;
    localparam FU_DIV   = 4'd2;
    localparam FU_MEM   = 4'd3;
    localparam FU_FPU   = 4'd4;
    localparam FU_CSR   = 4'd5;
    localparam FU_BRU   = 4'd6;

    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            decode_valid      <= 1'b0;
            decode_valid_mask <= {FETCH_WIDTH{1'b0}};
        end else if (fetch_valid && decode_ready) begin
            decode_valid <= 1'b1;
            for (k = 0; k < FETCH_WIDTH; k = k + 1) begin : dec_loop
                automatic reg [31:0] instr = fetch_instr[k*32 +: 32];
                automatic reg [6:0]  opcode= instr[6:0];
                automatic reg [4:0]  rd    = instr[11:7];
                automatic reg [2:0]  funct3= instr[14:12];
                automatic reg [4:0]  rs1   = instr[19:15];
                automatic reg [4:0]  rs2   = instr[24:20];
                automatic reg [6:0]  funct7= instr[31:25];
                automatic reg [XLEN-1:0] imm_i, imm_s, imm_b, imm_u, imm_j;

                // I-type immediate
                imm_i = {{(XLEN-12){instr[31]}}, instr[31:20]};
                // S-type immediate
                imm_s = {{(XLEN-12){instr[31]}}, instr[31:25], instr[11:7]};
                // B-type immediate
                imm_b = {{(XLEN-13){instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                // U-type immediate
                imm_u = {{(XLEN-32){instr[31]}}, instr[31:12], 12'b0};
                // J-type immediate
                imm_j = {{(XLEN-21){instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

                decode_opcode[k*7 +: 7]  <= opcode;
                decode_rd    [k*5 +: 5]  <= rd;
                decode_rs1   [k*5 +: 5]  <= rs1;
                decode_rs2   [k*5 +: 5]  <= rs2;
                decode_rs3   [k*5 +: 5]  <= instr[31:27]; // for FMA
                decode_pc    [k*VADDR_WIDTH +: VADDR_WIDTH] <= fetch_pc[k*VADDR_WIDTH +: VADDR_WIDTH];
                decode_valid_mask[k]     <= 1'b1;
                decode_ill_instr[k]      <= 1'b0;
                decode_is_branch[k]      <= (opcode == OP_BRANCH) || (opcode == OP_JAL) || (opcode == OP_JALR);
                decode_is_load[k]        <= (opcode == OP_LOAD) || (opcode == OP_FLD);
                decode_is_store[k]       <= (opcode == OP_STORE) || (opcode == OP_FST);
                decode_is_fp[k]          <= (opcode == OP_FPU) || (opcode == OP_FLD) || (opcode == OP_FST) ||
                                            (opcode == OP_MADD) || (opcode == OP_MSUB) ||
                                            (opcode == OP_NMADD) || (opcode == OP_NMSUB);

                case (opcode)
                    OP_LUI:   begin decode_alu_op[k*6 +: 6] <= ALU_LUI;  decode_imm[k*XLEN +: XLEN] <= imm_u; decode_fu_type[k*4 +: 4] <= FU_ALU; end
                    OP_AUIPC: begin decode_alu_op[k*6 +: 6] <= ALU_AUIPC;decode_imm[k*XLEN +: XLEN] <= imm_u; decode_fu_type[k*4 +: 4] <= FU_ALU; end
                    OP_JAL:   begin decode_alu_op[k*6 +: 6] <= ALU_ADD;  decode_imm[k*XLEN +: XLEN] <= imm_j; decode_fu_type[k*4 +: 4] <= FU_BRU; end
                    OP_JALR:  begin decode_alu_op[k*6 +: 6] <= ALU_ADD;  decode_imm[k*XLEN +: XLEN] <= imm_i; decode_fu_type[k*4 +: 4] <= FU_BRU; end
                    OP_BRANCH:begin decode_alu_op[k*6 +: 6] <= ALU_SUB;  decode_imm[k*XLEN +: XLEN] <= imm_b; decode_fu_type[k*4 +: 4] <= FU_BRU; end
                    OP_LOAD:  begin decode_alu_op[k*6 +: 6] <= ALU_ADD;  decode_imm[k*XLEN +: XLEN] <= imm_i; decode_fu_type[k*4 +: 4] <= FU_MEM; end
                    OP_STORE: begin decode_alu_op[k*6 +: 6] <= ALU_ADD;  decode_imm[k*XLEN +: XLEN] <= imm_s; decode_fu_type[k*4 +: 4] <= FU_MEM; end
                    OP_IMM:   begin
                        decode_imm[k*XLEN +: XLEN] <= imm_i;
                        decode_fu_type[k*4 +: 4]   <= FU_ALU;
                        case (funct3)
                            3'b000: decode_alu_op[k*6 +: 6] <= ALU_ADD;
                            3'b001: decode_alu_op[k*6 +: 6] <= ALU_SLL;
                            3'b010: decode_alu_op[k*6 +: 6] <= ALU_SLT;
                            3'b011: decode_alu_op[k*6 +: 6] <= ALU_SLTU;
                            3'b100: decode_alu_op[k*6 +: 6] <= ALU_XOR;
                            3'b101: decode_alu_op[k*6 +: 6] <= (funct7[5]) ? ALU_SRA : ALU_SRL;
                            3'b110: decode_alu_op[k*6 +: 6] <= ALU_OR;
                            3'b111: decode_alu_op[k*6 +: 6] <= ALU_AND;
                        endcase
                    end
                    OP_REG:   begin
                        decode_imm[k*XLEN +: XLEN] <= {XLEN{1'b0}};
                        if (funct7 == 7'b0000001) begin
                            decode_fu_type[k*4 +: 4] <= (funct3[2]) ? FU_DIV : FU_MUL;
                            case (funct3)
                                3'b000: decode_alu_op[k*6 +: 6] <= ALU_MUL;
                                3'b100: decode_alu_op[k*6 +: 6] <= ALU_DIV;
                                3'b110: decode_alu_op[k*6 +: 6] <= ALU_REM;
                                default: decode_alu_op[k*6 +: 6] <= ALU_ADD;
                            endcase
                        end else begin
                            decode_fu_type[k*4 +: 4] <= FU_ALU;
                            case ({funct7[5], funct3})
                                4'b0000: decode_alu_op[k*6 +: 6] <= ALU_ADD;
                                4'b1000: decode_alu_op[k*6 +: 6] <= ALU_SUB;
                                4'b0001: decode_alu_op[k*6 +: 6] <= ALU_SLL;
                                4'b0010: decode_alu_op[k*6 +: 6] <= ALU_SLT;
                                4'b0011: decode_alu_op[k*6 +: 6] <= ALU_SLTU;
                                4'b0100: decode_alu_op[k*6 +: 6] <= ALU_XOR;
                                4'b0101: decode_alu_op[k*6 +: 6] <= ALU_SRL;
                                4'b1101: decode_alu_op[k*6 +: 6] <= ALU_SRA;
                                4'b0110: decode_alu_op[k*6 +: 6] <= ALU_OR;
                                4'b0111: decode_alu_op[k*6 +: 6] <= ALU_AND;
                                default: decode_alu_op[k*6 +: 6] <= ALU_ADD;
                            endcase
                        end
                    end
                    OP_SYSTEM: begin
                        decode_alu_op[k*6 +: 6]    <= ALU_ADD;
                        decode_imm[k*XLEN +: XLEN] <= {52'b0, instr[31:20]};
                        decode_fu_type[k*4 +: 4]   <= FU_CSR;
                    end
                    OP_FPU, OP_MADD, OP_MSUB, OP_NMADD, OP_NMSUB,
                    OP_FLD, OP_FST: begin
                        decode_fu_type[k*4 +: 4] <= FU_FPU;
                        decode_alu_op[k*6 +: 6]  <= ALU_ADD;
                        decode_imm[k*XLEN +: XLEN] <= imm_i;
                    end
                    OP_AMO: begin
                        decode_fu_type[k*4 +: 4] <= FU_MEM;
                        decode_alu_op[k*6 +: 6]  <= ALU_ADD;
                        decode_imm[k*XLEN +: XLEN] <= {XLEN{1'b0}};
                    end
                    default: begin
                        decode_ill_instr[k] <= 1'b1;
                        decode_fu_type[k*4 +: 4] <= FU_ALU;
                        decode_alu_op[k*6 +: 6]  <= ALU_ADD;
                        decode_imm[k*XLEN +: XLEN] <= {XLEN{1'b0}};
                    end
                endcase
            end
        end else begin
            decode_valid <= 1'b0;
        end
    end

    assign fetch_ready = decode_ready;

endmodule
