
# ============================================================
# genus_setup.tcl - Cadence Genus Synthesis Environment Setup
# Industry SoC 28nm, Power-aware, MMMC synthesis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

# ---- Tool Settings ----
set_db max_cpus_per_server 32
set_db information_level 7

# ---- Library Setup ----
set lib_dir /pkgs/cadence/28nm/SAED28_EDK

# Target libraries (SS corner for setup closure)
set_db library [list \
    ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ss0p75v125c.lib \
    ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ss0p75v125c.lib \
    ${lib_dir}/lib/stdcell_rvt/nldm/saed28rvt_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_sp_256x64_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_sp_512x128_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_sp_1024x64_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_sp_2048x32_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_sp_4096x64_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_dp_256x64_ss0p75v125c.lib \
    ${lib_dir}/sram/sram_dp_512x128_ss0p75v125c.lib \
    ${lib_dir}/io/saed28io_ss0p75v125c.lib \
]

# LEF for physical synthesis
set_db lef_library [list \
    ${lib_dir}/lef/saed28nm_1p9m_tech.lef \
    ${lib_dir}/lef/saed28hvt.lef \
    ${lib_dir}/lef/saed28lvt.lef \
    ${lib_dir}/lef/saed28rvt.lef \
]

# QRC for physical-aware synthesis
set_db qrc_tech_file ${lib_dir}/qrc/saed28nm_1p9m_Cmax.tch

# ---- Dont Use ----
set_db [get_db lib_cells */DELLN*] .dont_use true
set_db [get_db lib_cells */TIEHI*] .dont_use true
set_db [get_db lib_cells */TIELO*] .dont_use true

# ---- Operating Conditions ----
set_db operating_conditions ss_0p75v_125c

# ---- Wireload ----
set_db auto_wireload_selection true

puts "Genus setup complete for $TOP"
