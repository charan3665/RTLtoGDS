
# ============================================================
# pt_noise.tcl - Noise/Glitch Analysis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_setup.tcl

# ---- Noise configuration ----
set_si_options \
    -static_noise              true \
    -glitch_budget_threshold   0.15 \
    -noise_budget_threshold    0.10 \
    -victim_aggressor_analysis true \
    -input_noise_margin        0.05

update_timing -si

# ---- Static Noise Analysis: identify victims with insufficient noise margin ----
report_si_noise_analysis \
    -above_noise_margin \
    -below_noise_margin \
    -nosplit \
    -file $proj/reports/noise_static.rpt

# ---- Glitch Analysis ----
report_si_glitch_analysis \
    -nosplit \
    -high_threshold 0.15 \
    -low_threshold  0.10 \
    -file $proj/reports/noise_glitch.rpt

# ---- Victim-Aggressor Report ----
report_si_delay_analysis \
    -victim_aggressor \
    -max_paths 100 \
    -file $proj/reports/noise_victim_aggressor.rpt

# ---- Noise Budget Summary ----
report_noise_budget \
    -file $proj/reports/noise_budget.rpt

puts "Noise analysis complete"
