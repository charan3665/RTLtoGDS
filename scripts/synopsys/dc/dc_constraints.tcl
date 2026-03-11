
# ============================================================
# dc_constraints.tcl - Apply SDC Constraints for Synthesis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/constraints/mcmm/func_tt_0p85v_25c.sdc
source $proj/constraints/clocks/clock_groups.sdc
source $proj/constraints/exceptions/false_paths.sdc
source $proj/constraints/exceptions/multicycle_paths.sdc
source $proj/lib/dont_use.tcl

# ---- Synthesis-specific constraints ----
set_max_area 0
set_max_fanout 20 [current_design]
set_max_transition 0.200 [current_design]

# ---- Boundary conditions ----
set_driving_cell -lib_cell BUFFD4BWP28NM [all_inputs]
set_load 0.050 [all_outputs]

puts "Constraints applied"
