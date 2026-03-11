
# ============================================================
# innovus_place.tcl - Placement & Placement Optimization
# Power-aware, congestion-driven, MMMC placement
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_init.db

# ============================================================
# Pre-Placement Settings
# ============================================================

# Congestion-driven placement
set_db place_global_cong_effort high
set_db place_global_timing_effort high
set_db place_global_clock_gate_aware true
set_db place_global_uniform_density true

# Power-aware placement (respects UPF domains)
set_db place_global_place_io_pins true
set_db opt_power_effort high

# Multi-threaded
set_multi_cpu_usage -local_cpu 32

# ---- Scan Chain Reorder ----
set_db place_global_reorder_scan true

# ---- Density Screens (avoid hotspots) ----
set_db place_global_max_density 0.70
set_db place_detail_max_density 0.75

# ============================================================
# Placement Constraints
# ============================================================

# Group critical paths together
create_inst_group grp_cpu0_critical \
    -region [list 500 4800 3000 6500] \
    -inst [get_cells u_cpu_cluster/u_core0/u_fetch/*] \
    -inst [get_cells u_cpu_cluster/u_core0/u_rob/*]

create_inst_group grp_cpu1_critical \
    -region [list 3800 4800 6500 6500] \
    -inst [get_cells u_cpu_cluster/u_core1/u_fetch/*]

# Keep clock mux cells near PLL
create_inst_group grp_clock_mux \
    -region [list 3200 3200 3800 3800] \
    -inst [get_cells u_clock_gen/u_mux_*]

# ============================================================
# Pre-Place Optimization
# ============================================================

# Buffer high-fanout nets before placement
set_db opt_pre_place_high_fanout_net_threshold 64
opt_design -pre_place

# ============================================================
# Global Placement
# ============================================================
place_design \
    -concurrent_macros \
    -no_pre_place_opt

# ============================================================
# Incremental Optimization
# ============================================================

# Congestion analysis
report_congestion -hotspot_list > $proj/reports/innovus_congestion_place.rpt

# Fix congestion if needed
set_db place_global_cong_effort high
refine_place -congestion

# ============================================================
# Scan Chain Reorder (post-place)
# ============================================================
place_opt_design -reorder_scan

# ============================================================
# Timing-Driven Placement Optimization
# ============================================================
set_db opt_useful_skew true
set_db opt_useful_skew_max_allowable 0.200

opt_design -pre_cts \
    -report_dir $proj/reports/innovus_pre_cts_opt/ \
    -report_prefix pre_cts

# ============================================================
# Leakage/Power Optimization
# ============================================================

# Multi-Vt optimization: swap cells to HVT where timing allows
set_db opt_multi_vt_effort high
opt_design -pre_cts -power

# ============================================================
# Physical Verification (Pre-CTS)
# ============================================================
check_place
check_drc -limit 1000

# ============================================================
# Reports
# ============================================================
report_timing -max_paths 50 -nworst 5 \
    > $proj/reports/innovus_place_timing.rpt

report_power -view av_func_tt_25c \
    > $proj/reports/innovus_place_power.rpt

report_utilization > $proj/reports/innovus_place_util.rpt

report_qor > $proj/reports/innovus_place_qor.rpt

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_placed.inn
write_db $proj/work/cadence/${TOP}_placed.db

puts "============================================"
puts " Placement & Pre-CTS Optimization Complete"
puts "============================================"
