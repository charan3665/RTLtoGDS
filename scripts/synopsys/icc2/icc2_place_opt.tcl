
# ============================================================
# icc2_place_opt.tcl - Placement and Physical Optimization
# Power-aware, congestion-driven, timing-driven
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@floorplan_done

# ---- Placement Settings ----
set_placement_options \
    -congestion_effort  high \
    -timing_effort      high \
    -power_effort       high \
    -legalize_at_end    true

# ---- Clock Uncertainty pre-CTS ----
set_clock_uncertainty 0.300 [all_clocks]

# ---- Pre-placement checks ----
check_design -checks pre_placement_feasibility

# ---- Place Decap Cells (before placement) ----
place_well_taps \
    -cell TAPCELL_SAED32NM \
    -distance 50 \
    -offset 25

place_end_caps \
    -pre_end_cap  ENDC_SAED32NM \
    -post_end_cap ENDC_SAED32NM

# ---- Global Placement ----
place_opt \
    -flow           soc \
    -effort         high \
    -power          true \
    -concurrent_opt true

# ---- Legalization ----
legalize_placement

# ---- Post-placement Timing ----
current_scenario [get_scenarios func_ss_0p75v_125c]
report_timing -scenarios [all_scenarios] -max_paths 50 \
    -file $proj/reports/place_timing.rpt

# ---- Congestion Report ----
report_congestion -file $proj/reports/place_congestion.rpt

save_block -label place_opt_done
puts "Placement optimization complete"
