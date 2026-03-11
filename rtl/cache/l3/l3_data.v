`timescale 1ns/1ps
module l3_data #(parameter SETS=4096,WAYS=16,LINE_BITS=512,INDEX_BITS=12)(
    input wire clk,
    input wire [INDEX_BITS-1:0] rd_idx, input wire [$clog2(WAYS)-1:0] rd_way, output reg [LINE_BITS-1:0] rd_data,
    input wire wr_en, input wire [INDEX_BITS-1:0] wr_idx, input wire [$clog2(WAYS)-1:0] wr_way, input wire [LINE_BITS-1:0] wr_data
);
    reg [LINE_BITS-1:0] m[0:SETS-1][0:WAYS-1];
    always @(posedge clk) begin if(wr_en) m[wr_idx][wr_way]<=wr_data; rd_data<=m[rd_idx][rd_way]; end
endmodule
