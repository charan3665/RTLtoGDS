
# ============================================================
# tempus_sta.tcl - Multi-Corner Multi-Mode STA Signoff
# Setup, Hold, Recovery, Removal checks across all views
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

source $proj/scripts/cadence/tempus/tempus_setup.tcl

# ============================================================
# Update Timing (all views)
# ============================================================
update_timing -full

# ============================================================
# Setup Analysis (all setup views)
# ============================================================
set setup_views {
    av_func_ss_125c
    av_func_ss_m40c
    av_func_ss_125c_cmax
    av_func_ss_aging
    av_func_tt_85c_cmax
    av_scan_ss_125c
}

foreach view $setup_views {
    report_timing \
        -view $view \
        -max_paths 200 \
        -nworst 10 \
        -path_type full_clock \
        -net \
        > $proj/reports/tempus_setup_${view}.rpt

    report_timing \
        -view $view \
        -max_paths 50 \
        -check_type setup \
        -path_group_only reg2reg \
        > $proj/reports/tempus_setup_r2r_${view}.rpt

    report_constraint -all_violators -view $view \
        > $proj/reports/tempus_setup_viol_${view}.rpt
}

# ============================================================
# Hold Analysis (all hold views)
# ============================================================
set hold_views {
    av_func_ff_m40c
    av_func_ff_0c
    av_func_tt_25c_cmin
    av_func_tt_25c
    av_scan_ff_m40c
}

foreach view $hold_views {
    report_timing \
        -view $view \
        -max_paths 200 \
        -nworst 10 \
        -early \
        -path_type full_clock \
        -net \
        > $proj/reports/tempus_hold_${view}.rpt

    report_constraint -all_violators -early -view $view \
        > $proj/reports/tempus_hold_viol_${view}.rpt
}

# ============================================================
# Recovery / Removal Checks (async reset paths)
# ============================================================
foreach view $setup_views {
    report_timing \
        -view $view \
        -check_type recovery \
        -max_paths 50 \
        > $proj/reports/tempus_recovery_${view}.rpt
}

foreach view $hold_views {
    report_timing \
        -view $view \
        -check_type removal \
        -max_paths 50 \
        > $proj/reports/tempus_removal_${view}.rpt
}

# ============================================================
# Clock Domain Crossing (CDC) Paths
# ============================================================
report_timing \
    -from [get_clocks clk_core_0] \
    -to [get_clocks clk_noc] \
    -max_paths 50 \
    > $proj/reports/tempus_cdc_core0_to_noc.rpt

report_timing \
    -from [get_clocks clk_noc] \
    -to [get_clocks clk_mem] \
    -max_paths 50 \
    > $proj/reports/tempus_cdc_noc_to_mem.rpt

# ============================================================
# Clock Gating Check
# ============================================================
report_timing -check_type clock_gating_setup -max_paths 100 \
    > $proj/reports/tempus_clock_gating_setup.rpt
report_timing -check_type clock_gating_hold -max_paths 100 \
    > $proj/reports/tempus_clock_gating_hold.rpt

# ============================================================
# Bottleneck Analysis
# ============================================================
report_bottleneck -max_paths 500 -cost_type path_count \
    > $proj/reports/tempus_bottleneck.rpt

# ============================================================
# Min Pulse Width Check
# ============================================================
report_min_pulse_width -all_violators \
    > $proj/reports/tempus_min_pulse_width.rpt

# ============================================================
# QoR Summary (all views)
# ============================================================
report_analysis_coverage \
    > $proj/reports/tempus_analysis_coverage.rpt

report_qor > $proj/reports/tempus_qor.rpt

# WNS/TNS summary
foreach view [concat $setup_views $hold_views] {
    set wns_val [report_timing -view $view -max_paths 1 -return_string]
    puts "View: $view  WNS: $wns_val"
}

puts "============================================"
puts " Tempus STA Complete"
puts " Setup views: [llength $setup_views]"
puts " Hold views:  [llength $hold_views]"
puts "============================================"
