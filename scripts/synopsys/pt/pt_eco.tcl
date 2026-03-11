
# ============================================================
# pt_eco.tcl - PrimeTime ECO (Engineering Change Order)
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_mcmm.tcl

# ---- Compute ECO changes ----
fix_eco_timing \
    -setup \
    -hold \
    -methods {add_buffer size_cell swap_cell move_cell} \
    -effort high \
    -max_paths 50 \
    -slack_improvement_threshold 0.010

# ---- Write ECO changes (for ICC2 implementation) ----
write_changes \
    -output $proj/scripts/synopsys/pt/pt_eco.tcl.changes \
    -format icc2

# ---- Post-ECO timing report ----
update_timing
report_timing -max_paths 50 -slack_lesser_than 0.050 \
    -file $proj/reports/eco_post_timing.rpt

puts "ECO changes written to pt_eco.tcl.changes"
