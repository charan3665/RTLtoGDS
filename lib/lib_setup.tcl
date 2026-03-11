
# ============================================================
# lib_setup.tcl - Library Setup for SAED32 28nm
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ---- Library Root ----
set LIB_ROOT $proj/lib/saed32

# ---- Standard Cell Libraries ----
set STDCELL_DB_PATH $LIB_ROOT/saed32rvt/db

# Timing libraries (all PVT corners)
set TT_DB $STDCELL_DB_PATH/saed32rvt_tt0p85v25c.db
set SS_DB $STDCELL_DB_PATH/saed32rvt_ss0p75v125c.db
set FF_DB $STDCELL_DB_PATH/saed32rvt_ff0p95vm40c.db

# NDM libraries (ICC2)
set TT_NDM $STDCELL_DB_PATH/saed32rvt_tt0p85v25c.ndm
set SS_NDM $STDCELL_DB_PATH/saed32rvt_ss0p75v125c.ndm
set FF_NDM $STDCELL_DB_PATH/saed32rvt_ff0p95vm40c.ndm

# ---- SRAM Macro Libraries ----
set SRAM_DB_PATH $LIB_ROOT/sram_macros/db
set SRAM_LIBS [list \
    $SRAM_DB_PATH/saed32_sram_sp_256x64_tt0p85v25c.db \
    $SRAM_DB_PATH/saed32_sram_sp_512x128_tt0p85v25c.db \
    $SRAM_DB_PATH/saed32_sram_sp_1024x64_tt0p85v25c.db \
    $SRAM_DB_PATH/saed32_sram_sp_2048x32_tt0p85v25c.db \
    $SRAM_DB_PATH/saed32_sram_sp_4096x64_tt0p85v25c.db \
    $SRAM_DB_PATH/saed32_sram_dp_256x64_tt0p85v25c.db \
    $SRAM_DB_PATH/saed32_sram_dp_512x128_tt0p85v25c.db \
]

# ---- IO Cell Libraries ----
set IO_DB_PATH $LIB_ROOT/io/db
set IO_LIBS [list \
    $IO_DB_PATH/saed32_io_tt0p85v25c.db \
]

# ---- Link Library Setup ----
set_app_var link_library   [concat [list *] $SRAM_LIBS $IO_LIBS $TT_DB]
set_app_var target_library [list $TT_DB]

# ---- NDM for ICC2 ----
set_app_var ndm_library [concat [list $TT_NDM $SS_NDM $FF_NDM] \
    [glob $SRAM_DB_PATH/*.ndm] \
    [glob $IO_DB_PATH/*.ndm] \
]

puts "Library setup complete"
puts "  Standard cells: SAED32RVT (TT/SS/FF corners)"
puts "  SRAM macros: [llength $SRAM_LIBS] variants"
puts "  IO cells: [llength $IO_LIBS] variants"
