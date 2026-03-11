// ============================================================
// l1i_cache.v - L1 Instruction Cache (32KB, 4-way set-associative)
// 64B lines, VIPT, pseudo-LRU replacement, pipeline interface
// ============================================================
`timescale 1ns/1ps

module l1i_cache #(
    parameter PADDR_WIDTH  = 56,
    parameter CACHE_SIZE   = 32768,  // 32 KB
    parameter WAYS         = 4,
    parameter LINE_BYTES   = 64,     // 64 bytes / line
    parameter LINE_BITS    = 512,    // 64*8
    parameter SETS         = CACHE_SIZE / (WAYS * LINE_BYTES)  // 128 sets
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // CPU interface
    input  wire                     req_valid,
    input  wire [PADDR_WIDTH-1:0]   req_paddr,
    output reg                      resp_valid,
    output reg  [LINE_BITS-1:0]     resp_data,
    output reg                      resp_miss,

    // L2 refill interface
    output reg                      refill_req_valid,
    output reg  [PADDR_WIDTH-1:0]   refill_req_addr,
    input  wire                     refill_resp_valid,
    input  wire [LINE_BITS-1:0]     refill_resp_data,

    // Invalidation (from coherence)
    input  wire                     inv_valid,
    input  wire [PADDR_WIDTH-1:0]   inv_addr,

    // Branch flush
    input  wire                     flush
);

    localparam INDEX_BITS = $clog2(SETS);     // 7
    localparam OFFSET_BITS= $clog2(LINE_BYTES); // 6
    localparam TAG_BITS   = PADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    // Tag array
    reg [TAG_BITS-1:0]  tags  [0:SETS-1][0:WAYS-1];
    reg                 valid [0:SETS-1][0:WAYS-1];
    // Data array (SRAM model)
    reg [LINE_BITS-1:0] data  [0:SETS-1][0:WAYS-1];
    // PLRU bits (WAYS-1 bits per set for tree-PLRU)
    reg [WAYS-2:0]      plru  [0:SETS-1];

    wire [INDEX_BITS-1:0]  idx    = req_paddr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]    tag    = req_paddr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    // Hit detection
    reg [WAYS-1:0]      hit_vec;
    reg [$clog2(WAYS)-1:0] hit_way;
    reg                 hit;
    integer i;

    always @(*) begin
        hit     = 1'b0;
        hit_way = {$clog2(WAYS){1'b0}};
        hit_vec = {WAYS{1'b0}};
        for (i = 0; i < WAYS; i = i + 1) begin
            if (valid[idx][i] && tags[idx][i] == tag) begin
                hit     = 1'b1;
                hit_way = i[$clog2(WAYS)-1:0];
                hit_vec[i] = 1'b1;
            end
        end
    end

    // PLRU: find victim way
    function [$clog2(WAYS)-1:0] plru_victim;
        input [WAYS-2:0] p;
        begin
            // 4-way tree PLRU: bit[0]=root, bit[1]=left child, bit[2]=right child
            if (!p[0])
                plru_victim = (!p[1]) ? 2'd0 : 2'd1;
            else
                plru_victim = (!p[2]) ? 2'd2 : 2'd3;
        end
    endfunction

    // Update PLRU on hit
    function [WAYS-2:0] plru_update;
        input [WAYS-2:0] p;
        input [$clog2(WAYS)-1:0] w;
        begin
            case (w)
                2'd0: plru_update = {p[2], 1'b1, 1'b1};
                2'd1: plru_update = {p[2], 1'b0, 1'b1};
                2'd2: plru_update = {1'b1, p[1], 1'b0};
                2'd3: plru_update = {1'b0, p[1], 1'b0};
                default: plru_update = p;
            endcase
        end
    endfunction

    // State machine
    localparam ST_IDLE     = 2'd0;
    localparam ST_REFILL   = 2'd1;
    localparam ST_RESPOND  = 2'd2;

    reg [1:0] state;
    reg [PADDR_WIDTH-1:0]  miss_addr;
    reg [INDEX_BITS-1:0]   miss_idx;
    reg [TAG_BITS-1:0]     miss_tag;
    reg [$clog2(WAYS)-1:0] victim_way;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            resp_valid <= 0;
            refill_req_valid <= 0;
            for (i = 0; i < SETS; i = i + 1) begin : init_loop
                valid[i][0] <= 0; valid[i][1] <= 0;
                valid[i][2] <= 0; valid[i][3] <= 0;
                plru[i] <= {(WAYS-1){1'b0}};
            end
        end else begin
            resp_valid <= 0;
            refill_req_valid <= 0;

            case (state)
                ST_IDLE: begin
                    if (req_valid) begin
                        if (hit) begin
                            resp_valid <= 1;
                            resp_data  <= data[idx][hit_way];
                            resp_miss  <= 0;
                            plru[idx]  <= plru_update(plru[idx], hit_way);
                        end else begin
                            resp_valid <= 1;
                            resp_miss  <= 1;
                            resp_data  <= {LINE_BITS{1'b0}};
                            miss_addr  <= req_paddr;
                            miss_idx   <= idx;
                            miss_tag   <= tag;
                            victim_way <= plru_victim(plru[idx]);
                            refill_req_valid <= 1;
                            refill_req_addr  <= {req_paddr[PADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                            state      <= ST_REFILL;
                        end
                    end
                end
                ST_REFILL: begin
                    refill_req_valid <= 1;
                    if (refill_resp_valid) begin
                        refill_req_valid       <= 0;
                        data [miss_idx][victim_way] <= refill_resp_data;
                        tags [miss_idx][victim_way] <= miss_tag;
                        valid[miss_idx][victim_way] <= 1;
                        plru [miss_idx]             <= plru_update(plru[miss_idx], victim_way);
                        state <= ST_IDLE;
                    end
                end
            endcase

            // Invalidation
            if (inv_valid) begin
                for (i = 0; i < WAYS; i = i + 1) begin
                    if (valid[inv_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]][i] &&
                        tags [inv_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]][i] ==
                             inv_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS])
                        valid[inv_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]][i] <= 0;
                end
            end
        end
    end

endmodule
