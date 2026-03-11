
# ============================================================
# tempus_si.tcl - Signal Integrity Analysis
# Crosstalk delay, noise, glitch propagation
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

source $proj/scripts/cadence/tempus/tempus_setup.tcl

# ============================================================
# SI Analysis Configuration
# ============================================================
set_db si_analysis_type aae
set_db si_delay_separate_on_data true
set_db si_delay_delta_annotation_mode arc_based
set_db si_enable_glitch_propagation true
set_db si_glitch_input_voltage_high_threshold 0.5
set_db si_glitch_input_voltage_low_threshold 0.3

# Aggressor filtering
set_db si_aggressor_alignment timing_aware
set_db si_delay_enable_report true
set_db si_noise_enable_report true

# Coupling cap threshold
set_db si_xtalk_delay_analysis_mode all_sensitive
set_db si_coupling_cap_threshold 0.005

# ============================================================
# Read Coupled SPEF (with coupling capacitance)
# ============================================================
read_parasitics -format spef \
    -rc_corner rc_cmax \
    $proj/output/${TOP}_rc_cmax_coupled.spef.gz

# ============================================================
# Update Timing with SI
# ============================================================
update_timing -si -full

# ============================================================
# Crosstalk Delay Analysis
# ============================================================

# Setup paths affected by crosstalk
report_timing -view av_func_ss_125c \
    -max_paths 200 \
    -nworst 10 \
    -si \
    -path_type full_clock \
    > $proj/reports/tempus_si_delay_setup.rpt

# SI delta delay report (which nets have most SI impact)
report_si_delay_analysis \
    -view av_func_ss_125c \
    -max_paths 200 \
    -above_threshold 0.010 \
    > $proj/reports/tempus_si_delta_delay.rpt

# Hold paths affected by crosstalk (speed-up)
report_timing -view av_func_ff_m40c \
    -max_paths 200 \
    -nworst 10 \
    -si \
    -early \
    > $proj/reports/tempus_si_delay_hold.rpt

report_si_delay_analysis \
    -view av_func_ff_m40c \
    -max_paths 200 \
    -early \
    -above_threshold 0.010 \
    > $proj/reports/tempus_si_delta_delay_hold.rpt

# ============================================================
# Noise Analysis (Glitch)
# ============================================================

# Above-threshold noise violations
report_noise \
    -view av_func_ss_125c \
    -above_noise_margin \
    -max_noise_sources 20 \
    > $proj/reports/tempus_si_noise_above_margin.rpt

# All noise report
report_noise \
    -view av_func_ss_125c \
    -max_paths 500 \
    > $proj/reports/tempus_si_noise_all.rpt

# Worst victim nets
report_noise \
    -view av_func_ss_125c \
    -sort_by noise_peak \
    -max_paths 100 \
    > $proj/reports/tempus_si_noise_worst_victims.rpt

# ============================================================
# Glitch Propagation Analysis
# ============================================================
report_noise \
    -view av_func_ss_125c \
    -propagated_noise \
    -above_noise_margin \
    > $proj/reports/tempus_si_glitch_propagation.rpt

# ============================================================
# Aggressor/Victim Analysis
# ============================================================

# Identify worst aggressor nets
report_si_aggressor \
    -view av_func_ss_125c \
    -max_aggressors 50 \
    -sort_by coupling_cap \
    > $proj/reports/tempus_si_aggressors.rpt

# Victim net analysis
report_si_victim \
    -view av_func_ss_125c \
    -max_victims 50 \
    > $proj/reports/tempus_si_victims.rpt

# ============================================================
# Bumpy Waveform Analysis (for deep submicron accuracy)
# ============================================================
set_db si_delay_analysis_mode merged_coupled_receiver

report_timing -view av_func_ss_125c \
    -max_paths 50 \
    -si \
    -path_type full_clock \
    > $proj/reports/tempus_si_bumpy_waveform.rpt

# ============================================================
# SI Summary
# ============================================================
puts "============================================"
puts " Tempus SI Analysis Complete"
puts " Crosstalk delay analysis: done"
puts " Noise/glitch analysis:   done"
puts " Aggressor/victim:        done"
puts " Glitch propagation:      done"
puts "============================================"
