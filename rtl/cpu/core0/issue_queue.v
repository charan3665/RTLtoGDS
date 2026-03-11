// ============================================================
// issue_queue.v - Unified Issue Queue (OoO scheduling)
// Age-based, wakeup + select, supports ALU/MEM/FPU/MUL/DIV
// ============================================================
`timescale 1ns/1ps

module issue_queue #(
    parameter IQ_ENTRIES  = 32,
    parameter PREG_BITS   = 7,
    parameter ROB_BITS    = 7,
    parameter XLEN        = 64,
    parameter FU_COUNT    = 6,   // ALU, MUL, DIV, MEM, FPU, BRU
    parameter ISSUE_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Dispatch interface (from rename)
    input  wire                     disp_valid,
    input  wire [PREG_BITS-1:0]     disp_prd,
    input  wire [PREG_BITS-1:0]     disp_prs1,
    input  wire [PREG_BITS-1:0]     disp_prs2,
    input  wire                     disp_prs1_rdy,
    input  wire                     disp_prs2_rdy,
    input  wire [3:0]               disp_fu_type,
    input  wire [5:0]               disp_alu_op,
    input  wire [XLEN-1:0]          disp_imm,
    input  wire [ROB_BITS-1:0]      disp_rob_tag,
    input  wire [38:0]              disp_pc,
    output wire                     disp_ready,

    // CDB wakeup (broadcast result tags)
    input  wire [FU_COUNT-1:0]      cdb_valid,
    input  wire [FU_COUNT*PREG_BITS-1:0] cdb_preg,

    // Issue outputs (up to ISSUE_WIDTH per cycle)
    output reg  [ISSUE_WIDTH-1:0]   iss_valid,
    output reg  [ISSUE_WIDTH*PREG_BITS-1:0] iss_prd,
    output reg  [ISSUE_WIDTH*PREG_BITS-1:0] iss_prs1,
    output reg  [ISSUE_WIDTH*PREG_BITS-1:0] iss_prs2,
    output reg  [ISSUE_WIDTH*4-1:0] iss_fu_type,
    output reg  [ISSUE_WIDTH*6-1:0] iss_alu_op,
    output reg  [ISSUE_WIDTH*XLEN-1:0] iss_imm,
    output reg  [ISSUE_WIDTH*ROB_BITS-1:0] iss_rob_tag,

    // Flush
    input  wire                     flush
);

    // Issue queue entry
    reg                     iq_valid  [0:IQ_ENTRIES-1];
    reg [PREG_BITS-1:0]     iq_prd    [0:IQ_ENTRIES-1];
    reg [PREG_BITS-1:0]     iq_prs1   [0:IQ_ENTRIES-1];
    reg [PREG_BITS-1:0]     iq_prs2   [0:IQ_ENTRIES-1];
    reg                     iq_rs1_rdy[0:IQ_ENTRIES-1];
    reg                     iq_rs2_rdy[0:IQ_ENTRIES-1];
    reg [3:0]               iq_fu_type[0:IQ_ENTRIES-1];
    reg [5:0]               iq_alu_op [0:IQ_ENTRIES-1];
    reg [XLEN-1:0]          iq_imm    [0:IQ_ENTRIES-1];
    reg [ROB_BITS-1:0]      iq_rob_tag[0:IQ_ENTRIES-1];
    reg [IQ_ENTRIES-1:0]    iq_age;   // age bit (older = 1)

    integer i, j, f;
    reg [IQ_ENTRIES-1:0]    ready_mask;
    reg [$clog2(IQ_ENTRIES)-1:0] sel_entry[0:ISSUE_WIDTH-1];
    reg [ISSUE_WIDTH-1:0]   sel_valid;

    // Wakeup logic: broadcast CDB tags to wake ready entries
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            for (i = 0; i < IQ_ENTRIES; i = i + 1)
                iq_valid[i] <= 1'b0;
            iss_valid <= {ISSUE_WIDTH{1'b0}};
        end else begin
            // Wakeup: mark RS ready if CDB broadcasts its tag
            for (i = 0; i < IQ_ENTRIES; i = i + 1) begin
                if (iq_valid[i]) begin
                    for (f = 0; f < FU_COUNT; f = f + 1) begin
                        if (cdb_valid[f]) begin
                            if (!iq_rs1_rdy[i] && (iq_prs1[i] == cdb_preg[f*PREG_BITS +: PREG_BITS]))
                                iq_rs1_rdy[i] <= 1'b1;
                            if (!iq_rs2_rdy[i] && (iq_prs2[i] == cdb_preg[f*PREG_BITS +: PREG_BITS]))
                                iq_rs2_rdy[i] <= 1'b1;
                        end
                    end
                end
            end

            // Dispatch: write into first empty slot
            if (disp_valid && disp_ready) begin
                for (i = 0; i < IQ_ENTRIES; i = i + 1) begin
                    if (!iq_valid[i]) begin
                        iq_valid  [i] <= 1'b1;
                        iq_prd    [i] <= disp_prd;
                        iq_prs1   [i] <= disp_prs1;
                        iq_prs2   [i] <= disp_prs2;
                        iq_rs1_rdy[i] <= disp_prs1_rdy;
                        iq_rs2_rdy[i] <= disp_prs2_rdy;
                        iq_fu_type[i] <= disp_fu_type;
                        iq_alu_op [i] <= disp_alu_op;
                        iq_imm    [i] <= disp_imm;
                        iq_rob_tag[i] <= disp_rob_tag;
                        // Only need to do this for first empty slot
                        i = IQ_ENTRIES; // break simulation loop
                    end
                end
            end

            // Select: pick oldest ready entries up to ISSUE_WIDTH
            iss_valid <= {ISSUE_WIDTH{1'b0}};
            begin : select_block
                integer issued = 0;
                for (i = 0; i < IQ_ENTRIES && issued < ISSUE_WIDTH; i = i + 1) begin
                    ready_mask[i] = iq_valid[i] && iq_rs1_rdy[i] && iq_rs2_rdy[i];
                    if (ready_mask[i]) begin
                        iss_valid[issued]                        <= 1'b1;
                        iss_prd  [issued*PREG_BITS +: PREG_BITS] <= iq_prd[i];
                        iss_prs1 [issued*PREG_BITS +: PREG_BITS] <= iq_prs1[i];
                        iss_prs2 [issued*PREG_BITS +: PREG_BITS] <= iq_prs2[i];
                        iss_fu_type[issued*4 +: 4]               <= iq_fu_type[i];
                        iss_alu_op [issued*6 +: 6]               <= iq_alu_op[i];
                        iss_imm    [issued*XLEN +: XLEN]         <= iq_imm[i];
                        iss_rob_tag[issued*ROB_BITS +: ROB_BITS] <= iq_rob_tag[i];
                        iq_valid[i] <= 1'b0;
                        issued = issued + 1;
                    end
                end
            end
        end
    end

    // Ready: not full
    wire [IQ_ENTRIES-1:0] iq_valid_vec;
    genvar g;
    generate
        for (g = 0; g < IQ_ENTRIES; g = g + 1)
            assign iq_valid_vec[g] = iq_valid[g];
    endgenerate
    assign disp_ready = (^iq_valid_vec !== 1'bx) && (~&iq_valid_vec); // not all full

endmodule
