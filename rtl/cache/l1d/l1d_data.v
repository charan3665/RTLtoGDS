`timescale 1ns/1ps
module l1d_data #(parameter SETS=128, WAYS=4, LINE_BITS=512, INDEX_BITS=7, XLEN=64)(
    input wire clk,
    input wire rd_en, input wire [INDEX_BITS-1:0] rd_idx, input wire [$clog2(WAYS)-1:0] rd_way,
    output reg [LINE_BITS-1:0] rd_data,
    input wire wr_en, input wire [INDEX_BITS-1:0] wr_idx, input wire [$clog2(WAYS)-1:0] wr_way,
    input wire [LINE_BITS-1:0] wr_data, input wire [(LINE_BITS/8)-1:0] wr_be
);
    reg [LINE_BITS-1:0] mem[0:SETS-1][0:WAYS-1];
    integer i;
    always @(posedge clk) begin
        if(wr_en) begin
            for(i=0;i<LINE_BITS/8;i=i+1)
                if(wr_be[i]) mem[wr_idx][wr_way][i*8+:8]<=wr_data[i*8+:8];
        end
        if(rd_en) rd_data<=mem[rd_idx][rd_way];
    end
endmodule
