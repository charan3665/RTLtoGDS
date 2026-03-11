
# ============================================================
# icv_drc.tcl - IC Validator DRC Run
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

icv -gds $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -runset $proj/tech/saed32nm_drc.rs \
    -output_directory $proj/reports/icv_drc \
    -jobs 32 \
    -run_dirs $proj/work/icv_drc

# Check results
set drc_count [icv_result -error_count -run_dir $proj/work/icv_drc]
puts "DRC violations: $drc_count"

if {$drc_count > 0} {
    icv -report \
        -run_dir $proj/work/icv_drc \
        -format {ASCII GDSII} \
        -output $proj/reports/drc_violations.rpt
}
