// ============================================================
// clock_gen_top.v - SoC Clock Generator Top Level
// Manages 15+ clock domains for all subsystems
// ============================================================
`timescale 1ns/1ps
module clock_gen_top (
    input  wire         refclk_25m,
    input  wire         rst_n,
    input  wire         test_mode,
    // Enable controls (from PMU)
    input  wire [15:0]  clk_en,
    // DFS interface
    input  wire [7:0]   dfs_fbdiv,
    input  wire [3:0]   dfs_postdiv,
    input  wire         dfs_req,
    output wire         dfs_ack,
    // Generated clocks
    output wire         clk_core_0,  // 1 GHz - CPU core 0
    output wire         clk_core_1,  // 1 GHz - CPU core 1
    output wire         clk_l2,      // 500 MHz - L2 cache
    output wire         clk_l3,      // 250 MHz - L3 cache
    output wire         clk_noc,     // 500 MHz - NoC
    output wire         clk_gpu,     // 800 MHz - GPU
    output wire         clk_pcie,    // 250 MHz - PCIe TL/DL
    output wire         clk_usb,     // 60 MHz  - USB
    output wire         clk_eth,     // 125 MHz - Ethernet
    output wire         clk_dma,     // 250 MHz - DMA
    output wire         clk_crypto,  // 400 MHz - Crypto
    output wire         clk_io,      // 100 MHz - IO ring
    output wire         clk_mem,     // 200 MHz - Memory controller
    output wire         clk_periph,  // 50 MHz  - APB peripherals
    output wire         clk_debug,   // 25 MHz  - Debug/JTAG
    output wire         pll_locked
);
    wire pll_vco, pll_lk;
    wire [7:0] cur_fbdiv;
    wire [3:0] cur_postdiv;

    // Main PLL
    pll_top u_main_pll (
        .refclk(refclk_25m), .rst_n(rst_n), .test_mode(test_mode),
        .fbdiv(cur_fbdiv), .refdiv(4'd1), .postdiv1(cur_postdiv), .postdiv2(4'd1),
        .clk_out0(pll_vco), .clk_out1(), .clk_out2(), .clk_out3(),
        .clk_out4(), .clk_out5(), .clk_out6(), .clk_out7(),
        .pll_locked(pll_lk), .pll_fout_vco()
    );
    assign pll_locked = pll_lk;

    // DFS controller
    dfs_controller u_dfs (
        .clk(refclk_25m), .rst_n(rst_n),
        .workload_hint(8'd200), .temp_reading(8'd70), .volt_reading(8'd180),
        .pll_locked(pll_lk), .pll_fbdiv(cur_fbdiv), .pll_postdiv(cur_postdiv),
        .change_req(dfs_req), .change_ack(dfs_ack), .freq_level()
    );

    // Per-domain clock dividers and gating
    wire clk_1g, clk_500m, clk_250m, clk_200m, clk_125m, clk_100m, clk_60m, clk_50m, clk_25m, clk_400m, clk_800m;

    clock_divider #(.DIV(1))  u_1g   (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_1g));
    clock_divider #(.DIV(2))  u_500m (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_500m));
    clock_divider #(.DIV(4))  u_250m (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_250m));
    clock_divider #(.DIV(5))  u_200m (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_200m));
    clock_divider #(.DIV(8))  u_125m (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_125m));
    clock_divider #(.DIV(10)) u_100m (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_100m));
    clock_divider #(.DIV(16)) u_60m  (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_60m));
    clock_divider #(.DIV(20)) u_50m  (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_50m));
    clock_divider #(.DIV(40)) u_25m  (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_25m));
    clock_divider #(.DIV(2))  u_800m (.clk_in(pll_vco),.rst_n(rst_n),.clk_out(clk_800m)); // Second PLL conceptually
    clock_divider #(.DIV(2))  u_400m (.clk_in(clk_800m),.rst_n(rst_n),.clk_out(clk_400m));

    // ICG cells per domain
    clock_gating_cell icg_core0  (.CK(clk_1g),    .EN(clk_en[0]),  .TE(test_mode), .Q(clk_core_0));
    clock_gating_cell icg_core1  (.CK(clk_1g),    .EN(clk_en[1]),  .TE(test_mode), .Q(clk_core_1));
    clock_gating_cell icg_l2     (.CK(clk_500m),  .EN(clk_en[2]),  .TE(test_mode), .Q(clk_l2));
    clock_gating_cell icg_l3     (.CK(clk_250m),  .EN(clk_en[3]),  .TE(test_mode), .Q(clk_l3));
    clock_gating_cell icg_noc    (.CK(clk_500m),  .EN(clk_en[4]),  .TE(test_mode), .Q(clk_noc));
    clock_gating_cell icg_gpu    (.CK(clk_800m),  .EN(clk_en[5]),  .TE(test_mode), .Q(clk_gpu));
    clock_gating_cell icg_pcie   (.CK(clk_250m),  .EN(clk_en[6]),  .TE(test_mode), .Q(clk_pcie));
    clock_gating_cell icg_usb    (.CK(clk_60m),   .EN(clk_en[7]),  .TE(test_mode), .Q(clk_usb));
    clock_gating_cell icg_eth    (.CK(clk_125m),  .EN(clk_en[8]),  .TE(test_mode), .Q(clk_eth));
    clock_gating_cell icg_dma    (.CK(clk_250m),  .EN(clk_en[9]),  .TE(test_mode), .Q(clk_dma));
    clock_gating_cell icg_crypto (.CK(clk_400m),  .EN(clk_en[10]), .TE(test_mode), .Q(clk_crypto));
    clock_gating_cell icg_io     (.CK(clk_100m),  .EN(clk_en[11]), .TE(test_mode), .Q(clk_io));
    clock_gating_cell icg_mem    (.CK(clk_200m),  .EN(clk_en[12]), .TE(test_mode), .Q(clk_mem));
    clock_gating_cell icg_periph (.CK(clk_50m),   .EN(clk_en[13]), .TE(test_mode), .Q(clk_periph));
    clock_gating_cell icg_debug  (.CK(clk_25m),   .EN(1'b1),       .TE(test_mode), .Q(clk_debug));

endmodule
