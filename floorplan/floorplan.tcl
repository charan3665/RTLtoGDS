
# ============================================================
# floorplan.tcl - ICC2 Full Floorplan Setup
# Die: 7mm x 7mm (49mm2), Core: 6.5mm x 6.5mm
# Technology: SAED32 28nm, Metal stack: 9M (M1-M9)
# ============================================================

set proj /u/saicha/industry_chip_rtl2gds

# ---- Die and Core Area ----
initialize_floorplan \
    -die_area  {0 0 7000 7000} \
    -core_area {250 250 6750 6750} \
    -site      {core} \
    -core_utilization 0.70 \
    -core_offset 250

# ---- IO Ring Setup ----
# Pad placement: 40 pads per side
source $proj/floorplan/pin_placement.tcl

# ---- Macro Placement ----
source $proj/floorplan/macro_placement.tcl
source $proj/floorplan/sram_placement.tcl

# ---- Power Grid ----
source $proj/floorplan/power_grid.tcl

# ---- Blockages ----
source $proj/floorplan/keepout.tcl

# ---- Verify ----
check_floorplan
report_floorplan_phys_utilization -file $proj/reports/floorplan_util.rpt

puts "Floorplan complete: die=7000x7000, core=6500x6500, util=70%"
