// ============================================================
// pll_top.v - Phase-Locked Loop Top Level (28nm SAED32)
// Generates multiple output clocks from 25MHz reference
// ============================================================
`timescale 1ns/1ps
module pll_top #(
    parameter REF_FREQ_MHZ = 25,
    parameter N_CLOCKS     = 8
)(
    input  wire         refclk,    // 25 MHz reference
    input  wire         rst_n,
    input  wire         test_mode,
    // PLL configuration
    input  wire [7:0]   fbdiv,     // feedback divider
    input  wire [3:0]   refdiv,    // reference divider
    input  wire [3:0]   postdiv1,  // output divider 1
    input  wire [3:0]   postdiv2,  // output divider 2
    // Clock outputs
    output wire         clk_out0,  // 1 GHz (fbdiv=40, refdiv=1, post=1)
    output wire         clk_out1,  // 500 MHz
    output wire         clk_out2,  // 250 MHz
    output wire         clk_out3,  // 125 MHz
    output wire         clk_out4,  // 200 MHz
    output wire         clk_out5,  // 100 MHz
    output wire         clk_out6,  // 50 MHz
    output wire         clk_out7,  // 25 MHz
    output wire         pll_locked,
    output wire         pll_fout_vco  // raw VCO output
);
    // Behavioral PLL model
    pll_core u_pll_core (
        .refclk(refclk), .rst_n(rst_n), .test_mode(test_mode),
        .fbdiv(fbdiv), .refdiv(refdiv), .postdiv1(postdiv1), .postdiv2(postdiv2),
        .clk_out(pll_fout_vco), .locked(pll_locked)
    );
    // Clock dividers
    clock_divider #(.DIV(1))  u_div1 (.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out0));
    clock_divider #(.DIV(2))  u_div2 (.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out1));
    clock_divider #(.DIV(4))  u_div4 (.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out2));
    clock_divider #(.DIV(8))  u_div8 (.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out3));
    clock_divider #(.DIV(5))  u_div5 (.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out4));
    clock_divider #(.DIV(10)) u_div10(.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out5));
    clock_divider #(.DIV(20)) u_div20(.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out6));
    clock_divider #(.DIV(40)) u_div40(.clk_in(pll_fout_vco),.rst_n(rst_n),.clk_out(clk_out7));
endmodule
