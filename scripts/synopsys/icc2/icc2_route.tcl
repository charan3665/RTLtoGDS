
# ============================================================
# icc2_route.tcl - Detailed Routing with NDR and Shielding
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@cts_done

# ---- Route Settings ----
set_app_options -name route.common.connect_within_effort -value medium
set_app_options -name route.common.post_detail_route_spread_metal -value true
set_app_options -name route.detail.diode_libcell_names {ANTENNA_DIODE_SAED32}

# ---- Antenna Prevention ----
set_app_options -name route.detail.insert_diodes_during_routing -value true
set_app_options -name route.detail.max_antenna_ratio -value 400

# ---- NDR for clock nets ----
set_routing_rule CLK_2X_NDR \
    -default_reference_rule \
    -multiplier_spacing 2 \
    -multiplier_width 2
set_clock_tree_options -routing_rule CLK_2X_NDR

# ---- Route ----
route_auto \
    -max_detail_route_iterations 10 \
    -effort high

# ---- Post-Route Timing ----
route_opt \
    -effort high \
    -power high \
    -timing high

# ---- DRC Check ----
check_routes

# ---- Reports ----
report_timing -scenarios [all_scenarios] -max_paths 100 \
    -file $proj/reports/route_timing.rpt
report_congestion -file $proj/reports/route_congestion.rpt
report_route_status -file $proj/reports/route_status.rpt

save_block -label route_done
puts "Routing complete"
