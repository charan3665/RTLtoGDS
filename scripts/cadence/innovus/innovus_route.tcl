
# ============================================================
# innovus_route.tcl - NanoRoute Detail Routing
# Multi-corner timing-driven, SI-aware, antenna-fix routing
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_cts.db

# ============================================================
# Pre-Route Settings
# ============================================================
set_multi_cpu_usage -local_cpu 32

# ---- NanoRoute Engine Settings ----
set_db route_design_with_timing_driven true
set_db route_design_with_si_driven true
set_db route_design_concurrent_minimize_via_count_effort high
set_db route_design_detail_post_route_spread_wire true
set_db route_design_antenna_diode_insertion true
set_db route_design_with_via_in_pin random
set_db route_design_detail_fix_antenna true
set_db route_design_detail_use_multi_cut_via_effort high

# SI-Driven Routing
set_db route_design_detail_max_delta_delay 0.020
set_db route_design_detail_min_spacing_to_signal_wire true

# ---- Layer Constraints ----
set_db route_design_top_routing_layer M8
set_db route_design_bottom_routing_layer M1

# Reserve M9 for power only
set_route_rule -name M9_power_only -layer M9 -type power_only

# ---- Via Rules ----
set_db route_design_via_auto_snap true
set_db route_design_via_use_multi_cut_via true

# ============================================================
# Antenna Rules
# ============================================================
set_db route_design_antenna_cell_name "ANTENNACELLD1BWP28NM"
set_db route_design_detail_antenna_fix_iterations 5

# ============================================================
# Shielding for Sensitive Nets
# ============================================================

# Shield critical AXI data buses
set_db route_design_detail_shield_net_list [list \
    u_axi_xbar/aw_data_* \
    u_axi_xbar/ar_data_* \
]

# ============================================================
# Trial Route (global route)
# ============================================================
route_design -global_detail

# ============================================================
# Detail Route
# ============================================================
route_design -detail

# ============================================================
# Post-Route DRC Clean
# ============================================================

# Check for DRC violations
set drc_count [verify_drc -limit 10000 -report $proj/reports/innovus_post_route_drc.rpt]
puts "Post-route DRC violations: $drc_count"

# Auto-fix shorts and spacing violations
edit_route -fix_drc true

# Check connectivity
verify_connectivity -type regular -error 10000 \
    -report $proj/reports/innovus_post_route_conn.rpt

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_routed.inn
write_db $proj/work/cadence/${TOP}_routed.db

puts "============================================"
puts " Detail Routing Complete"
puts " SI-driven: enabled"
puts " Antenna fix: enabled"
puts " Multi-cut via: high effort"
puts "============================================"
