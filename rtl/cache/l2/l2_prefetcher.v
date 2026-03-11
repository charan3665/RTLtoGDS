// ============================================================
// l2_prefetcher.v - Stream-based L2 Prefetcher
// Detects sequential access streams, issues prefetch requests
// ============================================================
`timescale 1ns/1ps

module l2_prefetcher #(
    parameter PADDR_WIDTH   = 56,
    parameter LINE_BYTES    = 64,
    parameter N_STREAMS     = 8,
    parameter PREFETCH_DIST = 4    // lines ahead to prefetch
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Miss address input
    input  wire                     miss_valid,
    input  wire [PADDR_WIDTH-1:0]   miss_addr,

    // Prefetch request output
    output reg                      pf_req_valid,
    output reg  [PADDR_WIDTH-1:0]   pf_req_addr,
    input  wire                     pf_req_ready,

    // Enable
    input  wire                     enable
);

    localparam STRIDE = LINE_BYTES;

    // Stream tracker: monitors N_STREAMS independent streams
    reg [PADDR_WIDTH-1:0]  stream_base  [0:N_STREAMS-1];
    reg signed [31:0]      stream_stride[0:N_STREAMS-1];
    reg [2:0]              stream_conf  [0:N_STREAMS-1]; // confidence counter
    reg [N_STREAMS-1:0]    stream_valid;
    reg [PADDR_WIDTH-1:0]  stream_pf_ptr[0:N_STREAMS-1]; // next prefetch address

    integer i;
    reg [$clog2(N_STREAMS)-1:0] hit_stream, alloc_stream;
    reg stream_hit;

    // History buffer for stride detection
    reg [PADDR_WIDTH-1:0]  hist [0:3];
    reg [1:0]              hist_ptr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stream_valid <= {N_STREAMS{1'b0}};
            pf_req_valid <= 1'b0;
            hist_ptr     <= 2'b0;
        end else begin
            pf_req_valid <= 1'b0;

            if (miss_valid && enable) begin
                // Update history
                hist[hist_ptr] <= miss_addr;
                hist_ptr       <= hist_ptr + 1;

                // Check if address matches existing stream
                stream_hit   = 1'b0;
                hit_stream   = {$clog2(N_STREAMS){1'b0}};
                alloc_stream = {$clog2(N_STREAMS){1'b0}};

                for (i = 0; i < N_STREAMS; i = i + 1) begin
                    if (stream_valid[i]) begin
                        // Check if current miss is expected next address in stream
                        if (miss_addr == stream_base[i] + stream_stride[i]) begin
                            stream_hit = 1; hit_stream = i[$clog2(N_STREAMS)-1:0];
                        end
                    end
                end

                if (stream_hit) begin
                    // Update stream
                    stream_base[hit_stream] <= miss_addr;
                    if (stream_conf[hit_stream] < 3'd7)
                        stream_conf[hit_stream] <= stream_conf[hit_stream] + 1;
                    // Issue prefetch if confidence high enough
                    if (stream_conf[hit_stream] >= 3'd2) begin
                        pf_req_valid <= 1'b1;
                        pf_req_addr  <= stream_pf_ptr[hit_stream];
                        stream_pf_ptr[hit_stream] <= stream_pf_ptr[hit_stream] + STRIDE;
                    end
                end else begin
                    // Allocate new stream entry
                    for (i = N_STREAMS-1; i >= 0; i = i - 1)
                        if (!stream_valid[i]) alloc_stream = i[$clog2(N_STREAMS)-1:0];
                    stream_valid [alloc_stream] <= 1'b1;
                    stream_base  [alloc_stream] <= miss_addr;
                    stream_stride[alloc_stream] <= STRIDE;
                    stream_conf  [alloc_stream] <= 3'd0;
                    stream_pf_ptr[alloc_stream] <= miss_addr + (PREFETCH_DIST * STRIDE);
                end
            end
        end
    end

endmodule
