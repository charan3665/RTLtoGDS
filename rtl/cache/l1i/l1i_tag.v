// ============================================================
// l1i_tag.v - L1I Tag Array (SRAM-based, 4-way, 128 sets)
// Separate tag SRAM instance for physical implementation
// ============================================================
`timescale 1ns/1ps

module l1i_tag #(
    parameter SETS      = 128,
    parameter WAYS      = 4,
    parameter TAG_BITS  = 43,
    parameter INDEX_BITS= 7
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     rd_en,
    input  wire [INDEX_BITS-1:0]    rd_idx,
    output reg  [WAYS*TAG_BITS-1:0] rd_tag,
    output reg  [WAYS-1:0]          rd_valid,
    input  wire                     wr_en,
    input  wire [INDEX_BITS-1:0]    wr_idx,
    input  wire [$clog2(WAYS)-1:0]  wr_way,
    input  wire [TAG_BITS-1:0]      wr_tag,
    input  wire                     wr_valid,
    input  wire                     inv_en,
    input  wire [INDEX_BITS-1:0]    inv_idx
);
    reg [TAG_BITS-1:0] tags  [0:SETS-1][0:WAYS-1];
    reg                valids[0:SETS-1][0:WAYS-1];
    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) valids[i][j]<=1'b0;
        end else begin
            if (wr_en) begin tags[wr_idx][wr_way]<=wr_tag; valids[wr_idx][wr_way]<=wr_valid; end
            if (inv_en) for(j=0;j<WAYS;j=j+1) valids[inv_idx][j]<=1'b0;
        end
    end
    always @(*) begin
        for(j=0;j<WAYS;j=j+1) begin
            rd_tag  [j*TAG_BITS +: TAG_BITS] = tags  [rd_idx][j];
            rd_valid[j]                      = valids[rd_idx][j];
        end
    end
endmodule
