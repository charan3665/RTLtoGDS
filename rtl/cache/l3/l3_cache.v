// ============================================================
// l3_cache.v - Last-Level Cache (16MB, 16-way, banked)
// 4-slice banked, inclusive, handles all L2 misses
// ============================================================
`timescale 1ns/1ps

module l3_cache #(
    parameter PADDR_WIDTH  = 56,
    parameter CACHE_SIZE   = 16777216,  // 16 MB
    parameter WAYS         = 16,
    parameter LINE_BYTES   = 64,
    parameter LINE_BITS    = 512,
    parameter N_SLICES     = 4,
    parameter SLICE_SETS   = CACHE_SIZE / (N_SLICES * WAYS * LINE_BYTES)  // 4096/slice
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // L2 request interface
    input  wire                     l2_req_valid,
    input  wire [PADDR_WIDTH-1:0]   l2_req_addr,
    input  wire                     l2_req_wr,
    input  wire [LINE_BITS-1:0]     l2_req_wdata,
    output wire                     l2_req_ready,

    output reg                      l2_resp_valid,
    output reg  [LINE_BITS-1:0]     l2_resp_data,

    // Memory controller interface (DRAM)
    output reg                      dram_req_valid,
    output reg  [PADDR_WIDTH-1:0]   dram_req_addr,
    output reg                      dram_req_wr,
    output reg  [LINE_BITS-1:0]     dram_req_wdata,
    input  wire                     dram_resp_valid,
    input  wire [LINE_BITS-1:0]     dram_resp_data,

    // NoC interface (for multi-chip or CXL)
    output wire [PADDR_WIDTH-1:0]   noc_req_addr,
    output wire                     noc_req_valid
);

    // Slice select based on address bits
    wire [1:0] slice_sel = l2_req_addr[$clog2(LINE_BYTES)+1:$clog2(LINE_BYTES)];

    // Instantiate 4 slices
    wire [N_SLICES-1:0]  slice_req_valid, slice_req_ready, slice_resp_valid;
    wire [LINE_BITS-1:0] slice_resp_data[0:N_SLICES-1];

    genvar g;
    generate
        for (g = 0; g < N_SLICES; g = g + 1) begin : gen_slices
            l3_slice #(
                .PADDR_WIDTH(PADDR_WIDTH), .WAYS(WAYS),
                .SETS(SLICE_SETS), .LINE_BYTES(LINE_BYTES), .LINE_BITS(LINE_BITS)
            ) u_slice (
                .clk(clk), .rst_n(rst_n),
                .req_valid(slice_req_valid[g]),
                .req_addr(l2_req_addr),
                .req_wr(l2_req_wr),
                .req_wdata(l2_req_wdata),
                .req_ready(slice_req_ready[g]),
                .resp_valid(slice_resp_valid[g]),
                .resp_data(slice_resp_data[g]),
                .dram_req_valid(dram_req_valid),
                .dram_req_addr(dram_req_addr),
                .dram_req_wr(dram_req_wr),
                .dram_req_wdata(dram_req_wdata),
                .dram_resp_valid(dram_resp_valid),
                .dram_resp_data(dram_resp_data)
            );
            assign slice_req_valid[g] = l2_req_valid && (slice_sel == g[1:0]);
        end
    endgenerate

    assign l2_req_ready = slice_req_ready[slice_sel];

    always @(*) begin
        l2_resp_valid = slice_resp_valid[slice_sel];
        l2_resp_data  = slice_resp_data[slice_sel];
    end

    assign noc_req_valid = 1'b0;
    assign noc_req_addr  = {PADDR_WIDTH{1'b0}};

endmodule
