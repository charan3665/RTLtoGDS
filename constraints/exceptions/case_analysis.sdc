
# ============================================================
# case_analysis.sdc - Case Analysis (constant value overrides)
# ============================================================

# Test mode off during functional analysis
set_case_analysis 0 [get_ports test_mode]
set_case_analysis 0 [get_ports scan_en]
set_case_analysis 0 [get_ports scan_in]

# Clock mux select (use primary PLL clock path)
set_case_analysis 0 [get_pins -hierarchical -filter "name =~ *clock_mux*/sel"]

# DFS: default level (full speed)
set_case_analysis 0 [get_pins u_clkgen/u_dfs/dfs_req]

# PCIe bypass: use internal PLL clock
set_case_analysis 0 [get_pins u_pcie/u_phy/bypass_clk_sel]

# All clock enables on during functional analysis
set_case_analysis 1 [get_pins -hierarchical -filter "name =~ *icg*/EN"]

# Power switches: all on
set_case_analysis 1 [get_pins -hierarchical -filter "name =~ *power_switch*/SW_EN"]
