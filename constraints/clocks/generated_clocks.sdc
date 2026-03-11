
# ============================================================
# generated_clocks.sdc - All Generated Clocks
# ============================================================

# PLL output clocks derived from refclk_25m
# VCO = 25MHz * FBDIV = 1000 MHz (nominal)

create_generated_clock -name clk_core_0 \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 1 -add \
    [get_pins u_clkgen/icg_core0/Q]

create_generated_clock -name clk_core_1 \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 1 -add \
    [get_pins u_clkgen/icg_core1/Q]

create_generated_clock -name clk_l2 \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 2 \
    [get_pins u_clkgen/icg_l2/Q]

create_generated_clock -name clk_l3 \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 4 \
    [get_pins u_clkgen/icg_l3/Q]

create_generated_clock -name clk_noc \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 2 \
    [get_pins u_clkgen/icg_noc/Q]

create_generated_clock -name clk_gpu \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 2 -add \
    [get_pins u_clkgen/icg_gpu/Q]

create_generated_clock -name clk_pcie \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 4 \
    [get_pins u_clkgen/icg_pcie/Q]

create_generated_clock -name clk_usb \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 16 \
    [get_pins u_clkgen/icg_usb/Q]

create_generated_clock -name clk_eth \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 8 \
    [get_pins u_clkgen/icg_eth/Q]

create_generated_clock -name clk_dma \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 4 \
    [get_pins u_clkgen/icg_dma/Q]

create_generated_clock -name clk_crypto \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 2 \
    [get_pins u_clkgen/icg_crypto/Q]

create_generated_clock -name clk_io \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 10 \
    [get_pins u_clkgen/icg_io/Q]

create_generated_clock -name clk_mem \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 5 \
    [get_pins u_clkgen/icg_mem/Q]

create_generated_clock -name clk_periph \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 20 \
    [get_pins u_clkgen/icg_periph/Q]

create_generated_clock -name clk_debug \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 40 \
    [get_pins u_clkgen/icg_debug/Q]

# DFS-generated alternate clocks (when DFS changes PLL)
create_generated_clock -name clk_core_dfs_l1 \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -divide_by 2 -add \
    [get_pins u_clkgen/icg_core0/Q]

create_generated_clock -name clk_core_dfs_l4 \
    -source [get_pins u_clkgen/u_main_pll/u_pll_core/clk_out] \
    -multiply_by 1 -add \
    [get_pins u_clkgen/icg_core0/Q]
