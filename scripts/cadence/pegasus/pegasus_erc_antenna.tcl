
# ============================================================
# pegasus_erc_antenna.tcl - ERC & Antenna Check
# Electrical Rule Check + Process Antenna violations
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

set lib_dir /pkgs/cadence/28nm/SAED28_EDK

# ============================================================
# ERC Rule Deck
# ============================================================
set erc_rule_file ${lib_dir}/pegasus/saed28nm_erc.rul
set antenna_rule_file ${lib_dir}/pegasus/saed28nm_antenna.rul

# ============================================================
# Input
# ============================================================
layout_input \
    -gds $proj/output/${TOP}.gds \
    -cell $TOP

# ============================================================
# ERC Configuration
# ============================================================
set_erc_options \
    -max_errors 10000 \
    -parallel_cores 32 \
    -supply_nets {VDD VDD_CPU VDD_GPU VDD_MEM VDD_PCIE VDD_AON VSS}

# ============================================================
# Run ERC
# ============================================================
run_erc \
    -rule_file $erc_rule_file \
    -report $proj/reports/pegasus_erc.rpt \
    -results_db $proj/work/pegasus/${TOP}_erc.db

report_erc_summary > $proj/reports/pegasus_erc_summary.rpt

# ============================================================
# Antenna Check Configuration
# ============================================================
set_antenna_options \
    -max_errors 50000 \
    -antenna_ratio_cumulative true \
    -diode_cell ANTENNACELLD1BWP28NM \
    -parallel_cores 32

# Process antenna rules (per metal layer)
# Antenna ratio limits: M1=400, M2-M4=400, M5-M8=800, via=20
set_antenna_rule -layer M1 -max_ratio 400
set_antenna_rule -layer M2 -max_ratio 400
set_antenna_rule -layer M3 -max_ratio 400
set_antenna_rule -layer M4 -max_ratio 400
set_antenna_rule -layer M5 -max_ratio 800
set_antenna_rule -layer M6 -max_ratio 800
set_antenna_rule -layer M7 -max_ratio 800
set_antenna_rule -layer M8 -max_ratio 800
set_antenna_rule -layer VIA1 -max_ratio 20
set_antenna_rule -layer VIA2 -max_ratio 20
set_antenna_rule -layer VIA3 -max_ratio 20
set_antenna_rule -layer VIA4 -max_ratio 20
set_antenna_rule -layer VIA5 -max_ratio 20
set_antenna_rule -layer VIA6 -max_ratio 20
set_antenna_rule -layer VIA7 -max_ratio 20

# ============================================================
# Run Antenna Check
# ============================================================
run_antenna \
    -rule_file $antenna_rule_file \
    -report $proj/reports/pegasus_antenna.rpt \
    -results_db $proj/work/pegasus/${TOP}_antenna.db

report_antenna_summary > $proj/reports/pegasus_antenna_summary.rpt

# Per-layer antenna violation breakdown
report_antenna_results -by_layer \
    > $proj/reports/pegasus_antenna_by_layer.rpt

# ============================================================
# Density Check
# ============================================================
run_density \
    -rule_file ${lib_dir}/pegasus/saed28nm_density.rul \
    -report $proj/reports/pegasus_density.rpt

report_density_summary > $proj/reports/pegasus_density_summary.rpt

puts "============================================"
puts " Pegasus ERC + Antenna + Density Complete"
puts " ERC:     $proj/reports/pegasus_erc.rpt"
puts " Antenna: $proj/reports/pegasus_antenna.rpt"
puts " Density: $proj/reports/pegasus_density.rpt"
puts "============================================"
