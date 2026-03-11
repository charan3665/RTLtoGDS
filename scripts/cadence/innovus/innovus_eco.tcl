
# ============================================================
# innovus_eco.tcl - Engineering Change Order (ECO) Flow
# Functional ECO, Timing ECO, Metal-only ECO
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_chip_finish.db

# ============================================================
# A. Timing ECO (fix signoff violations)
# ============================================================

# Read timing ECO from Tempus
# Format: fix_eco_timing -file eco_timing.tcl
if {[file exists $proj/eco/timing_eco.tcl]} {
    source $proj/eco/timing_eco.tcl
    puts "Loaded timing ECO file"
}

# Auto timing ECO: fix remaining setup/hold violations
opt_eco -setup \
    -pre_eco_file $proj/eco/pre_timing_eco.tcl \
    -post_eco_file $proj/eco/post_timing_eco.tcl

opt_eco -hold \
    -hold_target_slack 0.020 \
    -pre_eco_file $proj/eco/pre_hold_eco.tcl \
    -post_eco_file $proj/eco/post_hold_eco.tcl

# ============================================================
# B. Functional ECO (netlist change from updated RTL)
# ============================================================

# Read updated netlist (post-synthesis from Genus)
if {[file exists $proj/work/cadence/${TOP}_syn_eco.v]} {
    eco_design -netlist $proj/work/cadence/${TOP}_syn_eco.v

    # Place ECO cells
    place_eco_cells -prefix ECO_FUNC

    # Route ECO nets
    route_eco

    puts "Functional ECO applied"
}

# ============================================================
# C. Metal-Only ECO (spare cell utilization)
# ============================================================

# Read spare-cell-based ECO script
if {[file exists $proj/eco/metal_only_eco.tcl]} {
    source $proj/eco/metal_only_eco.tcl

    # Only route, no cell movement
    route_eco -fix_drc
    puts "Metal-only ECO applied"
}

# ============================================================
# D. Freeze Silicon ECO (post-tapeout)
# ============================================================

# For post-tapeout fixes using existing spare cells and metal-only changes
if {[file exists $proj/eco/freeze_eco.tcl]} {
    # Lock all base layers
    set_db eco_route_layers {M1 M2 M3 M4 M5 M6 M7 M8}
    set_db eco_allow_cell_move false

    source $proj/eco/freeze_eco.tcl

    # Route using available routing resources only
    route_eco -fix_drc -freeze_placement

    puts "Freeze silicon ECO applied"
}

# ============================================================
# Post-ECO Verification
# ============================================================

# Extract RC
extract_rc

# Timing
report_timing -max_paths 100 -nworst 5 \
    > $proj/reports/innovus_post_eco_setup.rpt

report_timing -max_paths 100 -nworst 5 -early \
    > $proj/reports/innovus_post_eco_hold.rpt

# DRC
verify_drc -limit 10000 \
    -report $proj/reports/innovus_post_eco_drc.rpt

verify_connectivity -type all -error 10000 \
    -report $proj/reports/innovus_post_eco_conn.rpt

# ============================================================
# Export ECO Changes
# ============================================================
write_eco_changes $proj/eco/eco_changes_summary.txt

# Updated GDS
write_stream $proj/output/${TOP}_eco.gds \
    -map_file $proj/tech/gds_layer_map.txt \
    -merge_level 1

# Updated netlist
write_netlist $proj/output/${TOP}_postroute_eco.v -phys

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_eco.inn
write_db $proj/work/cadence/${TOP}_eco.db

puts "============================================"
puts " ECO Flow Complete"
puts "============================================"
