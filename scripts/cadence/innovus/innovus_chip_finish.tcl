
# ============================================================
# innovus_chip_finish.tcl - Metal Fill, Via Optimization,
#   Filler Cell Insertion, Tie-off, Final DRC
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Load Design ----
read_db $proj/work/cadence/${TOP}_route_opt.db

# ============================================================
# Filler Cell Insertion
# ============================================================

# Standard cell fillers (largest to smallest for minimal count)
set filler_cells [list \
    FILL64BWP28NM FILL32BWP28NM FILL16BWP28NM FILL8BWP28NM \
    FILL4BWP28NM FILL3BWP28NM FILL2BWP28NM FILL1BWP28NM \
]

add_fillers -base_cells $filler_cells -prefix FILLER

# Well-tap cells (every 30um to prevent latchup)
add_well_taps -cell TAPCELLBWP28NM \
    -cell_interval 30.0 \
    -prefix WELLTAP

# ============================================================
# Tie-Off Cell Insertion
# ============================================================
add_tieoffs -high TIEHBWP28NM -low TIELBWP28NM -prefix TIEOFF \
    -max_fanout 8 -max_distance 50.0

# ============================================================
# Spare Cell Insertion (for ECO)
# ============================================================
add_spare_cells \
    -cell {INVD1BWP28NM NAND2D1BWP28NM NOR2D1BWP28NM DFQD1BWP28NM BUFFD4BWP28NM} \
    -num_per_type 200 \
    -prefix SPARE \
    -distance_to_power_rail 10.0

# ============================================================
# Via Optimization (Post-Route)
# ============================================================

# Replace single-cut vias with multi-cut where possible
edit_route -via_opt true

# Redundant via insertion
add_redundant_vias \
    -bottom_layer M1 \
    -top_layer M8 \
    -via_weight 2 \
    -auto

# Via pillar for PG connections
edit_power_via \
    -top_layer M9 \
    -bottom_layer M5 \
    -via_array true

# ============================================================
# Metal Fill (Timing-Aware)
# ============================================================

# Signoff-quality metal fill
set_db add_fillers_with_drc true

add_metal_fill \
    -layer {M1 M2 M3 M4 M5 M6 M7 M8} \
    -timing_aware sta \
    -slack_threshold 0.100 \
    -min_density 0.20 \
    -max_density 0.80 \
    -prefer_multiple_width true \
    -space_to_signal 0.1 \
    -space_to_gate 0.2

# ============================================================
# Diode Insertion (Antenna Fix)
# ============================================================
set_db route_design_antenna_diode_insertion true
verify_process_antenna -report $proj/reports/innovus_antenna.rpt
fix_antenna -diode_cell ANTENNACELLD1BWP28NM -check_after_fix

# ============================================================
# Geometry Clean
# ============================================================

# Final spread wire
set_db route_design_detail_post_route_spread_wire true
route_eco -fix_drc

# ============================================================
# Final DRC / Connectivity Check
# ============================================================
verify_drc -limit 100000 \
    -report $proj/reports/innovus_final_drc.rpt

verify_connectivity -type all -error 100000 \
    -report $proj/reports/innovus_final_conn.rpt

verify_process_antenna \
    -report $proj/reports/innovus_final_antenna.rpt

# Check well/substrate contacts
verify_endcap

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_chip_finish.inn
write_db $proj/work/cadence/${TOP}_chip_finish.db

puts "============================================"
puts " Chip Finish Complete"
puts " Fillers:        inserted"
puts " Well taps:      30um interval"
puts " Spare cells:    200 per type"
puts " Metal fill:     timing-aware"
puts " Redundant vias: enabled"
puts "============================================"
