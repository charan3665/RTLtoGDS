`timescale 1ns/1ps
// rasterizer_top.v - GPU Rasterizer Pipeline Top
module rasterizer_top #(parameter DW=32)(
    input  wire         clk, input wire rst_n,
    input  wire         tri_valid,
    input  wire [DW-1:0] v0x, v0y, v1x, v1y, v2x, v2y,
    output wire         tri_ready,
    output reg          frag_valid,
    output reg  [DW-1:0] frag_x, frag_y,
    output reg  [DW-1:0] frag_z,
    output reg  [DW-1:0] frag_w0, frag_w1, frag_w2  // barycentric
);
    wire ts_valid; wire [DW-1:0] ts_area, ts_e01, ts_e12, ts_e20;
    triangle_setup u_ts(.clk(clk),.rst_n(rst_n),.tri_valid(tri_valid),.v0x(v0x),.v0y(v0y),.v1x(v1x),.v1y(v1y),.v2x(v2x),.v2y(v2y),.ready(tri_ready),.out_valid(ts_valid),.area(ts_area),.e01(ts_e01),.e12(ts_e12),.e20(ts_e20));
    fragment_gen u_fg(.clk(clk),.rst_n(rst_n),.in_valid(ts_valid),.v0x(v0x),.v0y(v0y),.v2x(v2x),.v2y(v2y),.area(ts_area),.e01(ts_e01),.e12(ts_e12),.e20(ts_e20),.frag_valid(frag_valid),.frag_x(frag_x),.frag_y(frag_y),.frag_z(frag_z),.frag_w0(frag_w0),.frag_w1(frag_w1),.frag_w2(frag_w2));
endmodule
