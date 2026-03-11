// ============================================================
// execution_units.v - Integer ALU, Multiplier, Divider, BRU
// Pipelined integer execution units for OoO core
// ============================================================
`timescale 1ns/1ps

module execution_units #(
    parameter XLEN      = 64,
    parameter PREG_BITS = 7,
    parameter ROB_BITS  = 7
)(
    input  wire                 clk,
    input  wire                 rst_n,

    // ALU port
    input  wire                 alu_valid,
    input  wire [5:0]           alu_op,
    input  wire [XLEN-1:0]      alu_src1,
    input  wire [XLEN-1:0]      alu_src2,
    input  wire [PREG_BITS-1:0] alu_prd,
    input  wire [ROB_BITS-1:0]  alu_rob_tag,
    output reg                  alu_result_valid,
    output reg  [XLEN-1:0]      alu_result,
    output reg  [PREG_BITS-1:0] alu_result_prd,
    output reg  [ROB_BITS-1:0]  alu_result_rob_tag,

    // MUL port (3-cycle pipelined)
    input  wire                 mul_valid,
    input  wire [1:0]           mul_op,  // MUL, MULH, MULHU, MULHSU
    input  wire [XLEN-1:0]      mul_src1,
    input  wire [XLEN-1:0]      mul_src2,
    input  wire [PREG_BITS-1:0] mul_prd,
    input  wire [ROB_BITS-1:0]  mul_rob_tag,
    output reg                  mul_result_valid,
    output reg  [XLEN-1:0]      mul_result,
    output reg  [PREG_BITS-1:0] mul_result_prd,
    output reg  [ROB_BITS-1:0]  mul_result_rob_tag,

    // DIV port (iterative, ~34-66 cycles)
    input  wire                 div_valid,
    input  wire [1:0]           div_op,  // DIV, DIVU, REM, REMU
    input  wire [XLEN-1:0]      div_src1,
    input  wire [XLEN-1:0]      div_src2,
    input  wire [PREG_BITS-1:0] div_prd,
    input  wire [ROB_BITS-1:0]  div_rob_tag,
    output reg                  div_result_valid,
    output reg  [XLEN-1:0]      div_result,
    output reg  [PREG_BITS-1:0] div_result_prd,
    output reg  [ROB_BITS-1:0]  div_result_rob_tag,
    output wire                 div_busy,

    // BRU port
    input  wire                 bru_valid,
    input  wire [2:0]           bru_funct3,
    input  wire [XLEN-1:0]      bru_src1,
    input  wire [XLEN-1:0]      bru_src2,
    input  wire [38:0]          bru_pc,
    input  wire [XLEN-1:0]      bru_imm,
    input  wire [PREG_BITS-1:0] bru_prd,
    input  wire [ROB_BITS-1:0]  bru_rob_tag,
    input  wire                 bru_pred_taken,
    input  wire [38:0]          bru_pred_target,
    output reg                  bru_result_valid,
    output reg  [XLEN-1:0]      bru_result,
    output reg  [38:0]          bru_target,
    output reg                  bru_taken,
    output reg                  bru_mispred,
    output reg  [PREG_BITS-1:0] bru_result_prd,
    output reg  [ROB_BITS-1:0]  bru_result_rob_tag
);

    // -------------------------------------------------------
    // Integer ALU (single cycle)
    // -------------------------------------------------------
    localparam ALU_ADD=6'd0, ALU_SUB=6'd1, ALU_AND=6'd2, ALU_OR=6'd3;
    localparam ALU_XOR=6'd4, ALU_SLL=6'd5, ALU_SRL=6'd6, ALU_SRA=6'd7;
    localparam ALU_SLT=6'd8, ALU_SLTU=6'd9, ALU_LUI=6'd10, ALU_AUIPC=6'd11;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_valid <= 1'b0;
        end else begin
            alu_result_valid  <= alu_valid;
            alu_result_prd    <= alu_prd;
            alu_result_rob_tag<= alu_rob_tag;
            case (alu_op)
                ALU_ADD:  alu_result <= alu_src1 + alu_src2;
                ALU_SUB:  alu_result <= alu_src1 - alu_src2;
                ALU_AND:  alu_result <= alu_src1 & alu_src2;
                ALU_OR:   alu_result <= alu_src1 | alu_src2;
                ALU_XOR:  alu_result <= alu_src1 ^ alu_src2;
                ALU_SLL:  alu_result <= alu_src1 << alu_src2[5:0];
                ALU_SRL:  alu_result <= alu_src1 >> alu_src2[5:0];
                ALU_SRA:  alu_result <= $signed(alu_src1) >>> alu_src2[5:0];
                ALU_SLT:  alu_result <= {{(XLEN-1){1'b0}}, ($signed(alu_src1) < $signed(alu_src2))};
                ALU_SLTU: alu_result <= {{(XLEN-1){1'b0}}, (alu_src1 < alu_src2)};
                ALU_LUI:  alu_result <= alu_src2;
                ALU_AUIPC:alu_result <= alu_src1 + alu_src2;
                default:  alu_result <= alu_src1 + alu_src2;
            endcase
        end
    end

    // -------------------------------------------------------
    // Multiplier (3-cycle pipeline using Booth encoding)
    // -------------------------------------------------------
    reg [XLEN-1:0]       mul_p1, mul_p2, mul_p3;
    reg [1:0]            mul_op_p1, mul_op_p2;
    reg [PREG_BITS-1:0]  mul_prd_p1, mul_prd_p2;
    reg [ROB_BITS-1:0]   mul_rob_p1, mul_rob_p2;
    reg                  mul_v1, mul_v2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_v1 <= 0; mul_v2 <= 0; mul_result_valid <= 0;
        end else begin
            // Stage 1: partial products
            mul_v1      <= mul_valid;
            mul_op_p1   <= mul_op;
            mul_prd_p1  <= mul_prd;
            mul_rob_p1  <= mul_rob_tag;
            mul_p1      <= mul_src1 * mul_src2; // Simplified; real uses Booth

            // Stage 2: accumulate
            mul_v2      <= mul_v1;
            mul_op_p2   <= mul_op_p1;
            mul_prd_p2  <= mul_prd_p1;
            mul_rob_p2  <= mul_rob_p1;
            mul_p2      <= mul_p1;

            // Stage 3: output
            mul_result_valid <= mul_v2;
            mul_result_prd   <= mul_prd_p2;
            mul_result_rob_tag <= mul_rob_p2;
            case (mul_op_p2)
                2'b00: mul_result <= mul_p2[XLEN-1:0];        // MUL
                2'b01: mul_result <= $signed(mul_p2) >>> XLEN; // MULH (approx)
                2'b10: mul_result <= mul_p2 >> XLEN;           // MULHU
                2'b11: mul_result <= mul_p2 >> XLEN;           // MULHSU
            endcase
        end
    end

    // -------------------------------------------------------
    // Divider (non-restoring iterative, 64-cycle worst case)
    // -------------------------------------------------------
    reg [XLEN-1:0]      div_dividend, div_divisor;
    reg [XLEN:0]        div_partial;
    reg [5:0]           div_count;
    reg                 div_active;
    reg [1:0]           div_op_latch;
    reg [PREG_BITS-1:0] div_prd_latch;
    reg [ROB_BITS-1:0]  div_rob_latch;
    reg                 div_sign;
    reg [XLEN-1:0]      div_quotient;

    assign div_busy = div_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_active <= 1'b0;
            div_result_valid <= 1'b0;
        end else begin
            div_result_valid <= 1'b0;
            if (!div_active && div_valid) begin
                div_active   <= 1'b1;
                div_count    <= 6'd0;
                div_op_latch <= div_op;
                div_prd_latch<= div_prd;
                div_rob_latch<= div_rob_tag;
                div_sign     <= div_src1[XLEN-1] ^ div_src2[XLEN-1];
                div_dividend <= (div_op[0] == 1'b0 && div_src1[XLEN-1]) ? (~div_src1 + 1) : div_src1;
                div_divisor  <= (div_op[0] == 1'b0 && div_src2[XLEN-1]) ? (~div_src2 + 1) : div_src2;
                div_partial  <= {(XLEN+1){1'b0}};
                div_quotient <= {XLEN{1'b0}};
            end else if (div_active) begin
                // Simple shift-subtract
                div_partial  <= {div_partial[XLEN-1:0], div_dividend[XLEN-1]};
                div_dividend <= {div_dividend[XLEN-2:0], 1'b0};
                if (div_partial[XLEN:0] >= {1'b0, div_divisor}) begin
                    div_partial  <= div_partial - {1'b0, div_divisor};
                    div_quotient <= {div_quotient[XLEN-2:0], 1'b1};
                end else begin
                    div_quotient <= {div_quotient[XLEN-2:0], 1'b0};
                end
                div_count <= div_count + 1;
                if (div_count == 6'd63) begin
                    div_active <= 1'b0;
                    div_result_valid   <= 1'b1;
                    div_result_prd     <= div_prd_latch;
                    div_result_rob_tag <= div_rob_latch;
                    case (div_op_latch)
                        2'b00: div_result <= (div_sign) ? (~div_quotient + 1) : div_quotient; // DIV
                        2'b01: div_result <= div_quotient; // DIVU
                        2'b10: div_result <= (div_sign && div_src1[XLEN-1]) ? (~div_partial[XLEN-1:0] + 1) : div_partial[XLEN-1:0]; // REM
                        2'b11: div_result <= div_partial[XLEN-1:0]; // REMU
                    endcase
                end
            end
        end
    end

    // -------------------------------------------------------
    // Branch Resolution Unit
    // -------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bru_result_valid <= 1'b0;
        end else begin
            bru_result_valid  <= bru_valid;
            bru_result_prd    <= bru_prd;
            bru_result_rob_tag<= bru_rob_tag;
            bru_result        <= bru_pc + 4; // link address
            if (bru_valid) begin
                case (bru_funct3)
                    3'b000: bru_taken <= ($signed(bru_src1) == $signed(bru_src2)); // BEQ
                    3'b001: bru_taken <= ($signed(bru_src1) != $signed(bru_src2)); // BNE
                    3'b100: bru_taken <= ($signed(bru_src1) <  $signed(bru_src2)); // BLT
                    3'b101: bru_taken <= ($signed(bru_src1) >= $signed(bru_src2)); // BGE
                    3'b110: bru_taken <= (bru_src1 < bru_src2);                    // BLTU
                    3'b111: bru_taken <= (bru_src1 >= bru_src2);                   // BGEU
                    default: bru_taken <= 1'b0;
                endcase
                bru_target  <= bru_pc + bru_imm[38:0];
                bru_mispred <= (bru_taken != bru_pred_taken) ||
                               ((bru_taken) && (bru_pc + bru_imm[38:0] != bru_pred_target));
            end
        end
    end

endmodule
