
# ============================================================
# pt_si.tcl - Signal Integrity Analysis (Crosstalk)
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_mcmm.tcl

# ---- SI Settings ----
set_si_options \
    -delta_delay               true \
    -static_noise              true \
    -route_xtalk_sensitivity   true \
    -timing_window_analysis    true \
    -noise_budget_threshold    0.10 \
    -glitch_budget_threshold   0.15 \
    -aggressor_filter_threshold 0.005 \
    -enable_delay_variation_analysis true \
    -delay_analysis_mode       pessimistic

# ---- Read coupling capacitance from SPEF ----
read_parasitics -format spef -keep_capacitive_coupling \
    $proj/output/soc_top_tt_0p85v_25c_ccouple.spef.gz

# ---- Update Timing with SI ----
update_timing -si -full

# ---- Crosstalk Delay Analysis ----
report_si_delay_analysis \
    -max_paths 200 \
    -slack_lesser_than 0.100 \
    -worst_transition \
    -file $proj/reports/si_delay_analysis.rpt

# ---- Crosstalk Noise Analysis ----
report_si_noise_analysis \
    -nosplit \
    -above_noise_margin \
    -file $proj/reports/si_noise_analysis.rpt

# ---- Crosstalk-affected Timing Report ----
report_timing \
    -crosstalk_delta \
    -max_paths 100 \
    -path_type full \
    -file $proj/reports/si_crosstalk_timing.rpt

puts "SI analysis complete"
