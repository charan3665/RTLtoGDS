
# ============================================================
# icc2_route_opt.tcl - Post-Route Optimization
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@route_done

# ---- Post-route Setup/Hold Fix ----
set_app_options -name opt.flow.enable_ccd -value true
set_app_options -name opt.hold.effort -value high
set_app_options -name opt.setup.effort -value high

route_opt \
    -effort high \
    -power true \
    -timing true \
    -hold true \
    -ccd true

# ---- ECO Routing ----
route_eco -reroute modified_nets

# ---- SI (crosstalk) Fixing ----
set_si_options \
    -delta_delay true \
    -noise_threshold 0.05 \
    -glitch_threshold 0.10 \
    -delay_analysis_mode pessimistic
si_opt

# ---- Final DRC ----
check_routes
verify_drc

# ---- Timing Report (all scenarios) ----
foreach scen [get_object_name [get_scenarios]] {
    current_scenario $scen
    report_timing -max_paths 20 -path_type full \
        -file $proj/reports/post_route_${scen}.rpt
}

report_qor -file $proj/reports/post_route_qor.rpt
report_power -file $proj/reports/post_route_power.rpt

save_block -label route_opt_done
