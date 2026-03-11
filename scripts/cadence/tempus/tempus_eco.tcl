
# ============================================================
# tempus_eco.tcl - Tempus Timing ECO Generation
# Generate setup/hold fixes for Innovus to implement
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

source $proj/scripts/cadence/tempus/tempus_setup.tcl

# ============================================================
# Update Timing
# ============================================================
update_timing -si -full

# ============================================================
# Setup ECO
# ============================================================

# Fix setup violations across all setup views
set_db eco_opt_effort high
set_db eco_opt_allow_resize true
set_db eco_opt_allow_buffer true
set_db eco_opt_allow_vt_swap true

# Generate setup ECO script
eco_opt_design -setup \
    -report_dir $proj/reports/tempus_eco_setup/ \
    -report_prefix eco_setup

# Write ECO changes for Innovus
write_eco_opt_changes \
    -file $proj/eco/tempus_setup_eco.tcl \
    -format innovus

# ============================================================
# Hold ECO
# ============================================================

# Fix hold violations across all hold views
set_db eco_opt_hold_target_slack 0.020
set_db eco_opt_allow_hold_buffer true
set_db eco_opt_hold_buffer_cells {BUFFD1BWP28NM BUFFD2BWP28NM DELLN1BWP28NM DELLN2BWP28NM}

eco_opt_design -hold \
    -report_dir $proj/reports/tempus_eco_hold/ \
    -report_prefix eco_hold

write_eco_opt_changes \
    -file $proj/eco/tempus_hold_eco.tcl \
    -format innovus

# ============================================================
# SI ECO (fix crosstalk-induced violations)
# ============================================================
eco_opt_design -si \
    -report_dir $proj/reports/tempus_eco_si/ \
    -report_prefix eco_si

write_eco_opt_changes \
    -file $proj/eco/tempus_si_eco.tcl \
    -format innovus

# ============================================================
# DRV ECO (max transition, max capacitance)
# ============================================================
eco_opt_design -drv \
    -report_dir $proj/reports/tempus_eco_drv/ \
    -report_prefix eco_drv

write_eco_opt_changes \
    -file $proj/eco/tempus_drv_eco.tcl \
    -format innovus

# ============================================================
# Post-ECO Verification (predict impact)
# ============================================================
report_eco_opt_summary > $proj/reports/tempus_eco_summary.rpt

# Expected WNS after ECO
report_timing -max_paths 10 -nworst 5 \
    > $proj/reports/tempus_post_eco_timing.rpt

report_timing -max_paths 10 -nworst 5 -early \
    > $proj/reports/tempus_post_eco_hold_timing.rpt

puts "============================================"
puts " Tempus ECO Generation Complete"
puts " Setup ECO: $proj/eco/tempus_setup_eco.tcl"
puts " Hold ECO:  $proj/eco/tempus_hold_eco.tcl"
puts " SI ECO:    $proj/eco/tempus_si_eco.tcl"
puts " DRV ECO:   $proj/eco/tempus_drv_eco.tcl"
puts "============================================"
