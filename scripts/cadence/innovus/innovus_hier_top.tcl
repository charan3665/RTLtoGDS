
# ============================================================
# innovus_hier_top.tcl - Hierarchical Top-Level Assembly
# Black-box block integration, top-level routing, feedthrough
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ============================================================
# Hierarchical Strategy
# ============================================================
# Partition blocks:
#   - cpu_cluster  (both cores + L1 caches)
#   - gpu_top      (full GPU subsystem)
#   - l2_cache     (shared L2)
#   - l3_cache     (shared L3)
#   - axi4_crossbar (interconnect)
#   - crypto_top   (crypto subsystem)
#   - pcie_top     (PCIe subsystem)
#
# These are hardened blocks with ILMs (Interface Logic Models)
# ============================================================

# ---- Source Setup ----
source $proj/scripts/cadence/innovus/innovus_setup.tcl

# ============================================================
# Read Block Abstracts (ILMs)
# ============================================================
set hier_blocks {
    cpu_cluster
    gpu_top
    l2_cache
    l3_cache
    axi4_crossbar
    crypto_top
    pcie_top
}

# Read top-level netlist
read_netlist $proj/work/cadence/${TOP}_syn.v -top $TOP

# Read ILMs for each hardened block
foreach blk $hier_blocks {
    read_ilm -cell $blk \
        -directory $proj/work/cadence/blocks/${blk}/${blk}.ilm
    puts "Loaded ILM: $blk"
}

# Read top-level LEF abstracts
foreach blk $hier_blocks {
    read_physical -lef $proj/work/cadence/blocks/${blk}/${blk}.lef
}

# ---- Initialize ----
read_power_intent -1801 $proj/upf/soc_top.upf
init_design
commit_power_intent

# ============================================================
# Top-Level Floorplan
# ============================================================
source $proj/floorplan/floorplan.tcl

# Place hardened blocks
place_design -concurrent_macros

# ---- Manual Block Placement Refinement ----
place_inst u_cpu_cluster    500    4500 R0
place_inst u_gpu            3800   1800 R0
place_inst u_l2_cache       500    2800 R0
place_inst u_l3_cache       2000   1800 R0
place_inst u_axi_xbar       2200   3400 R0
place_inst u_crypto         300    300  R0
place_inst u_pcie           5600   300  R0

# ============================================================
# Feedthrough Insertion
# ============================================================

# Add feedthrough buffers for signals crossing blocks
set_db add_feedthroughs_buffer_cell BUFFD4BWP28NM
add_feedthroughs \
    -from_pin [get_pins u_cpu_cluster/*] \
    -to_pin [get_pins u_l2_cache/*] \
    -prefix FT_CPU_L2

add_feedthroughs \
    -from_pin [get_pins u_gpu/*] \
    -to_pin [get_pins u_axi_xbar/*] \
    -prefix FT_GPU_XBAR

# ============================================================
# Top-Level Power Grid
# ============================================================
source $proj/scripts/cadence/innovus/innovus_power_grid.tcl

# ============================================================
# Top-Level Placement (soft macros, glue logic)
# ============================================================
place_design
opt_design -pre_cts

# ============================================================
# Top-Level CTS
# ============================================================

# Only build clock trees at top level
# Block-level clocks are already balanced via ILMs
create_ccopt_clock_tree_spec -policy top_only

ccopt_design -cts

opt_design -post_cts -hold

# ============================================================
# Top-Level Routing
# ============================================================
route_design -global_detail

# ============================================================
# Post-Route Optimization
# ============================================================
opt_design -post_route -setup
opt_design -post_route -hold

# ============================================================
# Verify Block Interface Timing
# ============================================================
report_interface_timing -all_blocks \
    > $proj/reports/innovus_hier_interface_timing.rpt

# Check block-to-block paths
foreach blk $hier_blocks {
    report_timing -from [get_pins ${blk}/*] -to [get_pins ${blk}/*] \
        -max_paths 20 \
        > $proj/reports/innovus_hier_${blk}_io_timing.rpt
}

# ============================================================
# Flatten & Final Assembly
# ============================================================

# Flatten ILMs for final signoff
flatten_ilm

# Final chip finish at top level
source $proj/scripts/cadence/innovus/innovus_chip_finish.tcl

# ============================================================
# Save
# ============================================================
save_design $proj/work/cadence/${TOP}_hier_assembled.inn
write_db $proj/work/cadence/${TOP}_hier_assembled.db

puts "============================================"
puts " Hierarchical Top-Level Assembly Complete"
puts " Blocks: [llength $hier_blocks] hardened"
puts " Feedthroughs inserted"
puts " Top-level routing done"
puts "============================================"
