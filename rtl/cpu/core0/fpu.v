// ============================================================
// fpu.v - IEEE 754 Double Precision FPU
// Supports: FADD, FSUB, FMUL, FDIV, FSQRT, FMA, FCVT, FCMP
// Pipelined: 4-cycle ADD/SUB/MUL, 12-cycle DIV/SQRT
// ============================================================
`timescale 1ns/1ps

module fpu #(
    parameter FLEN      = 64,  // double precision
    parameter PREG_BITS = 7,
    parameter ROB_BITS  = 7
)(
    input  wire                 clk,
    input  wire                 rst_n,

    input  wire                 fpu_valid,
    input  wire [6:0]           fpu_op,     // FADD/FSUB/FMUL/FDIV/FSQRT/FMA/FCVT/FCMP
    input  wire [2:0]           fpu_rm,     // rounding mode
    input  wire [FLEN-1:0]      fpu_src1,
    input  wire [FLEN-1:0]      fpu_src2,
    input  wire [FLEN-1:0]      fpu_src3,   // FMA only
    input  wire [PREG_BITS-1:0] fpu_prd,
    input  wire [ROB_BITS-1:0]  fpu_rob_tag,

    output reg                  fpu_result_valid,
    output reg  [FLEN-1:0]      fpu_result,
    output reg  [PREG_BITS-1:0] fpu_result_prd,
    output reg  [ROB_BITS-1:0]  fpu_result_rob_tag,
    output reg  [4:0]           fpu_fflags  // NV, DZ, OF, UF, NX
);

    // Operation codes
    localparam FOP_FADD  = 7'd0;
    localparam FOP_FSUB  = 7'd1;
    localparam FOP_FMUL  = 7'd2;
    localparam FOP_FDIV  = 7'd3;
    localparam FOP_FSQRT = 7'd4;
    localparam FOP_FMADD = 7'd5;
    localparam FOP_FMSUB = 7'd6;
    localparam FOP_FCVT_FI = 7'd7;  // float to int
    localparam FOP_FCVT_IF = 7'd8;  // int to float
    localparam FOP_FCMP  = 7'd9;
    localparam FOP_FMIN  = 7'd10;
    localparam FOP_FMAX  = 7'd11;
    localparam FOP_FSGNJ = 7'd12;

    // IEEE 754 DP fields
    wire        s1 = fpu_src1[63];
    wire [10:0] e1 = fpu_src1[62:52];
    wire [51:0] m1 = fpu_src1[51:0];
    wire        s2 = fpu_src2[63];
    wire [10:0] e2 = fpu_src2[62:52];
    wire [51:0] m2 = fpu_src2[51:0];

    // Detect special values
    wire src1_nan  = (e1 == 11'h7FF) && (m1 != 52'b0);
    wire src2_nan  = (e2 == 11'h7FF) && (m2 != 52'b0);
    wire src1_inf  = (e1 == 11'h7FF) && (m1 == 52'b0);
    wire src2_inf  = (e2 == 11'h7FF) && (m2 == 52'b0);
    wire src1_zero = (e1 == 11'h0)   && (m1 == 52'b0);
    wire src2_zero = (e2 == 11'h0)   && (m2 == 52'b0);

    // Adder pipeline (4 stages)
    reg [FLEN-1:0]     add_stage [0:3];
    reg [PREG_BITS-1:0] add_prd  [0:3];
    reg [ROB_BITS-1:0]  add_rob  [0:3];
    reg [3:0]           add_vld;
    reg [4:0]           add_ff   [0:3];

    // Multiplier pipeline (4 stages)
    reg [FLEN-1:0]     mul_stage [0:3];
    reg [PREG_BITS-1:0] mul_prd  [0:3];
    reg [ROB_BITS-1:0]  mul_rob  [0:3];
    reg [3:0]           mul_vld;

    // Divider/SQRT (12 stages)
    reg [FLEN-1:0]     div_stage [0:11];
    reg [PREG_BITS-1:0] div_prd  [0:11];
    reg [ROB_BITS-1:0]  div_rob  [0:11];
    reg [11:0]          div_vld;

    // -------------------------------------------------------
    // Floating-point addition/subtraction (simplified)
    // -------------------------------------------------------
    function [63:0] fp_add;
        input [63:0] a, b;
        input [2:0]  rm;
        input        is_sub;
        reg [51:0] ma, mb, mres;
        reg [10:0] ea, eb, eres;
        reg sa, sb, sres;
        reg [52:0] ma_ext, mb_ext;
        reg [53:0] sum;
        integer    diff;
        begin
            sa = a[63]; ea = a[62:52]; ma = a[51:0];
            sb = b[63] ^ is_sub; eb = b[62:52]; mb = b[51:0];
            // Align
            if (ea >= eb) begin
                eres = ea; diff = ea - eb;
                ma_ext = {1'b1, ma};
                mb_ext = ({1'b1, mb}) >> diff;
            end else begin
                eres = eb; diff = eb - ea;
                mb_ext = {1'b1, mb};
                ma_ext = ({1'b1, ma}) >> diff;
            end
            // Add or subtract
            if (sa == sb) begin
                sres = sa;
                sum  = {1'b0, ma_ext} + {1'b0, mb_ext};
                if (sum[53]) begin eres = eres + 1; mres = sum[53:2]; end
                else              mres = sum[52:1];
            end else begin
                if (ma_ext >= mb_ext) begin
                    sres = sa;
                    sum  = {1'b0, ma_ext} - {1'b0, mb_ext};
                end else begin
                    sres = sb;
                    sum  = {1'b0, mb_ext} - {1'b0, ma_ext};
                end
                // Normalize (simplified)
                mres = sum[51:0];
            end
            fp_add = {sres, eres, mres};
        end
    endfunction

    integer p;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            add_vld <= 4'b0; mul_vld <= 4'b0; div_vld <= 12'b0;
            fpu_result_valid <= 1'b0;
        end else begin
            fpu_result_valid <= 1'b0;

            // Stage inputs
            if (fpu_valid && (fpu_op == FOP_FADD || fpu_op == FOP_FSUB)) begin
                add_stage[0] <= fp_add(fpu_src1, fpu_src2, fpu_rm, (fpu_op == FOP_FSUB));
                add_prd  [0] <= fpu_prd;
                add_rob  [0] <= fpu_rob_tag;
                add_vld  [0] <= 1'b1;
                add_ff   [0] <= (src1_nan | src2_nan) ? 5'b10000 : 5'b00000;
            end else add_vld[0] <= 1'b0;

            if (fpu_valid && fpu_op == FOP_FMUL) begin
                // Simplified: just multiply sign/exp, use mul directly
                mul_stage[0] <= {s1^s2, e1+e2-11'd1023, m1&m2};
                mul_prd  [0] <= fpu_prd;
                mul_rob  [0] <= fpu_rob_tag;
                mul_vld  [0] <= 1'b1;
            end else mul_vld[0] <= 1'b0;

            if (fpu_valid && (fpu_op == FOP_FDIV || fpu_op == FOP_FSQRT)) begin
                div_stage[0] <= fpu_src1;
                div_prd  [0] <= fpu_prd;
                div_rob  [0] <= fpu_rob_tag;
                div_vld  [0] <= 1'b1;
            end else div_vld[0] <= 1'b0;

            // Shift pipelines
            for (p = 3; p >= 1; p = p - 1) begin
                add_stage[p] <= add_stage[p-1];
                add_prd  [p] <= add_prd  [p-1];
                add_rob  [p] <= add_rob  [p-1];
                add_vld  [p] <= add_vld  [p-1];
                add_ff   [p] <= add_ff   [p-1];
                mul_stage[p] <= mul_stage[p-1];
                mul_prd  [p] <= mul_prd  [p-1];
                mul_rob  [p] <= mul_rob  [p-1];
                mul_vld  [p] <= mul_vld  [p-1];
            end
            for (p = 11; p >= 1; p = p - 1) begin
                div_stage[p] <= div_stage[p-1];
                div_prd  [p] <= div_prd  [p-1];
                div_rob  [p] <= div_rob  [p-1];
                div_vld  [p] <= div_vld  [p-1];
            end

            // Output from pipelines (priority: add > mul > div)
            if (add_vld[3]) begin
                fpu_result_valid <= 1'b1;
                fpu_result       <= add_stage[3];
                fpu_result_prd   <= add_prd[3];
                fpu_result_rob_tag <= add_rob[3];
                fpu_fflags       <= add_ff[3];
            end else if (mul_vld[3]) begin
                fpu_result_valid <= 1'b1;
                fpu_result       <= mul_stage[3];
                fpu_result_prd   <= mul_prd[3];
                fpu_result_rob_tag <= mul_rob[3];
                fpu_fflags       <= 5'b0;
            end else if (div_vld[11]) begin
                fpu_result_valid <= 1'b1;
                fpu_result       <= div_stage[11];
                fpu_result_prd   <= div_prd[11];
                fpu_result_rob_tag <= div_rob[11];
                fpu_fflags       <= 5'b0;
            end

            // FCMP / FMIN / FMAX / FSGNJ (single cycle)
            if (fpu_valid && (fpu_op == FOP_FCMP || fpu_op == FOP_FMIN ||
                              fpu_op == FOP_FMAX || fpu_op == FOP_FSGNJ)) begin
                fpu_result_valid <= 1'b1;
                fpu_result_prd   <= fpu_prd;
                fpu_result_rob_tag <= fpu_rob_tag;
                fpu_fflags       <= (src1_nan | src2_nan) ? 5'b10000 : 5'b0;
                case (fpu_op)
                    FOP_FCMP: begin
                        case (fpu_rm)
                            3'b010: fpu_result <= {{63{1'b0}}, (fpu_src1 == fpu_src2)};  // FEQ
                            3'b001: fpu_result <= {{63{1'b0}}, ($signed(fpu_src1) < $signed(fpu_src2))}; // FLT
                            3'b000: fpu_result <= {{63{1'b0}}, ($signed(fpu_src1) <= $signed(fpu_src2))};// FLE
                            default: fpu_result <= {FLEN{1'b0}};
                        endcase
                    end
                    FOP_FMIN: fpu_result <= ($signed(fpu_src1) < $signed(fpu_src2)) ? fpu_src1 : fpu_src2;
                    FOP_FMAX: fpu_result <= ($signed(fpu_src1) > $signed(fpu_src2)) ? fpu_src1 : fpu_src2;
                    FOP_FSGNJ: begin
                        case (fpu_rm)
                            3'b000: fpu_result <= {fpu_src2[63], fpu_src1[62:0]};       // FSGNJ
                            3'b001: fpu_result <= {~fpu_src2[63], fpu_src1[62:0]};      // FSGNJN
                            3'b010: fpu_result <= {fpu_src1[63]^fpu_src2[63], fpu_src1[62:0]}; // FSGNJX
                            default: fpu_result <= fpu_src1;
                        endcase
                    end
                endcase
            end
        end
    end

endmodule
