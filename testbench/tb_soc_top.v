// ============================================================
// tb_soc_top.v - SoC Top Level Comprehensive Testbench
// Generates all clock domains, full reset sequence, and
// basic stimulus including: boot, UART, GPIO, DMA, AXI access
// ============================================================
`timescale 1ns/1ps

module tb_soc_top;

    // ---- Parameters ----
    localparam CLK_PERIOD_25M  = 40.0;   // 25 MHz
    localparam CLK_PERIOD_1G   = 1.0;    // 1 GHz (core)

    // ---- DUT Ports ----
    reg         refclk_25m;
    reg         ext_rst_n;
    reg         tck, tms, tdi;
    wire        tdo;
    reg         trst_n;

    // PCIe
    wire [3:0]  pcie_txp, pcie_txn;

    // USB
    wire        usb_dp_wire, usb_dn_wire;
    reg         usb_dp_drive, usb_dn_drive;
    wire        usb_dp = usb_dp_drive ? usb_dp_wire : 1'bz;
    wire        usb_dn = usb_dn_drive ? usb_dn_wire : 1'bz;

    // Ethernet RGMII
    reg  [3:0]  rgmii_rxd;
    reg         rgmii_rx_ctl, rgmii_rxc;
    wire [3:0]  rgmii_txd;
    wire        rgmii_tx_ctl, rgmii_txc;
    wire        mdio_out, mdio_oe, mdc;

    // GPIO
    wire [31:0] gpio;
    reg  [31:0] gpio_drv;
    reg  [31:0] gpio_oe_drv;
    genvar gi;
    generate
        for (gi = 0; gi < 32; gi = gi + 1) begin : gen_gpio
            assign gpio[gi] = gpio_oe_drv[gi] ? gpio_drv[gi] : 1'bz;
        end
    endgenerate

    // UART
    reg         uart0_rxd;
    wire        uart0_txd;

    // SPI
    wire        spi_sclk, spi_mosi;
    reg         spi_miso;
    wire [3:0]  spi_cs_n;

    // I2C
    wire        i2c_sda;
    wire        i2c_scl;

    // Test signals
    reg         test_mode, scan_en, scan_in;
    wire        scan_out;
    reg  [31:0] ext_irq;

    // DDR stub
    wire [15:0] ddr_dq;
    wire [1:0]  ddr_dqs_p, ddr_dqs_n;
    wire [14:0] ddr_addr;
    wire [2:0]  ddr_ba;
    wire        ddr_ras_n, ddr_cas_n, ddr_we_n;
    wire        ddr_cs_n, ddr_cke, ddr_odt;
    wire        ddr_clk_p, ddr_clk_n;

    // ---- DUT instantiation ----
    soc_top u_dut (
        .refclk_25m(refclk_25m),
        .ext_rst_n(ext_rst_n),
        .tck(tck), .tms(tms), .tdi(tdi), .tdo(tdo), .trst_n(trst_n),
        .pcie_rxp(4'b0), .pcie_rxn(4'b1),
        .pcie_txp(pcie_txp), .pcie_txn(pcie_txn),
        .usb_dp(usb_dp), .usb_dn(usb_dn),
        .rgmii_rxd(rgmii_rxd), .rgmii_rx_ctl(rgmii_rx_ctl), .rgmii_rxc(rgmii_rxc),
        .rgmii_txd(rgmii_txd), .rgmii_tx_ctl(rgmii_tx_ctl), .rgmii_txc(rgmii_txc),
        .mdio_in(1'b1), .mdio_out(mdio_out), .mdio_oe(mdio_oe), .mdc(mdc),
        .gpio(gpio),
        .uart0_rxd(uart0_rxd), .uart0_txd(uart0_txd),
        .spi_sclk(spi_sclk), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_cs_n(spi_cs_n),
        .i2c_sda(i2c_sda), .i2c_scl(i2c_scl),
        .ext_irq(ext_irq),
        .ddr_dq(ddr_dq), .ddr_dqs_p(ddr_dqs_p), .ddr_dqs_n(ddr_dqs_n),
        .ddr_addr(ddr_addr), .ddr_ba(ddr_ba),
        .ddr_ras_n(ddr_ras_n), .ddr_cas_n(ddr_cas_n), .ddr_we_n(ddr_we_n),
        .ddr_cs_n(ddr_cs_n), .ddr_cke(ddr_cke), .ddr_odt(ddr_odt),
        .ddr_clk_p(ddr_clk_p), .ddr_clk_n(ddr_clk_n),
        .test_mode(test_mode), .scan_en(scan_en), .scan_in(scan_in), .scan_out(scan_out)
    );

    // ---- 25 MHz Reference Clock ----
    initial begin
        refclk_25m = 1'b0;
        forever #(CLK_PERIOD_25M/2.0) refclk_25m = ~refclk_25m;
    end

    // ---- RGMII RX Clock (125 MHz) ----
    initial begin
        rgmii_rxc = 1'b0;
        forever #4.0 rgmii_rxc = ~rgmii_rxc;
    end

    // ---- JTAG Clock (25 MHz) ----
    initial begin
        tck = 1'b0;
        forever #(CLK_PERIOD_25M*2) tck = ~tck;
    end

    // ---- JTAG TAP Task ----
    task jtag_tms_seq;
        input integer len;
        input [31:0] tms_seq;
        integer i;
        begin
            for (i = 0; i < len; i = i + 1) begin
                tms = tms_seq[i];
                @(posedge tck); #1;
            end
        end
    endtask

    task jtag_shift_dr;
        input integer nbits;
        input [63:0] data_in;
        output [63:0] data_out;
        integer i;
        begin
            // Go to Shift-DR
            tms = 1'b1; @(posedge tck); #1;  // Run-Test-Idle -> Select-DR
            tms = 1'b0; @(posedge tck); #1;  // Capture-DR
            tms = 1'b0; @(posedge tck); #1;  // Shift-DR
            for (i = 0; i < nbits - 1; i = i + 1) begin
                tdi = data_in[i];
                @(posedge tck);
                data_out[i] = tdo;
                #1;
            end
            tdi = data_in[nbits-1];
            tms = 1'b1; @(posedge tck);
            data_out[nbits-1] = tdo; #1;
            // Exit1-DR -> Update-DR -> RTI
            tms = 1'b1; @(posedge tck); #1;
            tms = 1'b0; @(posedge tck); #1;
        end
    endtask

    // ---- UART TX Model ----
    task uart_send_byte;
        input [7:0] data;
        integer i;
        localparam BIT_PERIOD = 8680; // ~115200 baud at 1ns timescale
        begin
            uart0_rxd = 1'b0; // start bit
            #BIT_PERIOD;
            for (i = 0; i < 8; i = i + 1) begin
                uart0_rxd = data[i];
                #BIT_PERIOD;
            end
            uart0_rxd = 1'b1; // stop bit
            #BIT_PERIOD;
        end
    endtask

    task uart_send_string;
        input [127:0] str;
        input integer len;
        integer i;
        begin
            for (i = 0; i < len; i = i + 1)
                uart_send_byte(str[i*8 +: 8]);
        end
    endtask

    // ---- Ethernet Frame Generator ----
    task eth_send_frame;
        input [47:0] dst_mac, src_mac;
        input [15:0] eth_type;
        input [7:0]  payload[0:63];
        input integer plen;
        integer i;
        begin
            // Preamble + SFD
            repeat(7) begin
                rgmii_rxd = 4'h5; rgmii_rx_ctl = 1'b1;
                @(posedge rgmii_rxc);
            end
            rgmii_rxd = 4'hD; @(posedge rgmii_rxc); // SFD

            // Header bytes (split into nibbles for RGMII)
            for (i = 0; i < 6; i = i + 1) begin
                rgmii_rxd = dst_mac[47-i*8 +: 4]; @(posedge rgmii_rxc);
                rgmii_rxd = dst_mac[43-i*8 +: 4]; @(posedge rgmii_rxc);
            end
            for (i = 0; i < 6; i = i + 1) begin
                rgmii_rxd = src_mac[47-i*8 +: 4]; @(posedge rgmii_rxc);
                rgmii_rxd = src_mac[43-i*8 +: 4]; @(posedge rgmii_rxc);
            end
            rgmii_rxd = eth_type[15:12]; @(posedge rgmii_rxc);
            rgmii_rxd = eth_type[11:8];  @(posedge rgmii_rxc);
            rgmii_rxd = eth_type[ 7:4];  @(posedge rgmii_rxc);
            rgmii_rxd = eth_type[ 3:0];  @(posedge rgmii_rxc);

            // Payload
            for (i = 0; i < plen; i = i + 1) begin
                rgmii_rxd = payload[i][7:4]; @(posedge rgmii_rxc);
                rgmii_rxd = payload[i][3:0]; @(posedge rgmii_rxc);
            end

            // End of frame
            rgmii_rx_ctl = 1'b0;
            @(posedge rgmii_rxc);
        end
    endtask

    // ---- SPI Transaction ----
    task spi_transaction;
        input [7:0] tx_byte;
        output [7:0] rx_byte;
        integer i;
        begin
            // Wait for CS assert (from DUT)
            @(negedge spi_cs_n[0]);
            for (i = 7; i >= 0; i = i - 1) begin
                spi_miso = $random;
                @(posedge spi_sclk);
                rx_byte[i] = spi_mosi;
                @(negedge spi_sclk);
            end
            @(posedge spi_cs_n[0]);
        end
    endtask

    // ---- Main Test Sequence ----
    integer test_phase;
    integer fail_cnt;

    initial begin
        // Initialize signals
        ext_rst_n   = 1'b0;
        trst_n      = 1'b0;
        tms         = 1'b1;
        tdi         = 1'b0;
        uart0_rxd   = 1'b1;  // idle
        rgmii_rxd   = 4'h0;
        rgmii_rx_ctl= 1'b0;
        spi_miso    = 1'b0;
        gpio_drv    = 32'h0;
        gpio_oe_drv = 32'h0;
        ext_irq     = 32'h0;
        test_mode   = 1'b0;
        scan_en     = 1'b0;
        scan_in     = 1'b0;
        usb_dp_drive= 1'b0;
        usb_dn_drive= 1'b0;
        fail_cnt    = 0;
        test_phase  = 0;

        $dumpfile("tb_soc_top.vcd");
        $dumpvars(0, tb_soc_top);

        // ===================================================
        // Phase 1: Power-On Reset
        // ===================================================
        $display("--- Phase 1: Power-On Reset ---");
        test_phase = 1;
        repeat(200) @(posedge refclk_25m);
        ext_rst_n = 1'b1;
        repeat(10) @(posedge refclk_25m);

        // ===================================================
        // Phase 2: JTAG Reset and IDCODE read
        // ===================================================
        $display("--- Phase 2: JTAG TAP Reset ---");
        test_phase = 2;
        trst_n = 1'b1;
        tms = 1'b1;
        repeat(6) @(posedge tck); // -> Test Logic Reset
        tms = 1'b0;
        @(posedge tck); // -> Run-Test-Idle
        #1;

        // Shift IR = IDCODE (4'h1)
        tms = 1; @(posedge tck); // -> Select-DR
        tms = 1; @(posedge tck); // -> Select-IR
        tms = 0; @(posedge tck); // -> Capture-IR
        tms = 0; @(posedge tck); // -> Shift-IR
        tdi = 1; tms = 0; @(posedge tck);
        tdi = 0; tms = 0; @(posedge tck);
        tdi = 0; tms = 0; @(posedge tck);
        tdi = 0; tms = 1; @(posedge tck); // -> Exit1-IR
        tms = 1; @(posedge tck); // -> Update-IR
        tms = 0; @(posedge tck); // -> RTI

        // Read IDCODE DR (32 bits)
        begin
            reg [31:0] idcode;
            reg [63:0] dummy;
            jtag_shift_dr(32, 64'h0, dummy);
            idcode = dummy[31:0];
            $display("JTAG IDCODE = 0x%08X", idcode);
            if (idcode[0] != 1'b1) begin
                $display("ERROR: IDCODE bit 0 should be 1");
                fail_cnt = fail_cnt + 1;
            end
        end

        // ===================================================
        // Phase 3: Wait for PLL lock and SoC ready
        // ===================================================
        $display("--- Phase 3: Wait PLL Lock + SoC Ready ---");
        test_phase = 3;
        wait (u_dut.pll_locked === 1'b1);
        $display("PLL locked at time %0t", $time);
        wait (u_dut.soc_ready === 1'b1);
        $display("SoC ready at time %0t", $time);

        // ===================================================
        // Phase 4: UART Loopback Test (send ASCII "HELLO")
        // ===================================================
        $display("--- Phase 4: UART TX Test ---");
        test_phase = 4;
        repeat(100) @(posedge refclk_25m);
        uart_send_byte(8'h48); // 'H'
        uart_send_byte(8'h45); // 'E'
        uart_send_byte(8'h4C); // 'L'
        uart_send_byte(8'h4C); // 'L'
        uart_send_byte(8'h4F); // 'O'
        uart_send_byte(8'h0D); // CR
        uart_send_byte(8'h0A); // LF
        $display("UART: Sent 'HELLO\r\n'");

        // ===================================================
        // Phase 5: GPIO Toggle Test
        // ===================================================
        $display("--- Phase 5: GPIO Test ---");
        test_phase = 5;
        gpio_oe_drv = 32'hFF;
        gpio_drv    = 32'h55;
        repeat(20) @(posedge refclk_25m);
        gpio_drv    = 32'hAA;
        repeat(20) @(posedge refclk_25m);
        gpio_drv    = 32'h0;
        gpio_oe_drv = 32'h0;
        $display("GPIO: Toggled pattern 0x55 / 0xAA");

        // ===================================================
        // Phase 6: External Interrupt Test
        // ===================================================
        $display("--- Phase 6: External IRQ ---");
        test_phase = 6;
        repeat(50) @(posedge refclk_25m);
        ext_irq = 32'h1; // Assert IRQ 0
        repeat(10) @(posedge refclk_25m);
        ext_irq = 32'h0; // Deassert
        $display("IRQ: External interrupt toggled");

        // ===================================================
        // Phase 7: Ethernet Frame RX
        // ===================================================
        $display("--- Phase 7: Ethernet RX Frame ---");
        test_phase = 7;
        begin
            reg [7:0] pld[0:63];
            integer i;
            for (i = 0; i < 64; i = i + 1) pld[i] = i;
            eth_send_frame(
                48'hFF_FF_FF_FF_FF_FF,  // dst: broadcast
                48'h00_11_22_33_44_55,  // src MAC
                16'h0800,               // IPv4
                pld, 64
            );
        end
        $display("Ethernet: Frame injected");

        // ===================================================
        // Phase 8: SoC-level reset and re-boot
        // ===================================================
        $display("--- Phase 8: System Reset ---");
        test_phase = 8;
        repeat(50) @(posedge refclk_25m);
        ext_rst_n = 1'b0;
        repeat(20) @(posedge refclk_25m);
        ext_rst_n = 1'b1;
        repeat(200) @(posedge refclk_25m);
        wait (u_dut.pll_locked === 1'b1);
        $display("SoC: Re-boot complete after reset");

        // ===================================================
        // Test Complete
        // ===================================================
        repeat(100) @(posedge refclk_25m);
        if (fail_cnt == 0)
            $display("PASS: All %0d test phases completed successfully", test_phase);
        else
            $display("FAIL: %0d errors detected", fail_cnt);

        $finish;
    end

    // ---- Timeout Watchdog ----
    initial begin
        #10_000_000; // 10ms timeout
        $display("TIMEOUT: Simulation exceeded 10ms, killing");
        $finish;
    end

    // ---- Monitor: SoC signals of interest ----
    always @(posedge u_dut.clk_core_0) begin
        if (u_dut.c0_icache_req_valid)
            $display("  [%0t] C0 Icache req PA=0x%014X", $time, u_dut.c0_icache_req_paddr);
        if (u_dut.c0_dcache_req_valid && u_dut.c0_dcache_req_wr)
            $display("  [%0t] C0 Dcache WRITE PA=0x%014X D=0x%016X", $time, u_dut.c0_dcache_req_paddr, u_dut.c0_dcache_req_wdata);
    end

    // ---- Clock domain monitors ----
    always @(posedge u_dut.clk_eth) begin
        if (u_dut.u_eth.u_mac.irq)
            $display("  [%0t] ETH: Frame received!", $time);
    end

    always @(posedge u_dut.clk_periph) begin
        if (u_dut.u_uart0.irq)
            $display("  [%0t] UART: IRQ asserted", $time);
    end

endmodule
