`timescale 1ns/1ps
module texture_cache #(parameter SIMD_WIDTH=32, ENTRIES=1024)(
    input wire clk, input wire rst_n,
    input wire req_valid, input wire [SIMD_WIDTH*32-1:0] req_u, input wire [SIMD_WIDTH*32-1:0] req_v,
    output reg resp_valid, output reg [SIMD_WIDTH*32-1:0] resp_texel
);
    // Simple direct-mapped texture cache
    reg [31:0] tcache[0:ENTRIES-1];
    integer t; reg [9:0] cidx;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) resp_valid<=0;
        else begin
            resp_valid<=req_valid;
            for(t=0;t<SIMD_WIDTH;t=t+1) begin
                cidx=(req_u[t*32+:10]^req_v[t*32+:10]);
                resp_texel[t*32+:32]<=tcache[cidx];
            end
        end
    end
endmodule
