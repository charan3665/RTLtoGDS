// ============================================================
// fetch_unit.v - Instruction Fetch Unit for OoO RISC-V Core
// Supports 64-bit RISC-V, branch prediction, I-cache interface
// ============================================================
`timescale 1ns/1ps

module fetch_unit #(
    parameter XLEN        = 64,
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56,
    parameter ICACHE_LINE = 512,  // bits per cache line
    parameter FETCH_WIDTH = 4,    // instructions per cycle
    parameter BTB_ENTRIES = 1024,
    parameter RAS_DEPTH   = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Branch resolution feedback
    input  wire                     bru_valid,
    input  wire [VADDR_WIDTH-1:0]   bru_pc,
    input  wire [VADDR_WIDTH-1:0]   bru_target,
    input  wire                     bru_taken,
    input  wire                     bru_mispred,

    // Redirect from decode/rename
    input  wire                     redirect_valid,
    input  wire [VADDR_WIDTH-1:0]   redirect_pc,

    // I-TLB interface
    output wire                     itlb_req_valid,
    output wire [VADDR_WIDTH-1:0]   itlb_req_vaddr,
    input  wire                     itlb_resp_valid,
    input  wire                     itlb_resp_fault,
    input  wire [PADDR_WIDTH-1:0]   itlb_resp_paddr,

    // I-cache interface
    output wire                     icache_req_valid,
    output wire [PADDR_WIDTH-1:0]   icache_req_paddr,
    input  wire                     icache_resp_valid,
    input  wire [ICACHE_LINE-1:0]   icache_resp_data,
    input  wire                     icache_resp_miss,

    // Output to decode queue
    output wire                     fetchq_valid,
    output wire [FETCH_WIDTH*32-1:0] fetchq_instr,
    output wire [FETCH_WIDTH*VADDR_WIDTH-1:0] fetchq_pc,
    output wire [FETCH_WIDTH-1:0]   fetchq_pred_taken,
    output wire [FETCH_WIDTH*VADDR_WIDTH-1:0] fetchq_pred_target,
    input  wire                     fetchq_ready,

    // Privilege mode
    input  wire [1:0]               priv_mode,
    input  wire [XLEN-1:0]          satp
);

    // PC register
    reg  [VADDR_WIDTH-1:0]  pc_reg;
    reg  [VADDR_WIDTH-1:0]  npc;

    // Branch Target Buffer
    reg  [VADDR_WIDTH-1:0]  btb_target [0:BTB_ENTRIES-1];
    reg  [BTB_ENTRIES-1:0]  btb_valid;
    reg  [1:0]              btb_counter[0:BTB_ENTRIES-1]; // 2-bit saturating counter

    // Return Address Stack
    reg  [VADDR_WIDTH-1:0]  ras_stack [0:RAS_DEPTH-1];
    reg  [$clog2(RAS_DEPTH)-1:0] ras_ptr;

    // State machine
    localparam ST_IDLE      = 3'd0;
    localparam ST_TLB_WAIT  = 3'd1;
    localparam ST_CACHE_REQ = 3'd2;
    localparam ST_CACHE_WAIT= 3'd3;
    localparam ST_DELIVER   = 3'd4;
    localparam ST_STALL     = 3'd5;

    reg [2:0] state;

    // Fetch buffer
    reg [ICACHE_LINE-1:0]      fetch_buf;
    reg [VADDR_WIDTH-1:0]      fetch_buf_pc;
    reg                        fetch_buf_valid;

    // BTB lookup
    wire [$clog2(BTB_ENTRIES)-1:0] btb_idx = pc_reg[$clog2(BTB_ENTRIES)+1:2];
    wire btb_hit = btb_valid[btb_idx];
    wire [1:0] btb_cnt = btb_counter[btb_idx];
    wire btb_pred_taken = btb_hit && (btb_cnt[1] == 1'b1);

    // PC mux
    always @(*) begin
        if (redirect_valid)
            npc = redirect_pc;
        else if (bru_mispred)
            npc = bru_target;
        else if (btb_pred_taken)
            npc = btb_target[btb_idx];
        else
            npc = pc_reg + (FETCH_WIDTH * 4);
    end

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg        <= {VADDR_WIDTH{1'b0}};
            state         <= ST_TLB_WAIT;
            fetch_buf_valid <= 1'b0;
            ras_ptr       <= {$clog2(RAS_DEPTH){1'b0}};
            btb_valid     <= {BTB_ENTRIES{1'b0}};
        end else begin
            case (state)
                ST_IDLE: begin
                    pc_reg <= npc;
                    state  <= ST_TLB_WAIT;
                end
                ST_TLB_WAIT: begin
                    if (itlb_resp_valid) begin
                        if (itlb_resp_fault)
                            state <= ST_IDLE; // handle fault
                        else
                            state <= ST_CACHE_WAIT;
                    end
                end
                ST_CACHE_WAIT: begin
                    if (icache_resp_valid) begin
                        if (!icache_resp_miss) begin
                            fetch_buf       <= icache_resp_data;
                            fetch_buf_pc    <= pc_reg;
                            fetch_buf_valid <= 1'b1;
                            state           <= ST_DELIVER;
                        end else begin
                            state <= ST_CACHE_WAIT; // wait for refill
                        end
                    end
                end
                ST_DELIVER: begin
                    if (fetchq_ready) begin
                        fetch_buf_valid <= 1'b0;
                        pc_reg <= npc;
                        state  <= ST_TLB_WAIT;
                    end
                end
                default: state <= ST_IDLE;
            endcase

            // BTB update on branch resolution
            if (bru_valid) begin
                btb_valid[btb_idx]                       <= 1'b1;
                btb_target[bru_pc[$clog2(BTB_ENTRIES)+1:2]] <= bru_target;
                if (bru_taken)
                    btb_counter[bru_pc[$clog2(BTB_ENTRIES)+1:2]] <=
                        (btb_counter[bru_pc[$clog2(BTB_ENTRIES)+1:2]] == 2'b11) ? 2'b11 :
                         btb_counter[bru_pc[$clog2(BTB_ENTRIES)+1:2]] + 1;
                else
                    btb_counter[bru_pc[$clog2(BTB_ENTRIES)+1:2]] <=
                        (btb_counter[bru_pc[$clog2(BTB_ENTRIES)+1:2]] == 2'b00) ? 2'b00 :
                         btb_counter[bru_pc[$clog2(BTB_ENTRIES)+1:2]] - 1;
            end
        end
    end

    // Output assignments
    assign itlb_req_valid   = (state == ST_TLB_WAIT);
    assign itlb_req_vaddr   = pc_reg;
    assign icache_req_valid = itlb_resp_valid && !itlb_resp_fault;
    assign icache_req_paddr = itlb_resp_paddr;

    assign fetchq_valid     = fetch_buf_valid && (state == ST_DELIVER);

    genvar i;
    generate
        for (i = 0; i < FETCH_WIDTH; i = i + 1) begin : gen_fetchq
            assign fetchq_instr[i*32 +: 32]              = fetch_buf[i*32 +: 32];
            assign fetchq_pc[i*VADDR_WIDTH +: VADDR_WIDTH] = fetch_buf_pc + (i * 4);
            assign fetchq_pred_taken[i]                   = btb_pred_taken;
            assign fetchq_pred_target[i*VADDR_WIDTH +: VADDR_WIDTH] = btb_target[btb_idx];
        end
    endgenerate

endmodule
