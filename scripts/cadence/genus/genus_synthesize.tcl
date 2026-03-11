
# ============================================================
# genus_synthesize.tcl - Synthesis (Generic + Mapped + Optimized)
# Physical-aware, power-aware, multi-Vt
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Source read design ----
source $proj/scripts/cadence/genus/genus_read_design.tcl

# ============================================================
# Synthesis Strategy
# ============================================================

# Physical-aware synthesis (use LEF for congestion estimation)
set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

# Hierarchical synthesis
set_db auto_ungroup none
set_db boundary_opto true

# DFT-aware
set_db dft_scan_style muxed_scan

# Power optimization
set_db lp_power_optimization_weight 0.5
set_db lp_insert_clock_gating true
set_db lp_clock_gating_min_flops 4
set_db lp_multi_vt_optimization true

# Area optimization
set_db opt_area_recovery true

# ============================================================
# Generic Synthesis
# ============================================================
syn_generic $TOP

report_qor -levels_of_logic > $proj/reports/genus_generic_qor.rpt

# ============================================================
# Technology Mapping
# ============================================================
syn_map $TOP

report_qor > $proj/reports/genus_mapped_qor.rpt
report_gates > $proj/reports/genus_mapped_gates.rpt

# ============================================================
# Optimization (Incremental)
# ============================================================

# Pass 1: timing closure
syn_opt $TOP

# Pass 2: area recovery
syn_opt $TOP -incremental

# Pass 3: power recovery (multi-Vt swap)
set_db lp_multi_vt_optimization true
syn_opt $TOP -incremental

# ============================================================
# Clock Gating Report
# ============================================================
report_clock_gating > $proj/reports/genus_clock_gating.rpt

# ============================================================
# DFT Scan Insertion
# ============================================================
set_db dft_scan_style muxed_scan
set_db dft_prefix DFT_
set_db dft_scan_map_mode tdrc_pass
check_dft_rules > $proj/reports/genus_dft_rules.rpt

# ============================================================
# Reports
# ============================================================
report_timing -max_paths 50 -nworst 5 > $proj/reports/genus_timing.rpt
report_area > $proj/reports/genus_area.rpt
report_power > $proj/reports/genus_power.rpt
report_qor > $proj/reports/genus_final_qor.rpt
report_dp > $proj/reports/genus_datapath.rpt
report_messages -all > $proj/reports/genus_messages.rpt

# Gate count
puts "Gate count: [get_db designs .num_gates]"

# ============================================================
# Export
# ============================================================

# Verilog netlist
write_hdl > $proj/work/cadence/${TOP}_syn.v

# SDC constraints (mapped)
write_sdc > $proj/work/cadence/${TOP}_syn.sdc

# Design database
write_db $proj/work/cadence/${TOP}_syn.db

# SDF
write_sdf > $proj/work/cadence/${TOP}_syn.sdf

puts "============================================"
puts " Genus Synthesis Complete"
puts " Output: $proj/work/cadence/${TOP}_syn.v"
puts "============================================"
