// ============================================================
// rob.v - Reorder Buffer for in-order retirement
// Circular buffer with head/tail, supports exception/mispredict
// ============================================================
`timescale 1ns/1ps

module rob #(
    parameter ROB_ENTRIES = 128,
    parameter ROB_BITS    = 7,
    parameter XLEN        = 64,
    parameter PREG_BITS   = 7,
    parameter ARCH_REGS   = 32,
    parameter RETIRE_WIDTH= 4
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Dispatch interface (write new entries)
    input  wire [RETIRE_WIDTH-1:0]  disp_valid,
    input  wire [RETIRE_WIDTH*5-1:0]  disp_ard,
    input  wire [RETIRE_WIDTH*PREG_BITS-1:0] disp_prd,
    input  wire [RETIRE_WIDTH*PREG_BITS-1:0] disp_old_prd,
    input  wire [RETIRE_WIDTH*XLEN-1:0] disp_pc,
    output wire                     rob_full,
    output wire [RETIRE_WIDTH*ROB_BITS-1:0] rob_tags,

    // Completion interface (mark entries done)
    input  wire [3:0]               comp_valid,
    input  wire [3:0][ROB_BITS-1:0] comp_rob_tag,
    input  wire [3:0][XLEN-1:0]     comp_result,
    input  wire [3:0]               comp_exception,
    input  wire [3:0][3:0]          comp_exc_code,

    // Retirement interface
    output reg  [RETIRE_WIDTH-1:0]  ret_valid,
    output reg  [RETIRE_WIDTH*5-1:0]  ret_ard,
    output reg  [RETIRE_WIDTH*PREG_BITS-1:0] ret_prd,
    output reg  [RETIRE_WIDTH*PREG_BITS-1:0] ret_old_prd,
    output reg  [RETIRE_WIDTH*XLEN-1:0] ret_pc,

    // Exception output
    output reg                      exc_valid,
    output reg  [XLEN-1:0]          exc_pc,
    output reg  [3:0]               exc_code,

    // Flush output
    output reg                      flush_valid,
    output reg  [ARCH_REGS*PREG_BITS-1:0] flush_rat_snapshot
);

    // ROB entry fields
    reg                     rob_done    [0:ROB_ENTRIES-1];
    reg [4:0]               rob_ard     [0:ROB_ENTRIES-1];
    reg [PREG_BITS-1:0]     rob_prd     [0:ROB_ENTRIES-1];
    reg [PREG_BITS-1:0]     rob_old_prd [0:ROB_ENTRIES-1];
    reg [XLEN-1:0]          rob_pc      [0:ROB_ENTRIES-1];
    reg [XLEN-1:0]          rob_result  [0:ROB_ENTRIES-1];
    reg                     rob_exc     [0:ROB_ENTRIES-1];
    reg [3:0]               rob_exc_code[0:ROB_ENTRIES-1];

    reg [ROB_BITS-1:0]      head, tail;
    reg [$clog2(ROB_ENTRIES):0] count;

    // Architectural RAT snapshot (for mispredict recovery)
    reg [PREG_BITS-1:0]     arch_rat [0:ARCH_REGS-1];

    integer i, k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head  <= {ROB_BITS{1'b0}};
            tail  <= {ROB_BITS{1'b0}};
            count <= 0;
            ret_valid   <= {RETIRE_WIDTH{1'b0}};
            exc_valid   <= 1'b0;
            flush_valid <= 1'b0;
            for (i = 0; i < ROB_ENTRIES; i = i + 1) rob_done[i] <= 1'b0;
        end else begin
            flush_valid <= 1'b0;
            exc_valid   <= 1'b0;
            ret_valid   <= {RETIRE_WIDTH{1'b0}};

            // Dispatch: write new entries at tail
            for (k = 0; k < RETIRE_WIDTH; k = k + 1) begin
                if (disp_valid[k]) begin
                    rob_done    [tail + k] <= 1'b0;
                    rob_ard     [tail + k] <= disp_ard[k*5 +: 5];
                    rob_prd     [tail + k] <= disp_prd[k*PREG_BITS +: PREG_BITS];
                    rob_old_prd [tail + k] <= disp_old_prd[k*PREG_BITS +: PREG_BITS];
                    rob_pc      [tail + k] <= disp_pc[k*XLEN +: XLEN];
                    rob_exc     [tail + k] <= 1'b0;
                end
            end
            if (|disp_valid) begin
                tail  <= tail  + RETIRE_WIDTH;
                count <= count + RETIRE_WIDTH;
            end

            // Completion: mark done
            for (k = 0; k < 4; k = k + 1) begin
                if (comp_valid[k]) begin
                    rob_done    [comp_rob_tag[k]] <= 1'b1;
                    rob_result  [comp_rob_tag[k]] <= comp_result[k];
                    rob_exc     [comp_rob_tag[k]] <= comp_exception[k];
                    rob_exc_code[comp_rob_tag[k]] <= comp_exc_code[k];
                end
            end

            // Retirement: commit head entries in-order
            begin : retire_block
                integer retired = 0;
                for (k = 0; k < RETIRE_WIDTH; k = k + 1) begin
                    if (rob_done[head + k] && retired == k) begin
                        if (rob_exc[head + k]) begin
                            // Exception: flush ROB
                            exc_valid   <= 1'b1;
                            exc_pc      <= rob_pc[head + k];
                            exc_code    <= rob_exc_code[head + k];
                            flush_valid <= 1'b1;
                            // Snapshot architectural RAT
                            for (i = 0; i < ARCH_REGS; i = i + 1)
                                flush_rat_snapshot[i*PREG_BITS +: PREG_BITS] <= arch_rat[i];
                            head  <= {ROB_BITS{1'b0}};
                            tail  <= {ROB_BITS{1'b0}};
                            count <= 0;
                            k = RETIRE_WIDTH; // break
                        end else begin
                            ret_valid  [k] <= 1'b1;
                            ret_ard    [k*5 +: 5] <= rob_ard[head + k];
                            ret_prd    [k*PREG_BITS +: PREG_BITS] <= rob_prd[head + k];
                            ret_old_prd[k*PREG_BITS +: PREG_BITS] <= rob_old_prd[head + k];
                            ret_pc     [k*XLEN +: XLEN] <= rob_pc[head + k];
                            // Update arch RAT
                            if (rob_ard[head + k] != 5'd0)
                                arch_rat[rob_ard[head + k]] <= rob_prd[head + k];
                            retired = retired + 1;
                        end
                    end
                end
                if (retired > 0) begin
                    head  <= head  + retired;
                    count <= count - retired;
                end
            end
        end
    end

    assign rob_full = (count >= ROB_ENTRIES - RETIRE_WIDTH);
    genvar gk;
    generate
        for (gk = 0; gk < RETIRE_WIDTH; gk = gk + 1)
            assign rob_tags[gk*ROB_BITS +: ROB_BITS] = tail + gk;
    endgenerate

endmodule
