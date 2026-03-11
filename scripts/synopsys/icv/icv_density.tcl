
# ============================================================
# icv_density.tcl - Metal Density Check
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

icv -gds $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -runset $proj/tech/saed32nm_density.rs \
    -density \
    -output_directory $proj/reports/icv_density \
    -jobs 8

report_density \
    -layers {M1 M2 M3 M4 M5 M6 M7 M8 M9} \
    -output $proj/reports/metal_density_icv.rpt

puts "Density check complete"
