`timescale 1ns/1ps
// clock_mux.v - Glitch-free clock mux (2:1)
module clock_mux(
    input  wire clk0, clk1, input wire sel, input wire rst_n,
    output wire clk_out
);
    // Two-stage synchronizer based glitch-free mux
    reg q0a, q0b, q1a, q1b;
    always @(posedge clk0 or negedge rst_n) begin if(!rst_n) begin q0a<=0; q0b<=0; end else begin q0a<=~sel&&~q1b; q0b<=q0a; end end
    always @(posedge clk1 or negedge rst_n) begin if(!rst_n) begin q1a<=0; q1b<=0; end else begin q1a<= sel&&~q0b; q1b<=q1a; end end
    assign clk_out = (clk0 & q0b) | (clk1 & q1b);
endmodule
