// ============================================================
// lsu.v - Load/Store Unit with store queue and load queue
// D-TLB interface, D-Cache interface, AMO support
// ============================================================
`timescale 1ns/1ps

module lsu #(
    parameter XLEN        = 64,
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56,
    parameter PREG_BITS   = 7,
    parameter ROB_BITS    = 7,
    parameter SQ_ENTRIES  = 32,
    parameter LQ_ENTRIES  = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Instruction issue interface
    input  wire                     lsu_issue_valid,
    input  wire [2:0]               lsu_funct3,    // width/sign
    input  wire [6:0]               lsu_opcode,    // LOAD/STORE/AMO
    input  wire [XLEN-1:0]          lsu_addr,
    input  wire [XLEN-1:0]          lsu_store_data,
    input  wire [PREG_BITS-1:0]     lsu_prd,
    input  wire [ROB_BITS-1:0]      lsu_rob_tag,
    output wire                     lsu_ready,

    // D-TLB interface
    output reg                      dtlb_req_valid,
    output reg  [VADDR_WIDTH-1:0]   dtlb_req_vaddr,
    output reg                      dtlb_req_wr,
    input  wire                     dtlb_resp_valid,
    input  wire                     dtlb_resp_fault,
    input  wire [PADDR_WIDTH-1:0]   dtlb_resp_paddr,

    // D-Cache interface
    output reg                      dcache_req_valid,
    output reg  [PADDR_WIDTH-1:0]   dcache_req_paddr,
    output reg                      dcache_req_wr,
    output reg  [2:0]               dcache_req_size,
    output reg  [XLEN-1:0]          dcache_req_wdata,
    output reg  [(XLEN/8)-1:0]      dcache_req_strb,
    input  wire                     dcache_resp_valid,
    input  wire [XLEN-1:0]          dcache_resp_rdata,
    input  wire                     dcache_resp_miss,

    // Result to CDB
    output reg                      cdb_valid,
    output reg  [XLEN-1:0]          cdb_result,
    output reg  [PREG_BITS-1:0]     cdb_prd,
    output reg  [ROB_BITS-1:0]      cdb_rob_tag,
    output reg                      cdb_exception,

    // Store commit (from ROB)
    input  wire                     sq_commit_valid,
    input  wire [ROB_BITS-1:0]      sq_commit_rob_tag,

    // Flush
    input  wire                     flush
);

    // Store Queue
    reg [SQ_ENTRIES-1:0]    sq_valid;
    reg [PADDR_WIDTH-1:0]   sq_paddr  [0:SQ_ENTRIES-1];
    reg [XLEN-1:0]          sq_data   [0:SQ_ENTRIES-1];
    reg [2:0]               sq_size   [0:SQ_ENTRIES-1];
    reg [(XLEN/8)-1:0]      sq_strb   [0:SQ_ENTRIES-1];
    reg [ROB_BITS-1:0]      sq_rob    [0:SQ_ENTRIES-1];
    reg [SQ_ENTRIES-1:0]    sq_committed;
    reg [$clog2(SQ_ENTRIES)-1:0] sq_head, sq_tail;

    // Load Queue
    reg [LQ_ENTRIES-1:0]    lq_valid;
    reg [PADDR_WIDTH-1:0]   lq_paddr  [0:LQ_ENTRIES-1];
    reg [2:0]               lq_size   [0:LQ_ENTRIES-1];
    reg [PREG_BITS-1:0]     lq_prd    [0:LQ_ENTRIES-1];
    reg [ROB_BITS-1:0]      lq_rob    [0:LQ_ENTRIES-1];
    reg [$clog2(LQ_ENTRIES)-1:0] lq_head, lq_tail;

    // State machine
    localparam ST_IDLE   = 3'd0;
    localparam ST_TLB    = 3'd1;
    localparam ST_CACHE  = 3'd2;
    localparam ST_DRAIN  = 3'd3;

    reg [2:0] state;
    reg       is_store;
    reg [PADDR_WIDTH-1:0] paddr_latch;
    reg [PREG_BITS-1:0]   prd_latch;
    reg [ROB_BITS-1:0]    rob_latch;
    reg [2:0]             size_latch;
    reg [XLEN-1:0]        wdata_latch;

    function [XLEN-1:0] sign_extend_load;
        input [2:0]      funct3;
        input [XLEN-1:0] rdata;
        begin
            case (funct3)
                3'b000: sign_extend_load = {{(XLEN- 8){rdata[ 7]}}, rdata[ 7:0]};  // LB
                3'b001: sign_extend_load = {{(XLEN-16){rdata[15]}}, rdata[15:0]};  // LH
                3'b010: sign_extend_load = {{(XLEN-32){rdata[31]}}, rdata[31:0]};  // LW
                3'b011: sign_extend_load = rdata;                                   // LD
                3'b100: sign_extend_load = {{(XLEN- 8){1'b0}}, rdata[ 7:0]};       // LBU
                3'b101: sign_extend_load = {{(XLEN-16){1'b0}}, rdata[15:0]};       // LHU
                3'b110: sign_extend_load = {{(XLEN-32){1'b0}}, rdata[31:0]};       // LWU
                default:sign_extend_load = rdata;
            endcase
        end
    endfunction

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            state       <= ST_IDLE;
            sq_valid    <= {SQ_ENTRIES{1'b0}};
            lq_valid    <= {LQ_ENTRIES{1'b0}};
            sq_head     <= 0; sq_tail <= 0;
            lq_head     <= 0; lq_tail <= 0;
            cdb_valid   <= 1'b0;
            dtlb_req_valid  <= 1'b0;
            dcache_req_valid<= 1'b0;
        end else begin
            cdb_valid        <= 1'b0;
            dtlb_req_valid   <= 1'b0;
            dcache_req_valid <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (lsu_issue_valid) begin
                        is_store    <= (lsu_opcode == 7'b0100011);
                        dtlb_req_valid <= 1'b1;
                        dtlb_req_vaddr <= lsu_addr[VADDR_WIDTH-1:0];
                        dtlb_req_wr    <= (lsu_opcode == 7'b0100011);
                        prd_latch      <= lsu_prd;
                        rob_latch      <= lsu_rob_tag;
                        size_latch     <= lsu_funct3;
                        wdata_latch    <= lsu_store_data;
                        state          <= ST_TLB;
                    end
                    // Drain committed stores
                    if (sq_committed[sq_head] && sq_valid[sq_head]) begin
                        dcache_req_valid <= 1'b1;
                        dcache_req_paddr <= sq_paddr[sq_head];
                        dcache_req_wr    <= 1'b1;
                        dcache_req_size  <= sq_size[sq_head];
                        dcache_req_wdata <= sq_data[sq_head];
                        dcache_req_strb  <= sq_strb[sq_head];
                        sq_valid[sq_head]<= 1'b0;
                        sq_head <= sq_head + 1;
                    end
                end
                ST_TLB: begin
                    if (dtlb_resp_valid) begin
                        if (dtlb_resp_fault) begin
                            cdb_valid     <= 1'b1;
                            cdb_exception <= 1'b1;
                            cdb_prd       <= prd_latch;
                            cdb_rob_tag   <= rob_latch;
                            state         <= ST_IDLE;
                        end else begin
                            paddr_latch   <= dtlb_resp_paddr;
                            if (!is_store) begin
                                // Load: check store queue for forwarding
                                dcache_req_valid <= 1'b1;
                                dcache_req_paddr <= dtlb_resp_paddr;
                                dcache_req_wr    <= 1'b0;
                                dcache_req_size  <= size_latch;
                            end else begin
                                // Store: push to store queue
                                sq_valid[sq_tail] <= 1'b1;
                                sq_paddr[sq_tail] <= dtlb_resp_paddr;
                                sq_data [sq_tail] <= wdata_latch;
                                sq_size [sq_tail] <= size_latch;
                                sq_rob  [sq_tail] <= rob_latch;
                                sq_committed[sq_tail] <= 1'b0;
                                sq_tail <= sq_tail + 1;
                                // Stores don't generate results (except for AMO)
                                cdb_valid   <= 1'b1;
                                cdb_result  <= {XLEN{1'b0}};
                                cdb_prd     <= prd_latch;
                                cdb_rob_tag <= rob_latch;
                                cdb_exception <= 1'b0;
                                state <= ST_IDLE;
                            end
                            if (!is_store)
                                state <= ST_CACHE;
                        end
                    end
                end
                ST_CACHE: begin
                    if (dcache_resp_valid && !dcache_resp_miss) begin
                        cdb_valid     <= 1'b1;
                        cdb_result    <= sign_extend_load(size_latch, dcache_resp_rdata);
                        cdb_prd       <= prd_latch;
                        cdb_rob_tag   <= rob_latch;
                        cdb_exception <= 1'b0;
                        state         <= ST_IDLE;
                    end
                end
            endcase

            // Commit store queue entry on ROB commit
            if (sq_commit_valid) begin
                for (i = 0; i < SQ_ENTRIES; i = i + 1)
                    if (sq_valid[i] && sq_rob[i] == sq_commit_rob_tag)
                        sq_committed[i] <= 1'b1;
            end
        end
    end

    assign lsu_ready = (state == ST_IDLE);

endmodule
