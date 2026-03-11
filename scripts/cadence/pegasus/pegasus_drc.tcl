
# ============================================================
# pegasus_drc.tcl - Cadence Pegasus Physical Verification (DRC)
# Signoff DRC for 28nm process
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

set lib_dir /pkgs/cadence/28nm/SAED28_EDK

# ============================================================
# DRC Rule Deck
# ============================================================
set drc_rule_file ${lib_dir}/pegasus/saed28nm_drc.rul

# ============================================================
# Input Files
# ============================================================
layout_input \
    -gds $proj/output/${TOP}.gds \
    -cell $TOP

# ============================================================
# DRC Configuration
# ============================================================
set_check_options \
    -max_errors_per_check 10000 \
    -max_results_db_size 2G \
    -parallel_cores 32

# Waiver file (known violations from IP blocks)
if {[file exists $proj/signoff/drc_waivers.txt]} {
    set_waiver_options -file $proj/signoff/drc_waivers.txt
}

# ============================================================
# Run DRC
# ============================================================
run_drc \
    -rule_file $drc_rule_file \
    -report $proj/reports/pegasus_drc.rpt \
    -results_db $proj/work/pegasus/${TOP}_drc.db

# ============================================================
# DRC Summary
# ============================================================
report_drc_summary > $proj/reports/pegasus_drc_summary.rpt

# Categorized results
report_drc_results -by_cell > $proj/reports/pegasus_drc_by_cell.rpt
report_drc_results -by_check > $proj/reports/pegasus_drc_by_check.rpt

puts "============================================"
puts " Pegasus DRC Complete"
puts " Results: $proj/reports/pegasus_drc.rpt"
puts "============================================"
