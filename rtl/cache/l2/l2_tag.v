`timescale 1ns/1ps
module l2_tag #(parameter SETS=1024,WAYS=8,TAG_BITS=40,INDEX_BITS=10)(
    input wire clk, input wire rst_n,
    input wire [INDEX_BITS-1:0] rd_idx, output reg [WAYS*TAG_BITS-1:0] rd_tag, output reg [WAYS*2-1:0] rd_mesi,
    input wire wr_en, input wire [INDEX_BITS-1:0] wr_idx, input wire [$clog2(WAYS)-1:0] wr_way,
    input wire [TAG_BITS-1:0] wr_tag, input wire [1:0] wr_mesi
);
    reg [TAG_BITS-1:0] tags[0:SETS-1][0:WAYS-1]; reg [1:0] mesi[0:SETS-1][0:WAYS-1];
    integer i,j;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) for(i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) mesi[i][j]<=2'b00;
        else if(wr_en) begin tags[wr_idx][wr_way]<=wr_tag; mesi[wr_idx][wr_way]<=wr_mesi; end
    end
    always @(*) for(j=0;j<WAYS;j=j+1) begin rd_tag[j*TAG_BITS+:TAG_BITS]=tags[rd_idx][j]; rd_mesi[j*2+:2]=mesi[rd_idx][j]; end
endmodule
