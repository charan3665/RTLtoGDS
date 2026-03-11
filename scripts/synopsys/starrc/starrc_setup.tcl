
# ============================================================
# starrc_setup.tcl - StarRC Extraction Setup
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# Technology data
set NXTGRD_FILE $proj/tech/saed32nm.nxtgrd
set MAPPING_FILE $proj/tech/saed32nm_mapping.itf

# Extraction modes
set EXTRACT_MODES {
    typical  {-X TYPICAL}
    bestcase {-X BESTCASE}
    worstcase {-X WORSTCASE}
}

proc run_starrc {corner gds def output_spef} {
    global proj NXTGRD_FILE MAPPING_FILE
    exec StarXtract -cmd {
        GROUND_NETS: VSS
        SUPPLY_NETS: VDD VDD_CPU0 VDD_CPU1 VDD_GPU VDD_MEM VDD_IO VDD_CRYPTO VDD_PCIE
        MILKYWAY_DATABASE: $proj/work/soc_top.dlib
        BLOCK: soc_top@route_opt_done
        NXTGRD: $NXTGRD_FILE
        MAPPING_FILE: $MAPPING_FILE
        NETLIST_FORMAT: SPEF
        NETLIST_FILE: $output_spef
        COUPLED_LINES_MAXIMUM_DISTANCE: 5.0
        EXTRACTION_CORNER: $corner
        REDUCTION: NONE
        COUPLING_ABS_THRESHOLD: 0.001fF
        COUPLING_REL_THRESHOLD: 0.01
    }
}
