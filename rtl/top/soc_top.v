// ============================================================
// soc_top.v - Industry SoC Top Level
// Integrates: Dual-core RISC-V, L1/L2/L3 cache, AXI4 crossbar,
//             NoC, GPU, DMA, Crypto, PCIe, USB, Ethernet,
//             Peripherals, Clock gen, Power ctrl, Debug, Security
// Technology: 28nm SAED32
// ============================================================
`timescale 1ns/1ps

module soc_top (
    // Reference clock
    input  wire         refclk_25m,
    input  wire         ext_rst_n,

    // JTAG debug
    input  wire         tck, tms, tdi,
    output wire         tdo,
    input  wire         trst_n,

    // PCIe (x4)
    input  wire [3:0]   pcie_rxp, pcie_rxn,
    output wire [3:0]   pcie_txp, pcie_txn,

    // USB 2.0
    inout  wire         usb_dp, usb_dn,

    // Gigabit Ethernet (RGMII)
    input  wire [3:0]   rgmii_rxd,
    input  wire         rgmii_rx_ctl, rgmii_rxc,
    output wire [3:0]   rgmii_txd,
    output wire         rgmii_tx_ctl, rgmii_txc,

    // MDIO (for Ethernet PHY config)
    input  wire         mdio_in,
    output wire         mdio_out, mdio_oe, mdc,

    // GPIO
    inout  wire [31:0]  gpio,

    // UART0
    input  wire         uart0_rxd,
    output wire         uart0_txd,

    // SPI
    output wire         spi_sclk, spi_mosi,
    input  wire         spi_miso,
    output wire [3:0]   spi_cs_n,

    // I2C
    inout  wire         i2c_sda,
    output wire         i2c_scl,

    // External interrupts
    input  wire [31:0]  ext_irq,

    // DDR memory interface (to PHY)
    output wire [15:0]  ddr_dq,
    output wire [1:0]   ddr_dqs_p, ddr_dqs_n,
    output wire [14:0]  ddr_addr,
    output wire [2:0]   ddr_ba,
    output wire         ddr_ras_n, ddr_cas_n, ddr_we_n,
    output wire         ddr_cs_n, ddr_cke, ddr_odt,
    output wire         ddr_clk_p, ddr_clk_n,

    // Test/scan interface
    input  wire         test_mode,
    input  wire         scan_en,
    input  wire         scan_in,
    output wire         scan_out
);

    // -------------------------------------------------------
    // Internal clock and reset
    // -------------------------------------------------------
    wire clk_core_0, clk_core_1, clk_l2, clk_l3, clk_noc;
    wire clk_gpu, clk_pcie, clk_usb, clk_eth, clk_dma;
    wire clk_crypto, clk_io, clk_mem, clk_periph, clk_debug;
    wire pll_locked;
    wire sys_rst_n, por_n;
    wire [3:0] rst_cause;
    wire wdt_rst_n;

    // POR
    por_gen u_por(.VDD(1'b1),.clk(refclk_25m),.por_n(por_n));

    // Reset controller
    reset_controller u_rst(.clk(refclk_25m),.por_n(por_n),.ext_rst_n(ext_rst_n),.wdt_rst_n(wdt_rst_n),.sw_rst(1'b0),.sys_rst_n(sys_rst_n),.rst_cause(rst_cause));

    // Always-on domain
    wire [15:0] clk_en_ao;
    wire soc_ready;
    always_on_domain u_ao(
        .clk_ao(refclk_25m), .por_n(por_n),
        .ext_irq(1'b0), .wake_src(16'b0),
        .sys_rst_n(), .pwr_on_req(),
        .pd_pwr_en(), .clk_en(clk_en_ao),
        .pd_pwr_ack(11'hFF), .pll_locked(pll_locked),
        .soc_ready(soc_ready)
    );

    // Clock generator
    wire dfs_ack_w;
    clock_gen_top u_clkgen(
        .refclk_25m(refclk_25m), .rst_n(sys_rst_n), .test_mode(test_mode),
        .clk_en(clk_en_ao), .dfs_fbdiv(8'd40), .dfs_postdiv(4'd1),
        .dfs_req(1'b0), .dfs_ack(dfs_ack_w),
        .clk_core_0(clk_core_0), .clk_core_1(clk_core_1),
        .clk_l2(clk_l2), .clk_l3(clk_l3), .clk_noc(clk_noc),
        .clk_gpu(clk_gpu), .clk_pcie(clk_pcie), .clk_usb(clk_usb),
        .clk_eth(clk_eth), .clk_dma(clk_dma), .clk_crypto(clk_crypto),
        .clk_io(clk_io), .clk_mem(clk_mem), .clk_periph(clk_periph),
        .clk_debug(clk_debug), .pll_locked(pll_locked)
    );

    // -------------------------------------------------------
    // CPU Cluster (dual-core RISC-V)
    // -------------------------------------------------------
    wire c0_icache_req_valid; wire [55:0] c0_icache_req_paddr;
    wire c0_icache_resp_valid; wire [511:0] c0_icache_resp_data; wire c0_icache_resp_miss;
    wire c0_dcache_req_valid; wire [55:0] c0_dcache_req_paddr;
    wire c0_dcache_req_wr; wire [2:0] c0_dcache_req_size;
    wire [63:0] c0_dcache_req_wdata; wire [7:0] c0_dcache_req_strb;
    wire c0_dcache_resp_valid; wire [63:0] c0_dcache_resp_rdata; wire c0_dcache_resp_miss;
    wire [63:0] c0_mcycle, c0_minstret, c1_mcycle, c1_minstret;
    wire [55:0] mmu_mem_req_addr; wire mmu_mem_req_valid;
    wire [63:0] mmu_mem_resp_data; wire mmu_mem_resp_valid; wire mmu_mem_resp_err;

    cpu_cluster u_cpu (
        .clk(clk_core_0), .rst_n(sys_rst_n),
        .c0_icache_req_valid(c0_icache_req_valid), .c0_icache_req_paddr(c0_icache_req_paddr),
        .c0_icache_resp_valid(c0_icache_resp_valid), .c0_icache_resp_data(c0_icache_resp_data),
        .c0_icache_resp_miss(c0_icache_resp_miss),
        .c0_dcache_req_valid(c0_dcache_req_valid), .c0_dcache_req_paddr(c0_dcache_req_paddr),
        .c0_dcache_req_wr(c0_dcache_req_wr), .c0_dcache_req_size(c0_dcache_req_size),
        .c0_dcache_req_wdata(c0_dcache_req_wdata), .c0_dcache_req_strb(c0_dcache_req_strb),
        .c0_dcache_resp_valid(c0_dcache_resp_valid), .c0_dcache_resp_rdata(c0_dcache_resp_rdata),
        .c0_dcache_resp_miss(c0_dcache_resp_miss),
        .c1_icache_req_valid(), .c1_icache_req_paddr(),
        .c1_icache_resp_valid(1'b0), .c1_icache_resp_data({512{1'b0}}), .c1_icache_resp_miss(1'b0),
        .c1_dcache_req_valid(), .c1_dcache_req_paddr(),
        .c1_dcache_req_wr(), .c1_dcache_req_size(), .c1_dcache_req_wdata(), .c1_dcache_req_strb(),
        .c1_dcache_resp_valid(1'b0), .c1_dcache_resp_rdata({64{1'b0}}), .c1_dcache_resp_miss(1'b0),
        .m_ext_irq(2'b0), .m_sw_irq(2'b0), .m_timer_irq(2'b0),
        .debug_halt(2'b0), .debug_halted(),
        .c0_mcycle(c0_mcycle), .c0_minstret(c0_minstret),
        .c1_mcycle(c1_mcycle), .c1_minstret(c1_minstret),
        .mmu_mem_req_addr(mmu_mem_req_addr), .mmu_mem_req_valid(mmu_mem_req_valid),
        .mmu_mem_resp_data(mmu_mem_resp_data), .mmu_mem_resp_valid(mmu_mem_resp_valid),
        .mmu_mem_resp_err(mmu_mem_resp_err),
        .satp(64'b0), .sfence_vma(1'b0)
    );

    // -------------------------------------------------------
    // L1 Caches (per core)
    // -------------------------------------------------------
    l1i_cache u_l1i0 (
        .clk(clk_core_0), .rst_n(sys_rst_n),
        .req_valid(c0_icache_req_valid), .req_paddr(c0_icache_req_paddr),
        .resp_valid(c0_icache_resp_valid), .resp_data(c0_icache_resp_data), .resp_miss(c0_icache_resp_miss),
        .refill_req_valid(), .refill_req_addr(), .refill_resp_valid(1'b0), .refill_resp_data({512{1'b0}}),
        .inv_valid(1'b0), .inv_addr({56{1'b0}}), .flush(1'b0)
    );

    l1d_cache u_l1d0 (
        .clk(clk_core_0), .rst_n(sys_rst_n),
        .req_valid(c0_dcache_req_valid), .req_addr(c0_dcache_req_paddr),
        .req_wr(c0_dcache_req_wr), .req_size(c0_dcache_req_size),
        .req_wdata(c0_dcache_req_wdata), .req_strb(c0_dcache_req_strb),
        .resp_valid(c0_dcache_resp_valid), .resp_rdata(c0_dcache_resp_rdata), .resp_miss(c0_dcache_resp_miss),
        .miss_req_valid(), .miss_req_addr(), .miss_req_wr(), .miss_req_wdata(),
        .miss_resp_valid(1'b0), .miss_resp_data({512{1'b0}}),
        .snoop_valid(1'b0), .snoop_addr({56{1'b0}}), .snoop_type(2'b0),
        .snoop_resp_valid(), .snoop_resp_data(), .snoop_resp_hit(),
        .flush_all(1'b0), .flush_done()
    );

    // -------------------------------------------------------
    // Debug
    // -------------------------------------------------------
    wire dmi_valid; wire [6:0] dmi_addr; wire [31:0] dmi_wdata; wire dmi_wr;
    wire [31:0] dmi_rdata; wire dmi_ready;

    debug_dtm u_dtm (
        .tck(tck), .tms(tms), .tdi(tdi), .tdo(tdo), .trst_n(trst_n),
        .dmi_valid(dmi_valid), .dmi_addr(dmi_addr), .dmi_wdata(dmi_wdata), .dmi_wr(dmi_wr),
        .dmi_rdata(dmi_rdata), .dmi_ready(dmi_ready)
    );

    debug_module u_dm (
        .clk(clk_debug), .rst_n(sys_rst_n),
        .dmi_valid(dmi_valid), .dmi_addr(dmi_addr), .dmi_wdata(dmi_wdata), .dmi_wr(dmi_wr),
        .dmi_rdata(dmi_rdata), .dmi_ready(dmi_ready),
        .hart_halt_req(), .hart_halted(2'b0), .hart_resume_req(), .hart_resumed(2'b0), .hart_reset_req(),
        .sb_addr(), .sb_rd(), .sb_wr(), .sb_wdata(), .sb_rdata(64'b0), .sb_ready(1'b0)
    );

    // -------------------------------------------------------
    // GPU
    // -------------------------------------------------------
    gpu_top u_gpu (
        .clk(clk_gpu), .rst_n(sys_rst_n),
        .s_awvalid(1'b0), .s_awaddr({64{1'b0}}), .s_awready(),
        .s_wvalid(1'b0), .s_wdata({128{1'b0}}), .s_wready(),
        .s_bvalid(), .s_bresp(), .s_bready(1'b1),
        .s_arvalid(1'b0), .s_araddr({64{1'b0}}), .s_arready(),
        .s_rvalid(), .s_rdata(), .s_rresp(), .s_rready(1'b1),
        .m_arvalid(), .m_araddr(), .m_arready(1'b0),
        .m_rvalid(1'b0), .m_rdata({128{1'b0}}), .m_rready(),
        .m_awvalid(), .m_awaddr(), .m_awready(1'b0),
        .m_wvalid(), .m_wdata(), .m_wready(1'b0),
        .m_bvalid(1'b0), .m_bresp(2'b0), .m_bready(),
        .gpu_irq(), .clk_en(1'b1)
    );

    // -------------------------------------------------------
    // DMA
    // -------------------------------------------------------
    dma_controller u_dma (
        .clk(clk_dma), .rst_n(sys_rst_n),
        .psel(1'b0), .pena(1'b0), .pwrite(1'b0), .paddr(16'b0), .pwdata(32'b0),
        .prdata(), .pready(), .pslverr(),
        .m_arvalid(), .m_araddr(), .m_arlen(), .m_arsize(), .m_arburst(), .m_arready(1'b0),
        .m_rvalid(1'b0), .m_rdata({128{1'b0}}), .m_rlast(1'b0), .m_rready(),
        .m_awvalid(), .m_awaddr(), .m_awlen(), .m_awsize(), .m_awburst(), .m_awready(1'b0),
        .m_wvalid(), .m_wdata(), .m_wstrb(), .m_wlast(), .m_wready(1'b0),
        .m_bvalid(1'b0), .m_bresp(2'b0), .m_bready(),
        .dma_irq()
    );

    // -------------------------------------------------------
    // Crypto Engine
    // -------------------------------------------------------
    crypto_top u_crypto (
        .clk(clk_crypto), .rst_n(sys_rst_n),
        .s_awvalid(1'b0),.s_awaddr({64{1'b0}}),.s_awready(),
        .s_wvalid(1'b0),.s_wdata({128{1'b0}}),.s_wready(),
        .s_bvalid(),.s_bresp(),.s_bready(1'b1),
        .s_arvalid(1'b0),.s_araddr({64{1'b0}}),.s_arready(),
        .s_rvalid(),.s_rdata(),.s_rresp(),.s_rready(1'b1),
        .crypto_irq()
    );

    // -------------------------------------------------------
    // PCIe
    // -------------------------------------------------------
    pcie_top u_pcie (
        .clk_pcie(clk_pcie), .rst_n(sys_rst_n),
        .rxp(pcie_rxp), .rxn(pcie_rxn), .txp(pcie_txp), .txn(pcie_txn),
        .m_awvalid(),.m_awaddr(),.m_awready(1'b0),
        .m_wvalid(),.m_wdata(),.m_wstrb(),.m_wlast(),.m_wready(1'b0),
        .m_bvalid(1'b0),.m_bresp(2'b0),.m_bready(),
        .m_arvalid(),.m_araddr(),.m_arready(1'b0),
        .m_rvalid(1'b0),.m_rdata({128{1'b0}}),.m_rresp(2'b0),.m_rready(),
        .s_awvalid(1'b0),.s_awaddr({64{1'b0}}),.s_awready(),
        .s_wvalid(1'b0),.s_wdata({128{1'b0}}),.s_wready(),
        .s_bvalid(),.s_bresp(),.s_bready(1'b1),
        .s_arvalid(1'b0),.s_araddr({64{1'b0}}),.s_arready(),
        .s_rvalid(),.s_rdata(),.s_rresp(),.s_rready(1'b1),
        .pcie_irq(),.cfg_reg_addr(12'b0),.cfg_wdata(32'b0),.cfg_wr(1'b0),.cfg_rdata()
    );

    // -------------------------------------------------------
    // USB
    // -------------------------------------------------------
    usb_top u_usb (
        .clk_usb(clk_usb), .rst_n(sys_rst_n),
        .usb_dp(usb_dp), .usb_dn(usb_dn),
        .s_awvalid(1'b0),.s_awaddr({32{1'b0}}),.s_awready(),
        .s_wvalid(1'b0),.s_wdata({32{1'b0}}),.s_wready(),
        .s_bvalid(),.s_bresp(),.s_bready(1'b1),
        .s_arvalid(1'b0),.s_araddr({32{1'b0}}),.s_arready(),
        .s_rvalid(),.s_rdata(),.s_rresp(),.s_rready(1'b1),
        .usb_irq()
    );

    // -------------------------------------------------------
    // Ethernet
    // -------------------------------------------------------
    eth_top u_eth (
        .clk_eth(clk_eth), .rst_n(sys_rst_n),
        .rgmii_rxd(rgmii_rxd),.rgmii_rx_ctl(rgmii_rx_ctl),.rgmii_rxc(rgmii_rxc),
        .rgmii_txd(rgmii_txd),.rgmii_tx_ctl(rgmii_tx_ctl),.rgmii_txc(rgmii_txc),
        .s_awvalid(1'b0),.s_awaddr({64{1'b0}}),.s_awready(),
        .s_wvalid(1'b0),.s_wdata({128{1'b0}}),.s_wready(),
        .s_bvalid(),.s_bresp(),.s_bready(1'b1),
        .s_arvalid(1'b0),.s_araddr({64{1'b0}}),.s_arready(),
        .s_rvalid(),.s_rdata(),.s_rresp(),.s_rready(1'b1),
        .m_awvalid(),.m_awaddr(),.m_awready(1'b0),
        .m_wvalid(),.m_wdata(),.m_wstrb(),.m_wlast(),.m_wready(1'b0),
        .m_bvalid(1'b0),.m_bready(),
        .m_arvalid(),.m_araddr(),.m_arready(1'b0),
        .m_rvalid(1'b0),.m_rdata({128{1'b0}}),.m_rready(),
        .eth_irq(),
        .mdio_in(mdio_in),.mdio_out(mdio_out),.mdio_oe(mdio_oe),.mdc(mdc)
    );

    // -------------------------------------------------------
    // Peripherals
    // -------------------------------------------------------
    gpio_top u_gpio (
        .clk(clk_periph), .rst_n(sys_rst_n),
        .psel(1'b0),.pena(1'b0),.pwrite(1'b0),.paddr(8'b0),.pwdata({32{1'b0}}),
        .prdata(),.pready(),.gpio_in(gpio),.gpio_out(),.gpio_oe(),.irq()
    );

    uart_top u_uart0 (
        .clk(clk_periph), .rst_n(sys_rst_n),
        .psel(1'b0),.pena(1'b0),.pwrite(1'b0),.paddr(8'b0),.pwdata(32'b0),
        .prdata(),.pready(),.pslverr(),
        .rxd(uart0_rxd),.txd(uart0_txd),.irq()
    );

    timer_top u_timer (
        .clk(clk_periph), .rst_n(sys_rst_n),
        .psel(1'b0),.pena(1'b0),.pwrite(1'b0),.paddr(8'b0),.pwdata(32'b0),
        .prdata(),.pready(),.irq()
    );

    wdt_top u_wdt (
        .clk(clk_periph), .rst_n(sys_rst_n),
        .psel(1'b0),.pena(1'b0),.pwrite(1'b0),.paddr(8'b0),.pwdata(32'b0),
        .prdata(),.pready(),.wdt_rst_n(wdt_rst_n),.wdt_irq()
    );

    // -------------------------------------------------------
    // Security
    // -------------------------------------------------------
    secure_boot u_secboot (
        .clk(clk_periph), .rst_n(sys_rst_n),
        .boot_req(soc_ready), .boot_ok(), .boot_fail(),
        .fw_hash({256{1'b0}}), .ref_hash({256{1'b0}}), .sec_state()
    );

    // -------------------------------------------------------
    // Tie-offs / DDR stub
    // -------------------------------------------------------
    assign ddr_dq      = 16'bz;
    assign ddr_dqs_p   = 2'bz;
    assign ddr_dqs_n   = 2'bz;
    assign ddr_addr    = 15'b0;
    assign ddr_ba      = 3'b0;
    assign ddr_ras_n   = 1'b1;
    assign ddr_cas_n   = 1'b1;
    assign ddr_we_n    = 1'b1;
    assign ddr_cs_n    = 1'b1;
    assign ddr_cke     = 1'b0;
    assign ddr_odt     = 1'b0;
    assign ddr_clk_p   = clk_mem;
    assign ddr_clk_n   = ~clk_mem;

    assign scan_out    = scan_in;

    // Tie off MMU memory response (stub)
    assign mmu_mem_resp_data  = 64'b0;
    assign mmu_mem_resp_valid = 1'b0;
    assign mmu_mem_resp_err   = 1'b0;

endmodule
