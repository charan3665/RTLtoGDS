
# ============================================================
# icv_antenna.tcl - Antenna Rule Check
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

icv -gds $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -runset $proj/tech/saed32nm_antenna.rs \
    -antenna \
    -netlist $proj/output/soc_top_final.v \
    -output_directory $proj/reports/icv_antenna \
    -jobs 16

set ant_count [icv_result -error_count -run_dir $proj/work/icv_antenna]
puts "Antenna violations: $ant_count"
