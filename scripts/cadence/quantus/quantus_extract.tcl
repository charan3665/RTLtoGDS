
# ============================================================
# quantus_extract.tcl - Cadence Quantus RC Extraction
# Multi-corner SPEF generation with coupling capacitance
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

set lib_dir /pkgs/cadence/28nm/SAED28_EDK
set qrc_dir ${lib_dir}/qrc

# ============================================================
# Extraction Technology Files
# ============================================================
set qrc_techfiles {
    {typical  saed28nm_1p9m_Ctypical.tch   25}
    {cmax     saed28nm_1p9m_Cmax.tch      125}
    {cmin     saed28nm_1p9m_Cmin.tch      -40}
    {cmax_125 saed28nm_1p9m_Cmax.tch      125}
    {cmin_m40 saed28nm_1p9m_Cmin.tch      -40}
}

# ============================================================
# Read Design
# ============================================================
read_design -cell $TOP \
    -lef [list \
        ${lib_dir}/lef/saed28nm_1p9m_tech.lef \
        ${lib_dir}/lef/saed28hvt.lef \
        ${lib_dir}/lef/saed28lvt.lef \
    ] \
    -def $proj/output/${TOP}.def

# ============================================================
# Extraction Settings
# ============================================================
set_extraction_options \
    -engine field_solver \
    -coupled true \
    -coupling_cap_threshold 0.005 \
    -ground_net VSS \
    -power_nets {VDD VDD_CPU VDD_GPU VDD_MEM VDD_PCIE VDD_AON} \
    -via_cap_model distributed \
    -net_model lumped \
    -reduction true

# ============================================================
# Multi-Corner Extraction
# ============================================================
foreach corner_spec $qrc_techfiles {
    set corner_name [lindex $corner_spec 0]
    set tech_file   [lindex $corner_spec 1]
    set temperature [lindex $corner_spec 2]

    puts "============================================"
    puts " Extracting corner: $corner_name"
    puts " Tech file: $tech_file"
    puts " Temperature: ${temperature}C"
    puts "============================================"

    set_extraction_options \
        -qrc_tech_file ${qrc_dir}/${tech_file} \
        -temperature $temperature

    # Run extraction
    extract

    # Write SPEF (with coupling)
    write_parasitics -format spef \
        -output $proj/output/${TOP}_rc_${corner_name}.spef.gz \
        -gzip true \
        -coupled true

    # Write SPEF without coupling (for non-SI flows)
    write_parasitics -format spef \
        -output $proj/output/${TOP}_rc_${corner_name}_decoupled.spef.gz \
        -gzip true \
        -coupled false

    puts "Corner $corner_name extraction complete"
}

# ============================================================
# Coupled SPEF for SI (Cmax corner with full coupling)
# ============================================================
set_extraction_options \
    -qrc_tech_file ${qrc_dir}/saed28nm_1p9m_Cmax.tch \
    -temperature 125 \
    -coupled true \
    -coupling_cap_threshold 0.001

extract

write_parasitics -format spef \
    -output $proj/output/${TOP}_rc_cmax_coupled.spef.gz \
    -gzip true \
    -coupled true

# ============================================================
# Reports
# ============================================================
report_extraction_statistics \
    > $proj/reports/quantus_extraction_stats.rpt

report_parasitic_parameters \
    > $proj/reports/quantus_parasitic_params.rpt

puts "============================================"
puts " Quantus Extraction Complete"
puts " Corners: [llength $qrc_techfiles] + 1 coupled"
puts " Output: $proj/output/${TOP}_rc_*.spef.gz"
puts "============================================"
