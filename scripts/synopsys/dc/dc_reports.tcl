
# ============================================================
# dc_reports.tcl - Synthesis Reports
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

report_timing -max_paths 50 -slack_lesser_than 0.0 \
    -file $proj/reports/syn_timing.rpt
report_area -hierarchy -file $proj/reports/syn_area.rpt
report_power -file $proj/reports/syn_power.rpt
report_qor -file $proj/reports/syn_qor.rpt
report_constraint -all_violators -file $proj/reports/syn_violations.rpt
report_compile_options -file $proj/reports/syn_options.rpt
report_reference -hier -file $proj/reports/syn_refs.rpt
