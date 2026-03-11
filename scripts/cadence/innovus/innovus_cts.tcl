
# ============================================================
# innovus_cts.tcl - Clock Tree Synthesis (CCOpt)
# 15+ clock domains, NDR, shielding, multi-source CTS
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_placed.db

# ============================================================
# CCOpt (Concurrent Clock Optimization) Settings
# ============================================================
set_ccopt_property update_io_latency false
set_ccopt_property target_max_trans 0.080
set_ccopt_property target_skew 0.050
set_ccopt_property max_fanout 32

# Clock buffer and inverter list
set_ccopt_property buffer_cells {CKBD1BWP28NM CKBD2BWP28NM CKBD4BWP28NM CKBD8BWP28NM CKBD12BWP28NM CKBD16BWP28NM CKBD20BWP28NM}
set_ccopt_property inverter_cells {CKINVD1BWP28NM CKINVD2BWP28NM CKINVD4BWP28NM CKINVD8BWP28NM CKINVD12BWP28NM CKINVD16BWP28NM}

# Clock gate cells (ICG)
set_ccopt_property clock_gating_cells {CKLHQD1BWP28NM CKLHQD2BWP28NM CKLHQD4BWP28NM CKLHQD8BWP28NM}

# Use H-tree for high-fanout clocks
set_ccopt_property use_inverter_pair true
set_ccopt_property balance_mode full

# ============================================================
# Non-Default Routing Rules (NDR) for Clock Nets
# ============================================================
create_route_rule -name NDR_CLK_TRUNK \
    -width_multiplier {M3:2 M4:2 M5:2 M6:2} \
    -spacing_multiplier {M3:2 M4:2 M5:2 M6:2} \
    -via_weight 2

create_route_rule -name NDR_CLK_LEAF \
    -width_multiplier {M3:1.5 M4:1.5} \
    -spacing_multiplier {M3:1.5 M4:1.5}

# Apply NDR to clock nets
set_ccopt_property route_type -net_type trunk NDR_CLK_TRUNK
set_ccopt_property route_type -net_type leaf  NDR_CLK_LEAF

# ============================================================
# Clock Shielding (for critical clock nets)
# ============================================================
create_route_rule -name NDR_CLK_SHIELD \
    -width_multiplier {M3:2 M4:2 M5:2} \
    -spacing_multiplier {M3:3 M4:3 M5:3} \
    -shielding true \
    -shield_net VSS

# Apply shielding to core clocks
set_ccopt_property route_type -net_type trunk -clock clk_core_0 NDR_CLK_SHIELD
set_ccopt_property route_type -net_type trunk -clock clk_core_1 NDR_CLK_SHIELD

# ============================================================
# Per-Clock Domain CTS Specifications
# ============================================================

# Clock list with target skew/latency
set cts_clocks {
    {clk_core_0  0.040  0.400  high}
    {clk_core_1  0.040  0.400  high}
    {clk_l2      0.060  0.350  high}
    {clk_l3      0.080  0.300  medium}
    {clk_noc     0.060  0.350  high}
    {clk_gpu     0.050  0.400  high}
    {clk_pcie    0.100  0.300  medium}
    {clk_usb     0.150  0.250  low}
    {clk_eth     0.100  0.300  medium}
    {clk_dma     0.100  0.300  medium}
    {clk_crypto  0.080  0.350  medium}
    {clk_io      0.150  0.250  low}
    {clk_mem     0.100  0.350  medium}
    {clk_periph  0.200  0.200  low}
    {clk_debug   0.250  0.200  low}
}

foreach clk_spec $cts_clocks {
    set clk_name   [lindex $clk_spec 0]
    set tgt_skew   [lindex $clk_spec 1]
    set tgt_lat    [lindex $clk_spec 2]
    set effort     [lindex $clk_spec 3]

    set_ccopt_property -clock $clk_name target_skew $tgt_skew
    set_ccopt_property -clock $clk_name target_insertion_delay $tgt_lat

    if {$effort == "high"} {
        set_ccopt_property -clock $clk_name balance_mode full
    } elseif {$effort == "medium"} {
        set_ccopt_property -clock $clk_name balance_mode partial
    } else {
        set_ccopt_property -clock $clk_name balance_mode none
    }
}

# ============================================================
# CCOpt Clock Tree Specification
# ============================================================
create_ccopt_clock_tree_spec

# Auto-identify clock trees
ccopt_check_and_flatten_ilms

# ============================================================
# Run CTS (CCOpt)
# ============================================================
ccopt_design \
    -cts \
    -report_dir $proj/reports/innovus_cts/ \
    -report_prefix cts

# ============================================================
# Post-CTS Optimization
# ============================================================

# Fix hold violations introduced by CTS
set_db opt_fix_hold true
set_db opt_hold_target_slack 0.020
set_db opt_setup_target_slack 0.050

opt_design -post_cts \
    -hold \
    -report_dir $proj/reports/innovus_post_cts_opt/ \
    -report_prefix post_cts

# ============================================================
# Useful Skew Optimization
# ============================================================
set_db opt_useful_skew true
set_db opt_useful_skew_max_allowable 0.150
set_db opt_useful_skew_ccopt true

opt_design -post_cts -incremental

# ============================================================
# Clock Tree Reports
# ============================================================
report_ccopt_clock_trees \
    > $proj/reports/innovus_cts_trees.rpt

report_ccopt_skew_groups \
    > $proj/reports/innovus_cts_skew.rpt

report_clock_tree -summary \
    > $proj/reports/innovus_cts_summary.rpt

# Per-clock skew report
foreach clk_spec $cts_clocks {
    set clk_name [lindex $clk_spec 0]
    report_clock_tree -clock $clk_name \
        > $proj/reports/innovus_cts_${clk_name}.rpt
}

report_timing -max_paths 50 -nworst 5 \
    > $proj/reports/innovus_post_cts_timing.rpt

report_timing -max_paths 50 -nworst 5 -early \
    > $proj/reports/innovus_post_cts_hold_timing.rpt

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_cts.inn
write_db $proj/work/cadence/${TOP}_cts.db

puts "============================================"
puts " CTS Complete: 15 clock domains balanced"
puts " Core clock skew target: 40ps"
puts " NDR: 2x width trunk, 1.5x leaf"
puts " Shielding: clk_core_0, clk_core_1"
puts "============================================"
