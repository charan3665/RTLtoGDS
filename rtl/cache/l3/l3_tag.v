`timescale 1ns/1ps
module l3_tag #(parameter SETS=4096,WAYS=16,TAG_BITS=38,INDEX_BITS=12)(
    input wire clk, input wire [INDEX_BITS-1:0] rd_idx, output reg [WAYS*TAG_BITS-1:0] rd_tag, output reg [WAYS-1:0] rd_valid,
    input wire wr_en, input wire [INDEX_BITS-1:0] wr_idx, input wire [$clog2(WAYS)-1:0] wr_way, input wire [TAG_BITS-1:0] wr_tag, input wire wr_val
);
    reg [TAG_BITS-1:0] t[0:SETS-1][0:WAYS-1]; reg v[0:SETS-1][0:WAYS-1];
    integer i,j;
    initial for(i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) v[i][j]=0;
    always @(posedge clk) if(wr_en) begin t[wr_idx][wr_way]<=wr_tag; v[wr_idx][wr_way]<=wr_val; end
    always @(*) for(j=0;j<WAYS;j=j+1) begin rd_tag[j*TAG_BITS+:TAG_BITS]=t[rd_idx][j]; rd_valid[j]=v[rd_idx][j]; end
endmodule
