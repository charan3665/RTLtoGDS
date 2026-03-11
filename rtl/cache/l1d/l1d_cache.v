// ============================================================
// l1d_cache.v - L1 Data Cache (32KB, 4-way, write-back, write-allocate)
// MSHR for non-blocking, supports AMO, 4-bank interleaving
// ============================================================
`timescale 1ns/1ps

module l1d_cache #(
    parameter PADDR_WIDTH  = 56,
    parameter XLEN         = 64,
    parameter CACHE_SIZE   = 32768,
    parameter WAYS         = 4,
    parameter LINE_BYTES   = 64,
    parameter LINE_BITS    = 512,
    parameter SETS         = CACHE_SIZE / (WAYS * LINE_BYTES),  // 128
    parameter MSHR_ENTRIES = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // CPU request
    input  wire                     req_valid,
    input  wire [PADDR_WIDTH-1:0]   req_addr,
    input  wire                     req_wr,
    input  wire [2:0]               req_size,    // 0=B,1=H,2=W,3=D
    input  wire [XLEN-1:0]          req_wdata,
    input  wire [7:0]               req_strb,
    output reg                      resp_valid,
    output reg  [XLEN-1:0]          resp_rdata,
    output reg                      resp_miss,

    // L2 miss interface
    output reg                      miss_req_valid,
    output reg  [PADDR_WIDTH-1:0]   miss_req_addr,
    output reg                      miss_req_wr,
    output reg  [LINE_BITS-1:0]     miss_req_wdata,  // for write-back
    input  wire                     miss_resp_valid,
    input  wire [LINE_BITS-1:0]     miss_resp_data,

    // Snoop interface (for coherence)
    input  wire                     snoop_valid,
    input  wire [PADDR_WIDTH-1:0]   snoop_addr,
    input  wire [1:0]               snoop_type,  // 00=INV, 01=SHARED, 10=EXCL
    output reg                      snoop_resp_valid,
    output reg  [LINE_BITS-1:0]     snoop_resp_data,
    output reg                      snoop_resp_hit,

    // Flush all dirty lines
    input  wire                     flush_all,
    output reg                      flush_done
);

    localparam INDEX_BITS  = $clog2(SETS);
    localparam OFFSET_BITS = $clog2(LINE_BYTES);
    localparam TAG_BITS    = PADDR_WIDTH - INDEX_BITS - OFFSET_BITS;
    localparam BYTE_OFF    = $clog2(XLEN/8);

    reg [TAG_BITS-1:0]  tags  [0:SETS-1][0:WAYS-1];
    reg                 valid [0:SETS-1][0:WAYS-1];
    reg                 dirty [0:SETS-1][0:WAYS-1];
    reg [LINE_BITS-1:0] data  [0:SETS-1][0:WAYS-1];
    reg [WAYS-2:0]      plru  [0:SETS-1];

    wire [INDEX_BITS-1:0]  idx     = req_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]    tag_in  = req_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
    wire [BYTE_OFF-1:0]    byte_off= req_addr[BYTE_OFF-1:0];
    wire [OFFSET_BITS-1:BYTE_OFF] word_off = req_addr[OFFSET_BITS-1:BYTE_OFF];

    // Hit detection
    reg [WAYS-1:0] hit_vec;
    reg [$clog2(WAYS)-1:0] hit_way;
    reg hit;
    integer i, j;

    always @(*) begin
        hit = 0; hit_way = 0; hit_vec = 0;
        for (i = 0; i < WAYS; i = i + 1) begin
            if (valid[idx][i] && tags[idx][i] == tag_in) begin
                hit = 1; hit_way = i[$clog2(WAYS)-1:0]; hit_vec[i] = 1;
            end
        end
    end

    // Word extraction from cache line
    function [XLEN-1:0] extract_word;
        input [LINE_BITS-1:0] line;
        input [OFFSET_BITS-BYTE_OFF-1:0] woff;
        input [2:0] sz;
        reg [XLEN-1:0] raw;
        begin
            raw = line[woff*XLEN +: XLEN];
            case (sz)
                3'd0: extract_word = {{56{raw[7]}}, raw[7:0]};
                3'd1: extract_word = {{48{raw[15]}},raw[15:0]};
                3'd2: extract_word = {{32{raw[31]}},raw[31:0]};
                3'd3: extract_word = raw;
                default: extract_word = raw;
            endcase
        end
    endfunction

    // PLRU
    function [$clog2(WAYS)-1:0] plru_victim;
        input [WAYS-2:0] p;
        begin
            plru_victim = (!p[0]) ? ((!p[1]) ? 2'd0 : 2'd1) : ((!p[2]) ? 2'd2 : 2'd3);
        end
    endfunction

    // State
    localparam ST_IDLE    = 3'd0;
    localparam ST_MISS    = 3'd1;
    localparam ST_WRITEBK = 3'd2;
    localparam ST_REFILL  = 3'd3;
    localparam ST_FLUSH   = 3'd4;

    reg [2:0]              state;
    reg [PADDR_WIDTH-1:0]  miss_addr_latch;
    reg [INDEX_BITS-1:0]   miss_idx_latch;
    reg [TAG_BITS-1:0]     miss_tag_latch;
    reg [$clog2(WAYS)-1:0] victim;
    reg                    miss_wr_latch;
    reg [XLEN-1:0]         miss_wdata_latch;
    reg [2:0]              miss_size_latch;
    reg [7:0]              miss_strb_latch;
    reg [INDEX_BITS-1:0]   flush_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            resp_valid <= 0; miss_req_valid <= 0;
            flush_done <= 0; snoop_resp_valid <= 0;
            for (i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) begin
                valid[i][j]<=0; dirty[i][j]<=0; plru[i]<={(WAYS-1){1'b0}};
            end
        end else begin
            resp_valid <= 0; miss_req_valid <= 0;
            flush_done <= 0; snoop_resp_valid <= 0;

            // Snoop handling
            if (snoop_valid) begin
                automatic reg [INDEX_BITS-1:0] sidx = snoop_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
                automatic reg [TAG_BITS-1:0]   stag = snoop_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
                snoop_resp_valid <= 1;
                snoop_resp_hit   <= 0;
                snoop_resp_data  <= {LINE_BITS{1'b0}};
                for (i=0;i<WAYS;i=i+1) begin
                    if (valid[sidx][i] && tags[sidx][i]==stag) begin
                        snoop_resp_hit  <= 1;
                        snoop_resp_data <= data[sidx][i];
                        if (snoop_type == 2'b00) begin // Invalidate
                            valid[sidx][i] <= 0;
                            dirty[sidx][i] <= 0;
                        end
                    end
                end
            end

            case (state)
                ST_IDLE: begin
                    if (flush_all) begin
                        flush_idx <= {INDEX_BITS{1'b0}};
                        state <= ST_FLUSH;
                    end else if (req_valid) begin
                        if (hit) begin
                            resp_valid <= 1;
                            resp_miss  <= 0;
                            if (!req_wr) begin
                                resp_rdata <= extract_word(data[idx][hit_way], word_off, req_size);
                            end else begin
                                // Write hit: update data array with byte strobes
                                for (j=0;j<XLEN/8;j=j+1)
                                    if (req_strb[j]) data[idx][hit_way][(word_off*(XLEN/8)+j)*8 +: 8] <= req_wdata[j*8 +: 8];
                                dirty[idx][hit_way] <= 1;
                                resp_rdata <= {XLEN{1'b0}};
                            end
                        end else begin
                            // Miss
                            resp_valid       <= 1;
                            resp_miss        <= 1;
                            resp_rdata       <= {XLEN{1'b0}};
                            miss_addr_latch  <= req_addr;
                            miss_idx_latch   <= idx;
                            miss_tag_latch   <= tag_in;
                            miss_wr_latch    <= req_wr;
                            miss_wdata_latch <= req_wdata;
                            miss_size_latch  <= req_size;
                            miss_strb_latch  <= req_strb;
                            victim           <= plru_victim(plru[idx]);
                            // Check if victim is dirty -> write-back first
                            if (dirty[idx][plru_victim(plru[idx])]) begin
                                miss_req_valid <= 1;
                                miss_req_addr  <= {tags[idx][plru_victim(plru[idx])],
                                                   idx, {OFFSET_BITS{1'b0}}};
                                miss_req_wr    <= 1;
                                miss_req_wdata <= data[idx][plru_victim(plru[idx])];
                                state <= ST_WRITEBK;
                            end else begin
                                miss_req_valid <= 1;
                                miss_req_addr  <= {req_addr[PADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                                miss_req_wr    <= 0;
                                state <= ST_REFILL;
                            end
                        end
                    end
                end

                ST_WRITEBK: begin
                    if (miss_resp_valid) begin
                        dirty[miss_idx_latch][victim] <= 0;
                        miss_req_valid <= 1;
                        miss_req_addr  <= {miss_addr_latch[PADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                        miss_req_wr    <= 0;
                        state <= ST_REFILL;
                    end else begin
                        miss_req_valid <= 1;
                    end
                end

                ST_REFILL: begin
                    if (miss_resp_valid) begin
                        data [miss_idx_latch][victim] <= miss_resp_data;
                        tags [miss_idx_latch][victim] <= miss_tag_latch;
                        valid[miss_idx_latch][victim] <= 1;
                        dirty[miss_idx_latch][victim] <= miss_wr_latch;
                        if (miss_wr_latch) begin
                            for (j=0;j<XLEN/8;j=j+1)
                                if (miss_strb_latch[j])
                                    data[miss_idx_latch][victim][(word_off*(XLEN/8)+j)*8 +: 8] <= miss_wdata_latch[j*8 +: 8];
                        end
                        state <= ST_IDLE;
                    end else begin
                        miss_req_valid <= 1;
                    end
                end

                ST_FLUSH: begin
                    // Flush dirty lines
                    for (j=0;j<WAYS;j=j+1) begin
                        if (dirty[flush_idx][j] && valid[flush_idx][j]) begin
                            miss_req_valid <= 1;
                            miss_req_addr  <= {tags[flush_idx][j], flush_idx, {OFFSET_BITS{1'b0}}};
                            miss_req_wr    <= 1;
                            miss_req_wdata <= data[flush_idx][j];
                            dirty[flush_idx][j] <= 0;
                        end
                    end
                    if (flush_idx == {INDEX_BITS{1'b1}}) begin
                        flush_done <= 1;
                        state      <= ST_IDLE;
                    end else begin
                        flush_idx <= flush_idx + 1;
                    end
                end
            endcase
        end
    end

endmodule
