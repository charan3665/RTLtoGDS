
# ============================================================
# false_paths.sdc - False Path Exceptions
# ============================================================

# ---- CDC paths (handled by synchronizers) ----
# CPU to NoC domain crossing
set_false_path -from [get_clocks clk_core_0] -to [get_clocks clk_noc]
set_false_path -from [get_clocks clk_core_1] -to [get_clocks clk_noc]
set_false_path -from [get_clocks clk_noc] -to [get_clocks clk_core_0]
set_false_path -from [get_clocks clk_noc] -to [get_clocks clk_core_1]

# PCIe TL to SoC crossing (asynchronous FIFO path)
set_false_path -from [get_clocks clk_pcie] -to [get_clocks clk_noc]
set_false_path -from [get_clocks clk_noc] -to [get_clocks clk_pcie]

# USB to SoC crossing
set_false_path -from [get_clocks clk_usb] -to [get_clocks clk_io]
set_false_path -from [get_clocks clk_io] -to [get_clocks clk_usb]

# Ethernet to SoC crossing
set_false_path -from [get_clocks clk_eth] -to [get_clocks clk_io]
set_false_path -from [get_clocks clk_io] -to [get_clocks clk_eth]

# Debug (JTAG) to functional paths
set_false_path -from [get_clocks tck] -to [get_clocks clk_core_0]
set_false_path -from [get_clocks tck] -to [get_clocks clk_core_1]
set_false_path -from [get_clocks clk_core_0] -to [get_clocks tck]
set_false_path -from [get_clocks clk_core_1] -to [get_clocks tck]

# ---- Reset paths (asynchronous assert, sync deassert) ----
set_false_path -from [get_ports ext_rst_n]
set_false_path -from [get_ports trst_n]

# ---- Scan paths ----
set_false_path -through [get_pins -hierarchical -filter "name =~ *SE"]
set_false_path -through [get_pins -hierarchical -filter "name =~ *scan_en"]

# ---- Tie cells ----
set_false_path -to [get_cells -hierarchical -filter "ref_name =~ TIEHI*"]
set_false_path -to [get_cells -hierarchical -filter "ref_name =~ TIELO*"]

# ---- Configuration ROM (static after boot) ----
set_false_path -from [get_cells u_boot_rom/*] -to [all_registers]

# ---- GPIO pad I/O (multi-cycle at IO boundary) ----
set_false_path -from [get_ports gpio[*]]
set_false_path -to [get_ports gpio[*]]

# ---- PLL lock/status registers ----
set_false_path -from [get_pins u_clkgen/u_main_pll/u_pll_core/locked]
