// ============================================================
// l1i_data.v - L1I Data Array (512-bit line, 4-way, 128 sets)
// ============================================================
`timescale 1ns/1ps

module l1i_data #(
    parameter SETS      = 128,
    parameter WAYS      = 4,
    parameter LINE_BITS = 512,
    parameter INDEX_BITS= 7
)(
    input  wire                       clk,
    input  wire                       rd_en,
    input  wire [INDEX_BITS-1:0]      rd_idx,
    input  wire [$clog2(WAYS)-1:0]    rd_way,
    output reg  [LINE_BITS-1:0]       rd_data,
    input  wire                       wr_en,
    input  wire [INDEX_BITS-1:0]      wr_idx,
    input  wire [$clog2(WAYS)-1:0]    wr_way,
    input  wire [LINE_BITS-1:0]       wr_data
);
    reg [LINE_BITS-1:0] data[0:SETS-1][0:WAYS-1];
    always @(posedge clk) begin
        if (wr_en) data[wr_idx][wr_way] <= wr_data;
        if (rd_en) rd_data <= data[rd_idx][rd_way];
    end
endmodule
