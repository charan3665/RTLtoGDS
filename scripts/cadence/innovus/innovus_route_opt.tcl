
# ============================================================
# innovus_route_opt.tcl - Post-Route Optimization
# SI fix, hold fix, leakage recovery, multi-corner closure
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_routed.db

# ============================================================
# Post-Route Extraction (in-design)
# ============================================================
set_db extract_rc_engine post_route
set_db extract_rc_effort_level medium

extract_rc

# ============================================================
# SI-Aware Post-Route Optimization
# ============================================================

# Enable SI analysis during optimization
set_db opt_post_route_area_reclaim none
set_db opt_si_aware true
set_db opt_si_restorer true

# ---- Setup Fix (across all setup views) ----
opt_design -post_route \
    -setup \
    -report_dir $proj/reports/innovus_post_route_setup/ \
    -report_prefix post_route_setup

# ---- Hold Fix (across all hold views) ----
set_db opt_fix_hold true
set_db opt_hold_target_slack 0.020
set_db opt_hold_allow_setup_tns_degradation false

opt_design -post_route \
    -hold \
    -report_dir $proj/reports/innovus_post_route_hold/ \
    -report_prefix post_route_hold

# ============================================================
# SI Crosstalk Fix
# ============================================================

# Aggressive SI repair
set_db delaycal_enable_si true
set_db si_analysis_type aae
set_db si_delay_separate_on_data true
set_db si_delay_delta_annotation_mode arc_based

opt_design -post_route -si \
    -report_dir $proj/reports/innovus_post_route_si/ \
    -report_prefix post_route_si

# ============================================================
# Leakage Power Recovery (Multi-Vt Swap)
# ============================================================

# Swap to HVT where slack permits
set_db opt_multi_vt_effort high
set_db opt_leakage_power_effort high

opt_design -post_route \
    -power \
    -report_dir $proj/reports/innovus_post_route_power/ \
    -report_prefix post_route_power

# ============================================================
# Incremental DRC Clean after Optimization
# ============================================================
route_eco -fix_drc

verify_drc -limit 10000 \
    -report $proj/reports/innovus_post_opt_drc.rpt

verify_connectivity -type regular -error 10000 \
    -report $proj/reports/innovus_post_opt_conn.rpt

# ============================================================
# Timing & Power Reports
# ============================================================

# Setup timing (all setup views)
foreach view [get_db [get_db analysis_views -if {.is_setup == true}] .name] {
    report_timing -max_paths 100 -nworst 5 -view $view \
        > $proj/reports/innovus_timing_setup_${view}.rpt
}

# Hold timing (all hold views)
foreach view [get_db [get_db analysis_views -if {.is_hold == true}] .name] {
    report_timing -max_paths 100 -nworst 5 -early -view $view \
        > $proj/reports/innovus_timing_hold_${view}.rpt
}

# QoR summary
report_qor > $proj/reports/innovus_post_route_opt_qor.rpt

# Power report
report_power -view av_func_tt_25c \
    > $proj/reports/innovus_post_route_opt_power.rpt

report_power -view av_func_tt_25c -leakage \
    > $proj/reports/innovus_post_route_opt_leakage.rpt

# Noise report (SI)
report_noise -above_noise_margin \
    > $proj/reports/innovus_post_route_noise.rpt

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_route_opt.inn
write_db $proj/work/cadence/${TOP}_route_opt.db

puts "============================================"
puts " Post-Route Optimization Complete"
puts " SI fix: done"
puts " Hold fix: done"
puts " Multi-Vt leakage recovery: done"
puts "============================================"
