
# ============================================================
# tech_setup.tcl - Technology File and Layer Setup (SAED32 28nm)
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

set TECH_ROOT $proj/tech

# ---- Technology File ----
set TECH_FILE $TECH_ROOT/saed32nm.tf

# ---- LEF Files ----
set LEF_FILES [list \
    $TECH_ROOT/saed32nm_tech.lef \
    $TECH_ROOT/saed32rvt_cells.lef \
    $TECH_ROOT/saed32_sram_macros.lef \
    $TECH_ROOT/saed32_io_cells.lef \
]

# ---- Routing Layers ----
# M1:  Horizontal - 0.064um min width, 0.068um pitch
# M2:  Vertical   - 0.064um min width, 0.068um pitch
# M3:  Horizontal - 0.064um min width, 0.068um pitch
# M4:  Vertical   - 0.064um min width, 0.068um pitch
# M5:  Horizontal - 0.080um min width, 0.120um pitch
# M6:  Vertical   - 0.080um min width, 0.120um pitch
# M7:  Horizontal - 0.120um min width, 0.200um pitch
# M8:  Vertical   - 0.200um min width, 0.400um pitch (power)
# M9:  Horizontal - 0.200um min width, 0.400um pitch (power)
# AP:  Aluminum pad layer

set ROUTING_LAYERS {M1 M2 M3 M4 M5 M6 M7 M8 M9}
set POWER_LAYERS   {M8 M9}

# ---- Via Definitions ----
set VIA_LAYERS {V1 V2 V3 V4 V5 V6 V7 V8}

# ---- Parasitic Technology (for StarRC) ----
set NXTGRD_FILE $TECH_ROOT/saed32nm.nxtgrd
set ITF_FILE    $TECH_ROOT/saed32nm_mapping.itf

# ---- Design Rules ----
set DRC_RULESET $TECH_ROOT/saed32nm_drc.rs
set LVS_RULESET $TECH_ROOT/saed32nm_lvs.rs
set ERC_RULESET $TECH_ROOT/saed32nm_erc.rs

puts "Technology: SAED32 28nm"
puts "Metal layers: [llength $ROUTING_LAYERS] (M1-M9 + AP)"
puts "Technology file: $TECH_FILE"
