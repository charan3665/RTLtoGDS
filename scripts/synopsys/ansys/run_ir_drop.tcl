
# ============================================================
# run_ir_drop.tcl - Ansys RedHawk Static IR Drop Analysis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

redhawk -gds $proj/output/soc_top.gds.gz \
    -spef $proj/output/soc_top_tt_0p85v_25c.spef.gz \
    -netlist $proj/output/soc_top_final.v \
    -lef [list $proj/tech/saed32nm_tech.lef $proj/tech/saed32nm_cells.lef] \
    -def $proj/output/soc_top.def.gz \
    -power_net VDD \
    -ground_net VSS \
    -saif $proj/work/sim/soc_top_func.saif \
    -frequency 1000 \
    -voltage 0.85 \
    -output_directory $proj/reports/ir_drop

# Generate IR maps
redhawk_report -ir_drop_map \
    -output $proj/reports/ir_drop/vdd_ir_map.png \
    -net VDD \
    -threshold 0.030

puts "Static IR Drop analysis complete"
puts "Max VDD drop reported in: $proj/reports/ir_drop/"
