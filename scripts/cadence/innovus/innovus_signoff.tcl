
# ============================================================
# innovus_signoff.tcl - Signoff Export (GDS, Netlist, SPEF, DEF)
# Final verification before tapeout
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_chip_finish.db

# ============================================================
# Final Extraction (Signoff Quality)
# ============================================================
set_db extract_rc_engine post_route
set_db extract_rc_effort_level signoff

extract_rc

# ============================================================
# Signoff Timing (In-Design Tempus)
# ============================================================
set_db timing_analysis_type ocv
set_db timing_analysis_cppr both

# Setup timing check
report_timing -max_paths 200 -nworst 10 \
    > $proj/reports/innovus_signoff_setup.rpt

report_timing -max_paths 200 -nworst 10 -early \
    > $proj/reports/innovus_signoff_hold.rpt

# All-corner timing summary
report_analysis_coverage \
    > $proj/reports/innovus_signoff_coverage.rpt

# Timing histogram
report_qor > $proj/reports/innovus_signoff_qor.rpt

# ============================================================
# Power Signoff
# ============================================================
report_power -view av_func_tt_25c -out_file $proj/reports/innovus_signoff_power.rpt

# Per-domain power
foreach domain {PD_CPU0 PD_CPU1 PD_GPU PD_MEM PD_IO PD_PERIPH PD_CRYPTO PD_PCIE PD_USB PD_ETH PD_ALWAYS_ON} {
    report_power -power_domain $domain -view av_func_tt_25c \
        > $proj/reports/innovus_signoff_power_${domain}.rpt
}

# ============================================================
# Gate Count & Area
# ============================================================
report_area > $proj/reports/innovus_signoff_area.rpt
report_utilization > $proj/reports/innovus_signoff_util.rpt

# ============================================================
# Export GDS
# ============================================================
set_db write_stream_merge_level 1
set_db write_stream_map_file $proj/tech/gds_layer_map.txt

write_stream $proj/output/${TOP}.gds \
    -map_file $proj/tech/gds_layer_map.txt \
    -merge_level 1 \
    -lib_name ${TOP}_lib \
    -struct_name $TOP \
    -units 1000

# ============================================================
# Export DEF (for Calibre/Pegasus)
# ============================================================
write_def $proj/output/${TOP}.def \
    -routing \
    -floorplan \
    -net_name_map \
    -scan_chain

# ============================================================
# Export Verilog Netlist (post-route)
# ============================================================
write_netlist $proj/output/${TOP}_postroute.v \
    -phys \
    -exclude_leaf_cell true

# Flat netlist for LVS
write_netlist $proj/output/${TOP}_postroute_flat.v \
    -flat \
    -phys

# SDF (Standard Delay Format)
write_sdf $proj/output/${TOP}_postroute.sdf \
    -version 3.0 \
    -precision 4 \
    -view av_func_ss_125c

# ============================================================
# Export SPEF (all corners)
# ============================================================

# Typical corner
write_parasitics -format spef \
    -output $proj/output/${TOP}_rc_typical.spef.gz \
    -rc_corner rc_typical

# Cmax corner
write_parasitics -format spef \
    -output $proj/output/${TOP}_rc_cmax.spef.gz \
    -rc_corner rc_cmax

# Cmin corner
write_parasitics -format spef \
    -output $proj/output/${TOP}_rc_cmin.spef.gz \
    -rc_corner rc_cmin

# ============================================================
# Export UPF for Signoff
# ============================================================
write_power_intent -1801 $proj/output/${TOP}_postroute.upf

# ============================================================
# Export LEF (abstract for hierarchical integration)
# ============================================================
write_lef_abstract $proj/output/${TOP}.lef \
    -stripe_pins \
    -pg_pin_layers {M8 M9}

# ============================================================
# Final Checks
# ============================================================
verify_drc -limit 0 -report $proj/reports/innovus_signoff_drc_final.rpt
verify_connectivity -type all -error 0 -report $proj/reports/innovus_signoff_conn_final.rpt
verify_process_antenna -report $proj/reports/innovus_signoff_antenna_final.rpt
verify_power_domain -report $proj/reports/innovus_signoff_power_domain.rpt

# ============================================================
# Summary
# ============================================================
set wns [report_timing -max_paths 1 -return_string]
puts "============================================"
puts " SIGNOFF EXPORT COMPLETE"
puts "============================================"
puts " GDS:     $proj/output/${TOP}.gds"
puts " DEF:     $proj/output/${TOP}.def"
puts " Netlist: $proj/output/${TOP}_postroute.v"
puts " SPEF:    3 corners exported (typ/cmax/cmin)"
puts " SDF:     $proj/output/${TOP}_postroute.sdf"
puts " UPF:     $proj/output/${TOP}_postroute.upf"
puts " LEF:     $proj/output/${TOP}.lef"
puts "============================================"
