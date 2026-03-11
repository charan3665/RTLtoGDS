// ============================================================
// rename_unit.v - Register Rename Unit (RAT-based)
// Uses physical register file with free list, ROB tag assignment
// ============================================================
`timescale 1ns/1ps

module rename_unit #(
    parameter XLEN        = 64,
    parameter FETCH_WIDTH = 4,
    parameter ARCH_REGS   = 32,
    parameter PHYS_REGS   = 128,
    parameter ROB_ENTRIES = 128,
    parameter PREG_BITS   = 7,    // log2(PHYS_REGS)
    parameter ROB_BITS    = 7
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // From decode
    input  wire                     decode_valid,
    input  wire [FETCH_WIDTH*5-1:0] decode_rd,
    input  wire [FETCH_WIDTH*5-1:0] decode_rs1,
    input  wire [FETCH_WIDTH*5-1:0] decode_rs2,
    input  wire [FETCH_WIDTH*5-1:0] decode_rs3,
    input  wire [FETCH_WIDTH-1:0]   decode_valid_mask,
    output wire                     decode_ready,

    // Forwarded from decode
    input  wire [FETCH_WIDTH*7-1:0]  decode_opcode,
    input  wire [FETCH_WIDTH*6-1:0]  decode_alu_op,
    input  wire [FETCH_WIDTH*4-1:0]  decode_fu_type,
    input  wire [FETCH_WIDTH*XLEN-1:0] decode_imm,
    input  wire [FETCH_WIDTH-1:0]    decode_is_branch,
    input  wire [FETCH_WIDTH-1:0]    decode_is_load,
    input  wire [FETCH_WIDTH-1:0]    decode_is_store,
    input  wire [FETCH_WIDTH-1:0]    decode_is_fp,
    input  wire [FETCH_WIDTH*39-1:0] decode_pc,

    // To issue queue / ROB
    output reg                       rename_valid,
    output reg  [FETCH_WIDTH*PREG_BITS-1:0] rename_prd,
    output reg  [FETCH_WIDTH*PREG_BITS-1:0] rename_prs1,
    output reg  [FETCH_WIDTH*PREG_BITS-1:0] rename_prs2,
    output reg  [FETCH_WIDTH*PREG_BITS-1:0] rename_prs3,
    output reg  [FETCH_WIDTH-1:0]    rename_prs1_valid,
    output reg  [FETCH_WIDTH-1:0]    rename_prs2_valid,
    output reg  [FETCH_WIDTH*ROB_BITS-1:0]  rename_rob_tag,
    output reg  [FETCH_WIDTH*7-1:0]  rename_opcode,
    output reg  [FETCH_WIDTH*6-1:0]  rename_alu_op,
    output reg  [FETCH_WIDTH*4-1:0]  rename_fu_type,
    output reg  [FETCH_WIDTH*XLEN-1:0] rename_imm,
    output reg  [FETCH_WIDTH-1:0]    rename_is_branch,
    output reg  [FETCH_WIDTH-1:0]    rename_is_load,
    output reg  [FETCH_WIDTH-1:0]    rename_is_store,
    output reg  [FETCH_WIDTH*39-1:0] rename_pc,
    input  wire                      rename_ready,

    // ROB commit interface (for freelist reclaim)
    input  wire                      commit_valid,
    input  wire [PREG_BITS-1:0]      commit_old_prd,
    input  wire                      commit_stall,

    // Flush / recovery interface
    input  wire                      flush_valid,
    input  wire [ARCH_REGS*PREG_BITS-1:0] flush_rat_snapshot
);

    // Register Alias Table (RAT): arch_reg -> phys_reg
    reg [PREG_BITS-1:0]  rat [0:ARCH_REGS-1];
    reg [PREG_BITS-1:0]  old_rat [0:ARCH_REGS-1]; // for undo on mispredict

    // Free list as a circular FIFO
    reg [PREG_BITS-1:0]  freelist [0:PHYS_REGS-1];
    reg [$clog2(PHYS_REGS)-1:0] fl_head, fl_tail;
    reg [$clog2(PHYS_REGS):0]   fl_count;

    // ROB tail pointer
    reg [ROB_BITS-1:0]   rob_tail;

    // Busy bits
    reg [PHYS_REGS-1:0]  preg_busy;

    integer i;

    // Initialize RAT (arch reg i maps to phys reg i)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ARCH_REGS; i = i + 1) begin
                rat[i] <= i[PREG_BITS-1:0];
            end
            // Initialize free list: phys regs ARCH_REGS..PHYS_REGS-1
            for (i = 0; i < PHYS_REGS - ARCH_REGS; i = i + 1)
                freelist[i] <= (ARCH_REGS + i)[PREG_BITS-1:0];
            fl_head  <= 0;
            fl_tail  <= PHYS_REGS - ARCH_REGS;
            fl_count <= PHYS_REGS - ARCH_REGS;
            preg_busy<= {PHYS_REGS{1'b0}};
            rob_tail <= {ROB_BITS{1'b0}};
            rename_valid <= 1'b0;
        end else if (flush_valid) begin
            // Restore RAT from snapshot
            for (i = 0; i < ARCH_REGS; i = i + 1)
                rat[i] <= flush_rat_snapshot[i*PREG_BITS +: PREG_BITS];
            rename_valid <= 1'b0;
        end else if (decode_valid && rename_ready && !commit_stall) begin
            rename_valid <= 1'b1;
            for (i = 0; i < FETCH_WIDTH; i = i + 1) begin : ren_loop
                automatic reg [4:0] ard  = decode_rd [i*5 +: 5];
                automatic reg [4:0] ars1 = decode_rs1[i*5 +: 5];
                automatic reg [4:0] ars2 = decode_rs2[i*5 +: 5];
                automatic reg [4:0] ars3 = decode_rs3[i*5 +: 5];
                automatic reg [PREG_BITS-1:0] new_prd;

                if (decode_valid_mask[i] && (fl_count >= FETCH_WIDTH - i)) begin
                    // Allocate physical register
                    new_prd = freelist[fl_head];
                    fl_head  <= (fl_head + 1) % PHYS_REGS;
                    fl_count <= fl_count - 1;

                    rename_prd [i*PREG_BITS +: PREG_BITS] <= new_prd;
                    rename_prs1[i*PREG_BITS +: PREG_BITS] <= rat[ars1];
                    rename_prs2[i*PREG_BITS +: PREG_BITS] <= rat[ars2];
                    rename_prs3[i*PREG_BITS +: PREG_BITS] <= rat[ars3];
                    rename_prs1_valid[i]                   <= (ars1 != 5'd0);
                    rename_prs2_valid[i]                   <= (ars2 != 5'd0);
                    rename_rob_tag[i*ROB_BITS +: ROB_BITS] <= rob_tail + i;

                    // Update RAT
                    if (ard != 5'd0)
                        rat[ard] <= new_prd;
                    preg_busy[new_prd] <= 1'b1;
                end
            end
            rob_tail <= rob_tail + FETCH_WIDTH;

            // Copy forwarded signals
            rename_opcode    <= decode_opcode;
            rename_alu_op    <= decode_alu_op;
            rename_fu_type   <= decode_fu_type;
            rename_imm       <= decode_imm;
            rename_is_branch <= decode_is_branch;
            rename_is_load   <= decode_is_load;
            rename_is_store  <= decode_is_store;
            rename_pc        <= decode_pc;
        end else begin
            rename_valid <= 1'b0;
        end

        // Free list reclaim on commit
        if (commit_valid) begin
            freelist[fl_tail]  <= commit_old_prd;
            fl_tail            <= (fl_tail + 1) % PHYS_REGS;
            fl_count           <= fl_count + 1;
            preg_busy[commit_old_prd] <= 1'b0;
        end
    end

    assign decode_ready = rename_ready && !commit_stall && (fl_count >= FETCH_WIDTH);

endmodule
