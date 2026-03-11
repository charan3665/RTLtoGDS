
# ============================================================
# keepout.tcl - Keepout and Placement Blockages
# ============================================================

# ---- Hard keepout around SRAM macros (5um halo) ----
foreach macro [get_cells -hierarchical -filter "is_hard_macro == true"] {
    set_keepout_margin -type hard -all_macros \
        -north 5 -south 5 -east 5 -west 5 \
        $macro
}

# ---- PLL placement blockage (sensitive to digital noise) ----
create_placement_blockage -type hard \
    -bbox {5500 5000 6700 6700} \
    -name pll_blockage

# ---- Clock tree blockage over SRAM arrays ----
create_routing_blockage -layers {M1 M2} \
    -bbox {2500 2500 4500 3500} \
    -name l2_clock_blockage

# ---- IO ring area reservation ----
create_placement_blockage -type hard \
    -bbox {0 0 250 7000} -name left_io_block
create_placement_blockage -type hard \
    -bbox {6750 0 7000 7000} -name right_io_block
create_placement_blockage -type hard \
    -bbox {0 0 7000 250} -name bottom_io_block
create_placement_blockage -type hard \
    -bbox {0 6750 7000 7000} -name top_io_block

# ---- PCIe SerDes analog area (no digital cells) ----
create_placement_blockage -type hard \
    -bbox {5000 0 6700 1000} \
    -name pcie_serdes_blockage

# ---- Decap cell reservation areas (near power switches) ----
create_placement_blockage -type soft \
    -bbox {450 450 700 700} \
    -name cpu0_decap_reserve

# ---- Voltage domain boundary buffer ----
set_voltage_area -name VA_CPU0 \
    -usage PD_CPU0 \
    -regions {{500 500 1900 2500}}

set_voltage_area -name VA_CPU1 \
    -usage PD_CPU1 \
    -regions {{500 2000 1900 3500}}

set_voltage_area -name VA_GPU \
    -usage PD_GPU \
    -regions {{4000 500 6000 2500}}

set_voltage_area -name VA_MEM \
    -usage PD_MEM \
    -regions {{2000 2000 5000 5500}}
