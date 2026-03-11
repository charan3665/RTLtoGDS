`timescale 1ns/1ps
module timer_comparator(
    input wire clk, input wire rst_n,
    input wire [31:0] cnt, input wire [31:0] cmp_val, input wire cmp_en,
    output reg match
);
    always @(posedge clk or negedge rst_n) begin if(!rst_n) match<=0; else match<=cmp_en&&(cnt==cmp_val); end
endmodule
