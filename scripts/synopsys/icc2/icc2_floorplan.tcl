
# ============================================================
# icc2_floorplan.tcl - Detailed Floorplan in ICC2
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@import_done

# ---- Floorplan Initialization ----
initialize_floorplan \
    -die_area  {0 0 7000 7000} \
    -core_area {250 250 6750 6750} \
    -site      {unit} \
    -flip_first_row false

# ---- Macro Placement ----
source $proj/floorplan/macro_placement.tcl
source $proj/floorplan/sram_placement.tcl

# ---- Pin Placement ----
source $proj/floorplan/pin_placement.tcl

# ---- Power Plan ----
source $proj/floorplan/power_grid.tcl

# ---- Keepout Margins ----
source $proj/floorplan/keepout.tcl

# ---- Sanity Check ----
check_floorplan
check_mv_design -verbose

save_block -label floorplan_done
puts "Floorplan saved"
