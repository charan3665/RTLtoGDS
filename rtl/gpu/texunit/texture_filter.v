`timescale 1ns/1ps
module texture_filter #(parameter SIMD_WIDTH=32)(
    input wire clk, input wire rst_n,
    input wire in_valid, input wire [SIMD_WIDTH*32-1:0] in_texel,
    output reg out_valid, output reg [SIMD_WIDTH*32-1:0] out_texel
);
    // Bilinear filter: 4 samples -> interpolate (simplified pipeline)
    reg [SIMD_WIDTH*32-1:0] s1, s2;
    reg v1, v2;
    integer t;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin v1<=0; v2<=0; out_valid<=0; end
        else begin
            v1<=in_valid; s1<=in_texel;
            v2<=v1; s2<=s1;
            out_valid<=v2;
            for(t=0;t<SIMD_WIDTH;t=t+1)
                out_texel[t*32+:32]<=(s2[t*32+:16]+s1[t*32+:16])>>1; // bilinear approx
        end
    end
endmodule
