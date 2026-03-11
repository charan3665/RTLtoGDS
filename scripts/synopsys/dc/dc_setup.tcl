
# ============================================================
# dc_setup.tcl - Design Compiler Setup
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

set_app_var search_path [list $proj/lib $proj/rtl .]
set_app_var link_library [list saed32rvt_tt0p85v25c.db *]
set_app_var target_library saed32rvt_tt0p85v25c.db
set_app_var synthetic_library dw_foundation.sldb

set_host_options -max_cores 16

set SYN_EFFORT   high
set MAP_EFFORT   high
set OPT_EFFORT   high

puts "DC setup: lib=$target_library effort=$SYN_EFFORT"
