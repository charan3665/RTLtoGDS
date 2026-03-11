`timescale 1ns/1ps
module l2_data #(parameter SETS=1024,WAYS=8,LINE_BITS=512,INDEX_BITS=10)(
    input wire clk,
    input wire [INDEX_BITS-1:0] rd_idx, input wire [$clog2(WAYS)-1:0] rd_way, output reg [LINE_BITS-1:0] rd_data,
    input wire wr_en, input wire [INDEX_BITS-1:0] wr_idx, input wire [$clog2(WAYS)-1:0] wr_way, input wire [LINE_BITS-1:0] wr_data
);
    reg [LINE_BITS-1:0] mem[0:SETS-1][0:WAYS-1];
    always @(posedge clk) begin
        if(wr_en) mem[wr_idx][wr_way]<=wr_data;
        rd_data<=mem[rd_idx][rd_way];
    end
endmodule
