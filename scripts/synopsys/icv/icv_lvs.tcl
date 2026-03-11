
# ============================================================
# icv_lvs.tcl - IC Validator LVS Run
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

icv -gds $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -netlist $proj/output/soc_top_final.v \
    -runset $proj/tech/saed32nm_lvs.rs \
    -lvs \
    -output_directory $proj/reports/icv_lvs \
    -jobs 32

set lvs_ok [icv_result -lvs_clean -run_dir $proj/work/icv_lvs]
puts "LVS: [expr {$lvs_ok ? {CLEAN} : {FAILED}}]"
