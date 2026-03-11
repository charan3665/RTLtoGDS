
# ============================================================
# pt_setup.tcl - PrimeTime Setup: Library, Parasitics, Design
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ---- Set search paths ----
set_app_var search_path [list $proj/lib $proj/work/output .]

# ---- Read timing libraries ----
set_app_var link_library [list \
    saed32rvt_tt0p85v25c.db \
    saed32rvt_ss0p75v125c.db \
    saed32rvt_ff0p95vm40c.db \
    saed32_sram_tt0p85v25c.db \
    saed32_io_tt0p85v25c.db \
    * \
]

# ---- Read design netlist ----
read_verilog $proj/output/soc_top_final.v
current_design soc_top
link_design

# ---- Read parasitics (SPEF from StarRC) ----
# Read SPEF for nominal corner
read_parasitics \
    -format spef \
    -keep_capacitive_coupling \
    $proj/output/soc_top_tt_0p85v_25c.spef.gz

# ---- Scale parasitics for corners ----
set_app_var si_delay_separate_on_data true
set_app_var report_default_significant_digits 4

# ---- Operating conditions ----
set_operating_conditions \
    -analysis_type bc_wc \
    -max saed32rvt_ss0p75v125c_max \
    -min saed32rvt_ff0p95vm40c_min

puts "PT setup complete for [get_object_name [current_design]]"
