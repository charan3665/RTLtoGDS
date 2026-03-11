`timescale 1ns/1ps
module texture_unit #(parameter SIMD_WIDTH=32)(
    input wire clk, input wire rst_n,
    input wire req_valid, input wire [SIMD_WIDTH*32-1:0] req_u, input wire [SIMD_WIDTH*32-1:0] req_v,
    input wire [3:0] tex_idx, output wire req_ready,
    output reg resp_valid, output reg [SIMD_WIDTH*32-1:0] resp_texel
);
    wire tc_valid; wire [SIMD_WIDTH*32-1:0] tc_addr;
    texture_cache u_tc(.clk(clk),.rst_n(rst_n),.req_valid(req_valid),.req_u(req_u),.req_v(req_v),.resp_valid(tc_valid),.resp_texel(resp_texel));
    wire tf_valid; wire [SIMD_WIDTH*32-1:0] tf_out;
    texture_filter u_tf(.clk(clk),.rst_n(rst_n),.in_valid(tc_valid),.in_texel(resp_texel),.out_valid(resp_valid),.out_texel(resp_texel));
    assign req_ready=1'b1;
endmodule
