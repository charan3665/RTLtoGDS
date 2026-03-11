
# ============================================================
# icc2_cts.tcl - Clock Tree Synthesis (CTS) for 15+ clocks
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@place_opt_done

# ---- CTS Settings ----
set_cts_options \
    -target_skew  0.080 \
    -target_latency 0.500 \
    -balance_points [get_pins -hierarchical */CK] \
    -buffer_list {CKBD1BWP28NM CKBD2BWP28NM CKBD4BWP28NM CKBD8BWP28NM CKBD16BWP28NM} \
    -inverter_list {CKINVD1BWP28NM CKINVD2BWP28NM CKINVD4BWP28NM} \
    -ndr_rule CLK_NDR_RULE

# ---- CTS for all clocks ----
set clock_list {
    clk_core_0 clk_core_1 clk_l2 clk_l3 clk_noc
    clk_gpu clk_pcie clk_usb clk_eth clk_dma
    clk_crypto clk_io clk_mem clk_periph clk_debug
}

foreach clk $clock_list {
    set_cts_options -clock $clk \
        -pre_cts_skew 0.100 \
        -post_cts_skew 0.050
}

# ---- Run CTS ----
clock_opt

# ---- Update Clock Latency (post-CTS) ----
set_propagated_clock [all_clocks]

# ---- Post-CTS Optimization ----
set_clock_uncertainty -setup 0.075 [get_clocks clk_core_0]
set_clock_uncertainty -hold  0.050 [get_clocks clk_core_0]
set_clock_uncertainty -setup 0.075 [get_clocks clk_core_1]
set_clock_uncertainty -hold  0.050 [get_clocks clk_core_1]
set_clock_uncertainty -setup 0.100 [get_clocks clk_l2]
set_clock_uncertainty -hold  0.075 [get_clocks clk_l2]

# ---- Post-CTS Hold Fix ----
optimize_hold

# ---- CTS Reports ----
report_clock_tree -summary -file $proj/reports/cts_summary.rpt
report_clock_skew -scenarios [all_scenarios] -file $proj/reports/cts_skew.rpt
report_clock_qor  -file $proj/reports/cts_qor.rpt

save_block -label cts_done
puts "CTS complete for [llength $clock_list] clocks"
