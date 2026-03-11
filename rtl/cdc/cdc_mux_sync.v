`timescale 1ns/1ps
module cdc_mux_sync #(parameter DW=32)(
    input wire clk_dst, input wire rst_dst_n,
    input wire [DW-1:0] data_a, input wire [DW-1:0] data_b,
    input wire sel,  // already synchronized
    output wire [DW-1:0] data_out
);
    // Safe multiplexer: data must be stable across the mux boundary
    // sel must be synchronized to clk_dst before use here
    assign data_out = sel ? data_b : data_a;
endmodule
