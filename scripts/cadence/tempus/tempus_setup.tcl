
# ============================================================
# tempus_setup.tcl - Cadence Tempus Timing Signoff Setup
# Multi-corner, SI-aware, AOCV/POCV
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Tool Settings ----
set_multi_cpu_usage -local_cpu 32

# ---- Read Libraries ----
set lib_dir /pkgs/cadence/28nm/SAED28_EDK

# ---- Read Physical Data ----
read_physical -lef [list \
    ${lib_dir}/lef/saed28nm_1p9m_tech.lef \
    ${lib_dir}/lef/saed28hvt.lef \
    ${lib_dir}/lef/saed28lvt.lef \
    ${lib_dir}/lef/saed28rvt.lef \
]

# ---- Read MMMC (same as Innovus) ----
source $proj/scripts/cadence/innovus/innovus_mmmc.tcl

# ---- Read Netlist ----
read_netlist $proj/output/${TOP}_postroute.v -top $TOP

# ---- Read Power Intent ----
read_power_intent -1801 $proj/upf/soc_top.upf

# ---- Initialize ----
init_design
commit_power_intent

# ---- Read SPEF (per RC corner) ----
read_parasitics -format spef \
    -rc_corner rc_typical \
    $proj/output/${TOP}_rc_typical.spef.gz

read_parasitics -format spef \
    -rc_corner rc_cmax \
    $proj/output/${TOP}_rc_cmax.spef.gz

read_parasitics -format spef \
    -rc_corner rc_cmin \
    $proj/output/${TOP}_rc_cmin.spef.gz

# ---- OCV / AOCV / POCV ----
set_db timing_analysis_type ocv
set_db timing_analysis_cppr both
set_db timing_analysis_aocv true

# Read AOCV tables
# read_aocv_table ${lib_dir}/aocv/saed28hvt.aocv
# read_aocv_table ${lib_dir}/aocv/saed28lvt.aocv

# ---- SI Settings ----
set_db si_analysis_type aae
set_db si_delay_separate_on_data true
set_db si_delay_delta_annotation_mode arc_based
set_db si_enable_glitch_propagation true
set_db si_glitch_input_voltage_high_threshold 0.5

puts "============================================"
puts " Tempus Setup Complete"
puts " Design: $TOP"
puts " MMMC:   12 analysis views"
puts " OCV:    AOCV enabled"
puts " SI:     AAE mode"
puts "============================================"
