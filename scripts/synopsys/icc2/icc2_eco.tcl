
# ============================================================
# icc2_eco.tcl - Engineering Change Order Flow
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

open_block $proj/work/soc_top.dlib:soc_top@route_opt_done

# ---- Apply ECO from PT (timing ECO) ----
source $proj/scripts/synopsys/pt/pt_eco.tcl.changes

# ---- Route ECO changes only ----
route_eco \
    -reroute modified_nets \
    -reuse_existing_global_route true

# ---- Verify after ECO ----
verify_drc -output $proj/reports/eco_drc.rpt

# ---- Incremental timing update ----
update_timing -incremental

report_timing -max_paths 20 -file $proj/reports/eco_timing.rpt

save_block -label eco_done
