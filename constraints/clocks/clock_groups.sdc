
# ============================================================
# clock_groups.sdc - Asynchronous Clock Group Declarations
# ============================================================
# All CPU cluster clocks are synchronous (derived from same PLL)
# PCIe ref clock is asynchronous to SoC clocks
# USB 60MHz is asynchronous to SoC clocks
# External RGMII clock is asynchronous

set_clock_groups -asynchronous \
    -group {clk_core_0 clk_core_1 clk_l2 clk_l3 clk_noc \
            clk_gpu clk_dma clk_crypto clk_mem clk_io clk_periph clk_debug} \
    -group {clk_pcie} \
    -group {clk_usb} \
    -group {clk_eth} \
    -group {refclk_25m}

# JTAG clock (tck) is asynchronous to all functional clocks
set_clock_groups -asynchronous -group {tck} \
    -group {clk_core_0 clk_core_1 clk_l2 clk_l3 clk_noc \
            clk_gpu clk_dma clk_crypto clk_mem clk_io clk_periph clk_debug \
            clk_pcie clk_usb clk_eth refclk_25m}

# DFS alternate clocks logically exclusive
set_clock_groups -logically_exclusive \
    -group {clk_core_0} \
    -group {clk_core_dfs_l1} \
    -group {clk_core_dfs_l4}
