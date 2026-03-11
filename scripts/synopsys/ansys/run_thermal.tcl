
# ============================================================
# run_thermal.tcl - Thermal Analysis (Ansys Totem)
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

totem -thermal \
    -gds $proj/output/soc_top.gds.gz \
    -power_report $proj/reports/signoff_power.rpt \
    -package_model $proj/tech/saed32nm_package_theta.totem \
    -ambient_temp 25 \
    -output_directory $proj/reports/thermal

report_thermal \
    -hotspot_threshold 85 \
    -output $proj/reports/thermal/hotspot_map.rpt

report_junction_temp \
    -domains {PD_CPU0 PD_CPU1 PD_GPU PD_MEM} \
    -output $proj/reports/thermal/junction_temps.rpt

puts "Thermal analysis complete. Hotspot map at: $proj/reports/thermal/"
