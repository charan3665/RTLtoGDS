
# ============================================================
# innovus_init.tcl - Design Import & Initialization
# Reads netlist, LEF, UPF, MMMC, and initializes floorplan
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Source Environment ----
source $proj/scripts/cadence/innovus/innovus_setup.tcl

# ============================================================
# Design Import
# ============================================================

# Read physical libraries (LEF)
read_physical -lef [list $tech_lef {*}$cell_lefs]

# Read netlist (post-synthesis from Genus)
read_netlist $proj/work/cadence/${TOP}_syn.v -top $TOP

# Read power intent (UPF)
read_power_intent -1801 $proj/upf/soc_top.upf

# Initialize design with MMMC
init_design

# Commit power intent
commit_power_intent

# ============================================================
# Floorplan Initialization
# ============================================================

# Die/Core area: 7mm x 7mm die, IO ring ~200um
set die_llx 0.0
set die_lly 0.0
set die_urx 7000.0
set die_ury 7000.0

set core_llx 200.0
set core_lly 200.0
set core_urx 6800.0
set core_ury 6800.0

create_floorplan \
    -die_area  [list $die_llx $die_lly $die_urx $die_ury] \
    -core_area [list $core_llx $core_lly $core_urx $core_ury] \
    -core_utilization 0.65 \
    -core_margins_by {die} \
    -flip_first_row true \
    -left_io2core 200.0 \
    -right_io2core 200.0 \
    -top_io2core 200.0 \
    -bottom_io2core 200.0

# ---- Row Creation ----
create_row -site core28 -flip_first_row true

# ---- Tracks ----
add_tracks -honor_pitch

# ============================================================
# IO Pad Placement
# ============================================================
source $proj/floorplan/pin_placement.tcl

# ============================================================
# Voltage Area Definition (per UPF power domains)
# ============================================================

# CPU0 voltage area (upper-left quadrant)
create_voltage_area -name VA_CPU0 \
    -power_domain PD_CPU0 \
    -guard_band_x 10.0 \
    -guard_band_y 10.0 \
    -coordinate [list 220 4500 3300 6780]

# CPU1 voltage area (upper-right quadrant)
create_voltage_area -name VA_CPU1 \
    -power_domain PD_CPU1 \
    -guard_band_x 10.0 \
    -guard_band_y 10.0 \
    -coordinate [list 3500 4500 6780 6780]

# GPU voltage area (middle-right)
create_voltage_area -name VA_GPU \
    -power_domain PD_GPU \
    -guard_band_x 10.0 \
    -guard_band_y 10.0 \
    -coordinate [list 3500 1500 6780 4300]

# Memory subsystem (middle-left)
create_voltage_area -name VA_MEM \
    -power_domain PD_MEM \
    -guard_band_x 10.0 \
    -guard_band_y 10.0 \
    -coordinate [list 220 2500 3300 4300]

# Crypto (lower-left corner)
create_voltage_area -name VA_CRYPTO \
    -power_domain PD_CRYPTO \
    -guard_band_x 5.0 \
    -guard_band_y 5.0 \
    -coordinate [list 220 220 1500 1200]

# PCIe (lower-right corner)
create_voltage_area -name VA_PCIE \
    -power_domain PD_PCIE \
    -guard_band_x 5.0 \
    -guard_band_y 5.0 \
    -coordinate [list 5500 220 6780 1200]

# ============================================================
# Macro Placement
# ============================================================
source $proj/floorplan/macro_placement.tcl

# SRAM macro placement with halos
source $proj/floorplan/sram_placement.tcl

# ---- Macro Halos ----
set macro_list [get_cells -hierarchical -filter "is_macro==true"]
add_halo_to_macro -macro $macro_list \
    -left 5.0 -right 5.0 -top 5.0 -bottom 5.0

# ============================================================
# Blockages
# ============================================================
source $proj/floorplan/keepout.tcl

# Placement blockage around macros
create_place_blockage -type hard \
    -name blk_macro_channel \
    -area [list 3300 4300 3500 6780]

# Routing blockage for sensitive analog area
create_route_blockage \
    -layer {M1 M2} \
    -area [list 220 220 600 600] \
    -name blk_analog_route

# ============================================================
# Power Planning
# ============================================================
source $proj/scripts/cadence/innovus/innovus_power_grid.tcl

# ============================================================
# Check & Save
# ============================================================
check_floorplan
check_power_domain -all

# Save design
save_design $proj/work/cadence/${TOP}_init.inn
write_db $proj/work/cadence/${TOP}_init.db

puts "============================================"
puts " Design Initialization Complete"
puts " Die area: ${die_urx}um x ${die_ury}um"
puts " Core utilization: 65%"
puts " Voltage areas: 6 defined"
puts "============================================"
