
# ============================================================
# icc2_signoff.tcl - Final Signoff and GDSII Export
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@chip_finish_done

# ---- Final Timing Signoff (with StarRC parasitics) ----
update_timing -full

# ---- Final QoR Report ----
report_qor -file $proj/reports/signoff_qor.rpt
report_timing -scenarios [all_scenarios] -max_paths 200 \
    -path_type full_clock_expanded \
    -file $proj/reports/signoff_timing.rpt
report_power -scenarios [all_scenarios] \
    -file $proj/reports/signoff_power.rpt
report_area -file $proj/reports/signoff_area.rpt

# ---- Final DRC/LVS (internal) ----
verify_drc -output $proj/reports/final_drc.rpt
verify_lvs

# ---- GDSII Export ----
write_gds \
    -compress true \
    -long_names true \
    -output $proj/output/soc_top.gds.gz \
    -format gdsii \
    -units 0.001

# ---- DEF Export ----
write_def \
    -output $proj/output/soc_top.def.gz \
    -compress

# ---- Verilog Netlist (for LVS/simulation) ----
write_verilog \
    -output $proj/output/soc_top_final.v \
    -supply_statement use_pgpin \
    -include_pg_ports true

# ---- SDF (for gate-level simulation) ----
write_sdf \
    -corner func_tt_0p85v_25c \
    -output $proj/output/soc_top.sdf

# ---- SPEF (for external SI analysis) ----
write_parasitics \
    -format spef \
    -output $proj/output/soc_top \
    -compress

puts "Signoff complete. GDS at $proj/output/soc_top.gds.gz"
