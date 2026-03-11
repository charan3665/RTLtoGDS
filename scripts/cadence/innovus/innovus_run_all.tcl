
# ============================================================
# innovus_run_all.tcl - Master Flow Script
# Runs the complete Innovus PnR flow end-to-end
# ============================================================
# Usage: innovus -stylus -files innovus_run_all.tcl
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

set flow_start [clock seconds]

puts "======================================================"
puts " Industry SoC: Cadence Innovus Full PnR Flow"
puts " Design:    $TOP"
puts " Tech:      28nm (SAED28)"
puts " Start:     [clock format $flow_start]"
puts "======================================================"

# ---- Step 1: Design Import & Floorplan ----
puts "\n>>> STEP 1: Init & Floorplan"
set t1 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_init.tcl
puts "Step 1 done in [expr {[clock seconds]-$t1}] seconds"

# ---- Step 2: Placement ----
puts "\n>>> STEP 2: Placement & Pre-CTS Optimization"
set t2 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_place.tcl
puts "Step 2 done in [expr {[clock seconds]-$t2}] seconds"

# ---- Step 3: CTS ----
puts "\n>>> STEP 3: Clock Tree Synthesis (CCOpt)"
set t3 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_cts.tcl
puts "Step 3 done in [expr {[clock seconds]-$t3}] seconds"

# ---- Step 4: Routing ----
puts "\n>>> STEP 4: Detail Routing (NanoRoute)"
set t4 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_route.tcl
puts "Step 4 done in [expr {[clock seconds]-$t4}] seconds"

# ---- Step 5: Post-Route Optimization ----
puts "\n>>> STEP 5: Post-Route Optimization (SI, Hold, Power)"
set t5 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_route_opt.tcl
puts "Step 5 done in [expr {[clock seconds]-$t5}] seconds"

# ---- Step 6: Chip Finish ----
puts "\n>>> STEP 6: Chip Finish (Fill, Filler, Via Opt)"
set t6 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_chip_finish.tcl
puts "Step 6 done in [expr {[clock seconds]-$t6}] seconds"

# ---- Step 7: Signoff Export ----
puts "\n>>> STEP 7: Signoff Export (GDS, DEF, SPEF, Netlist)"
set t7 [clock seconds]
source $proj/scripts/cadence/innovus/innovus_signoff.tcl
puts "Step 7 done in [expr {[clock seconds]-$t7}] seconds"

set flow_end [clock seconds]
set total [expr {$flow_end - $flow_start}]

puts ""
puts "======================================================"
puts " FLOW COMPLETE"
puts " Total runtime: ${total} seconds ([expr {$total/60}] min)"
puts " Final outputs in: $proj/output/"
puts "======================================================"
puts " Outputs:"
puts "   GDS:     $proj/output/${TOP}.gds"
puts "   DEF:     $proj/output/${TOP}.def"
puts "   Netlist: $proj/output/${TOP}_postroute.v"
puts "   SPEF:    $proj/output/${TOP}_rc_*.spef.gz"
puts "   SDF:     $proj/output/${TOP}_postroute.sdf"
puts "   Reports: $proj/reports/innovus_*"
puts "======================================================"
