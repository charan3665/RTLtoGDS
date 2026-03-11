
# ============================================================
# run_dynamic_ir.tcl - Dynamic IR Drop (Vectorless)
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

redhawk -dynamic \
    -gds $proj/output/soc_top.gds.gz \
    -spef $proj/output/soc_top_tt_0p85v_25c.spef.gz \
    -netlist $proj/output/soc_top_final.v \
    -switching_activity_file $proj/work/sim/soc_top_func.saif \
    -power_net VDD \
    -frequency 1000 \
    -time_resolution 0.1 \
    -output_directory $proj/reports/dynamic_ir

report_dynamic_ir \
    -peak_drop_threshold 0.100 \
    -output $proj/reports/dynamic_ir/peak_drop.rpt

puts "Dynamic IR Drop complete. Peak drop reported in: $proj/reports/dynamic_ir/"
