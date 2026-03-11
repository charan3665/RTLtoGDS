
# ============================================================
# pt_sta.tcl - Comprehensive Static Timing Analysis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_mcmm.tcl

# ---- Update Timing ----
update_timing -full

# ---- Setup Timing Report (worst 500 paths) ----
foreach scen [get_object_name [all_scenarios]] {
    current_scenario $scen
    report_timing \
        -max_paths 500 \
        -path_type full_clock_expanded \
        -delay_type max \
        -slack_lesser_than 0.2 \
        -sort_by slack \
        -nosplit \
        -file $proj/reports/timing_setup_${scen}.rpt
}

# ---- Hold Timing Report ----
foreach scen [get_object_name [all_scenarios]] {
    current_scenario $scen
    report_timing \
        -max_paths 200 \
        -delay_type min \
        -slack_lesser_than 0.0 \
        -sort_by slack \
        -file $proj/reports/timing_hold_${scen}.rpt
}

# ---- QoR Summary ----
report_qor -scenarios [all_scenarios] \
    -nosplit \
    -file $proj/reports/sta_qor_summary.rpt

# ---- Constraint Violations ----
report_constraint \
    -all_violators \
    -nosplit \
    -file $proj/reports/sta_constraint_violations.rpt

# ---- Clock Summary ----
report_clock -nosplit -file $proj/reports/sta_clock_summary.rpt

# ---- Net Summary ----
report_net_fanout -max_fanout 100 \
    -file $proj/reports/sta_high_fanout.rpt

puts "STA complete: $(foreach s [all_scenarios] {expr {$s . " "}}) scenarios analyzed"
