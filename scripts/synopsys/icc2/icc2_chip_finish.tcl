
# ============================================================
# icc2_chip_finish.tcl - Metal Fill, Via Optimization, Final DRC
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@route_opt_done

# ---- Metal Fill (for planarity/etching) ----
create_stdcell_fillers \
    -cell_names {FILL1BWP28NM FILL2BWP28NM FILL4BWP28NM FILL8BWP28NM FILL16BWP28NM} \
    -connect_to_power   VDD \
    -connect_to_ground  VSS

metal_fill \
    -metal_fill_layers {M1 M2 M3 M4 M5 M6 M7 M8 M9} \
    -timing_aware  true \
    -si_aware      true \
    -density_step  0.05

# ---- Via Optimization (improve reliability) ----
optimize_via_implementation \
    -wide_metal true \
    -cutclass_aware true \
    -effort high

# ---- Decap Filler Insertion ----
insert_decap_cells \
    -budget 500000 \
    -target_frequency 2000 \
    -lib_cell_list {DCAP1BWP28NM DCAP2BWP28NM DCAP4BWP28NM DCAP8BWP28NM}

# ---- Final DRC ----
verify_drc -output $proj/reports/chip_finish_drc.rpt
verify_lvs -output $proj/reports/chip_finish_lvs.rpt

# ---- Density Check ----
check_metal_density \
    -file $proj/reports/metal_density.rpt

save_block -label chip_finish_done
puts "Chip finishing complete"
