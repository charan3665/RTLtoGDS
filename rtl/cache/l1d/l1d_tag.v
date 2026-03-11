`timescale 1ns/1ps
module l1d_tag #(parameter SETS=128, WAYS=4, TAG_BITS=43, INDEX_BITS=7)(
    input wire clk, input wire rst_n,
    input wire rd_en, input wire [INDEX_BITS-1:0] rd_idx,
    output reg [WAYS*TAG_BITS-1:0] rd_tag, output reg [WAYS-1:0] rd_valid, output reg [WAYS-1:0] rd_dirty,
    input wire wr_en, input wire [INDEX_BITS-1:0] wr_idx, input wire [$clog2(WAYS)-1:0] wr_way,
    input wire [TAG_BITS-1:0] wr_tag, input wire wr_valid, input wire wr_dirty,
    input wire clr_dirty_en, input wire [INDEX_BITS-1:0] clr_dirty_idx, input wire [$clog2(WAYS)-1:0] clr_dirty_way
);
    reg [TAG_BITS-1:0] tags[0:SETS-1][0:WAYS-1];
    reg valids[0:SETS-1][0:WAYS-1];
    reg dirtys[0:SETS-1][0:WAYS-1];
    integer i,j;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) for(i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) begin valids[i][j]<=0; dirtys[i][j]<=0; end
        else begin
            if(wr_en) begin tags[wr_idx][wr_way]<=wr_tag; valids[wr_idx][wr_way]<=wr_valid; dirtys[wr_idx][wr_way]<=wr_dirty; end
            if(clr_dirty_en) dirtys[clr_dirty_idx][clr_dirty_way]<=0;
        end
    end
    always @(*) for(j=0;j<WAYS;j=j+1) begin
        rd_tag[j*TAG_BITS+:TAG_BITS]=tags[rd_idx][j]; rd_valid[j]=valids[rd_idx][j]; rd_dirty[j]=dirtys[rd_idx][j];
    end
endmodule
