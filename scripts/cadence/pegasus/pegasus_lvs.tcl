
# ============================================================
# pegasus_lvs.tcl - Cadence Pegasus Layout vs Schematic
# Signoff LVS for 28nm process
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

set lib_dir /pkgs/cadence/28nm/SAED28_EDK

# ============================================================
# LVS Rule Deck
# ============================================================
set lvs_rule_file ${lib_dir}/pegasus/saed28nm_lvs.rul

# ============================================================
# Input Files
# ============================================================

# Layout (GDS)
layout_input \
    -gds $proj/output/${TOP}.gds \
    -cell $TOP

# Schematic (Verilog netlist)
schematic_input \
    -verilog $proj/output/${TOP}_postroute_flat.v \
    -top $TOP

# ============================================================
# LVS Configuration
# ============================================================
set_lvs_options \
    -max_errors 10000 \
    -parallel_cores 32 \
    -supply_nets {VDD VDD_CPU VDD_GPU VDD_MEM VDD_PCIE VDD_AON VSS} \
    -power_pin_names {VDD VDD_CPU VDD_GPU VDD_MEM VDD_PCIE VDD_AON} \
    -ground_pin_names {VSS}

# SRAM black-box handling
set_lvs_options \
    -black_box_cells [list \
        sram_sp_256x64 sram_sp_512x128 sram_sp_1024x64 \
        sram_sp_2048x32 sram_sp_4096x64 \
        sram_dp_256x64 sram_dp_512x128 \
    ]

# ============================================================
# Run LVS
# ============================================================
run_lvs \
    -rule_file $lvs_rule_file \
    -report $proj/reports/pegasus_lvs.rpt \
    -results_db $proj/work/pegasus/${TOP}_lvs.db

# ============================================================
# LVS Summary
# ============================================================
report_lvs_summary > $proj/reports/pegasus_lvs_summary.rpt

# Detailed mismatch report
report_lvs_mismatches \
    -max_mismatches 1000 \
    > $proj/reports/pegasus_lvs_mismatches.rpt

puts "============================================"
puts " Pegasus LVS Complete"
puts " Results: $proj/reports/pegasus_lvs.rpt"
puts "============================================"
