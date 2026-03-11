
# ============================================================
# innovus_setup.tcl - Cadence Innovus Environment & Library Setup
# Industry SoC Hierarchical PnR Flow (28nm)
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Tool Settings ----
set_multi_cpu_usage -local_cpu 32 -remote_cpu 0
set_db design_process_node 28
set_db design_tech_node 28

# ---- Library Directories ----
set lib_dir   /pkgs/cadence/28nm/SAED28_EDK
set lef_dir   ${lib_dir}/lef
set lib_ss    ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ss0p75vm40c.lib
set lib_tt    ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_tt0p85v25c.lib
set lib_ff    ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ff0p95vm40c.lib
set lib_lvt_ss ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ss0p75vm40c.lib
set lib_lvt_tt ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_tt0p85v25c.lib
set lib_lvt_ff ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ff0p95vm40c.lib

# SRAM macro libs
set sram_dir  ${lib_dir}/sram
set sram_libs [list \
    ${sram_dir}/sram_sp_256x64_ss.lib \
    ${sram_dir}/sram_sp_512x128_ss.lib \
    ${sram_dir}/sram_sp_1024x64_ss.lib \
    ${sram_dir}/sram_sp_2048x32_ss.lib \
    ${sram_dir}/sram_sp_4096x64_ss.lib \
    ${sram_dir}/sram_dp_256x64_ss.lib \
    ${sram_dir}/sram_dp_512x128_ss.lib \
]

# IO pad libs
set io_dir    ${lib_dir}/io
set io_libs   [list ${io_dir}/saed28io_ss.lib]

# ---- LEF Files ----
set tech_lef  ${lef_dir}/saed28nm_1p9m_tech.lef
set cell_lefs [list \
    ${lef_dir}/saed28hvt.lef \
    ${lef_dir}/saed28lvt.lef \
    ${lef_dir}/saed28rvt.lef \
    ${sram_dir}/sram_sp_256x64.lef \
    ${sram_dir}/sram_sp_512x128.lef \
    ${sram_dir}/sram_sp_1024x64.lef \
    ${sram_dir}/sram_sp_2048x32.lef \
    ${sram_dir}/sram_sp_4096x64.lef \
    ${sram_dir}/sram_dp_256x64.lef \
    ${sram_dir}/sram_dp_512x128.lef \
    ${io_dir}/saed28io.lef \
]

# ---- QRC Tech Files (extraction) ----
set qrc_dir   ${lib_dir}/qrc
set qrc_tech  ${qrc_dir}/saed28nm_1p9m_Cmax.tch
set qrc_cmin  ${qrc_dir}/saed28nm_1p9m_Cmin.tch

# ---- MMMC (Multi-Mode Multi-Corner) Setup ----
# Defined in innovus_mmmc.tcl
source $proj/scripts/cadence/innovus/innovus_mmmc.tcl

# ---- OCV / AOCV / POCV Settings ----
set_db timing_analysis_type ocv
set_db timing_analysis_cppr both
set_db timing_analysis_aocv true

# ---- Design Rule Settings ----
set_db route_design_antenna_diode_insertion true
set_db route_design_detail_post_route_spread_wire true
set_db opt_useful_skew true

# ---- Dont Use Cells ----
set_dont_use [get_lib_cells */DELLN*]
set_dont_use [get_lib_cells */TIEHI*]
set_dont_use [get_lib_cells */TIELO*]

# ---- Power Intent ----
set upf_file $proj/upf/soc_top.upf

puts "============================================"
puts " Innovus Setup Complete"
puts " Design:    $TOP"
puts " Tech node: 28nm"
puts " MMMC:      12 corners defined"
puts "============================================"
