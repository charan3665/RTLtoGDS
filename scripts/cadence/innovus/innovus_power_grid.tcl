
# ============================================================
# innovus_power_grid.tcl - Power Grid / Power Distribution Network
# Multi-voltage domain PG mesh for Industry SoC
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ============================================================
# Global Net Connections
# ============================================================
connect_global_net VDD -type pg_pin -pin_base_name VDD -inst_base_name *
connect_global_net VSS -type pg_pin -pin_base_name VSS -inst_base_name *

# Per-domain power connections
connect_global_net VDD_CPU  -type pg_pin -pin_base_name VDD -inst_base_name u_cpu_cluster/*
connect_global_net VDD_GPU  -type pg_pin -pin_base_name VDD -inst_base_name u_gpu/*
connect_global_net VDD_MEM  -type pg_pin -pin_base_name VDD -inst_base_name u_l2/* -inst_base_name u_l3/*
connect_global_net VDD_PCIE -type pg_pin -pin_base_name VDD -inst_base_name u_pcie/*
connect_global_net VDD_AON  -type pg_pin -pin_base_name VDD -inst_base_name u_aon/*

# ============================================================
# Power Rings (per voltage area)
# ============================================================

# -- Top-level VDD/VSS ring --
add_rings \
    -nets {VDD VSS} \
    -type core_rings \
    -layer {top M9 bottom M9 left M8 right M8} \
    -width 4.0 \
    -spacing 2.0 \
    -offset 5.0

# -- CPU0 domain ring --
add_rings \
    -nets {VDD_CPU VSS} \
    -type block_rings \
    -around voltage_area:VA_CPU0 \
    -layer {top M7 bottom M7 left M6 right M6} \
    -width 3.0 \
    -spacing 1.5 \
    -offset 3.0

# -- CPU1 domain ring --
add_rings \
    -nets {VDD_CPU VSS} \
    -type block_rings \
    -around voltage_area:VA_CPU1 \
    -layer {top M7 bottom M7 left M6 right M6} \
    -width 3.0 \
    -spacing 1.5 \
    -offset 3.0

# -- GPU domain ring --
add_rings \
    -nets {VDD_GPU VSS} \
    -type block_rings \
    -around voltage_area:VA_GPU \
    -layer {top M7 bottom M7 left M6 right M6} \
    -width 3.5 \
    -spacing 1.5 \
    -offset 3.0

# -- Crypto domain ring --
add_rings \
    -nets {VDD VSS} \
    -type block_rings \
    -around voltage_area:VA_CRYPTO \
    -layer {top M7 bottom M7 left M6 right M6} \
    -width 2.0 \
    -spacing 1.0 \
    -offset 2.0

# -- PCIe domain ring --
add_rings \
    -nets {VDD_PCIE VSS} \
    -type block_rings \
    -around voltage_area:VA_PCIE \
    -layer {top M7 bottom M7 left M6 right M6} \
    -width 2.5 \
    -spacing 1.0 \
    -offset 2.0

# ============================================================
# Power Stripes
# ============================================================

# -- M9 (top metal): Horizontal primary stripes --
add_stripes \
    -nets {VDD VSS} \
    -layer M9 \
    -direction horizontal \
    -width 4.0 \
    -spacing 2.0 \
    -set_to_set_distance 80.0 \
    -start_from left \
    -start 40.0

# -- M8: Vertical primary stripes --
add_stripes \
    -nets {VDD VSS} \
    -layer M8 \
    -direction vertical \
    -width 4.0 \
    -spacing 2.0 \
    -set_to_set_distance 80.0 \
    -start_from bottom \
    -start 40.0

# -- M7: Horizontal secondary stripes --
add_stripes \
    -nets {VDD VSS} \
    -layer M7 \
    -direction horizontal \
    -width 2.0 \
    -spacing 1.0 \
    -set_to_set_distance 40.0 \
    -start_from left \
    -start 20.0

# -- M6: Vertical secondary stripes --
add_stripes \
    -nets {VDD VSS} \
    -layer M6 \
    -direction vertical \
    -width 2.0 \
    -spacing 1.0 \
    -set_to_set_distance 40.0 \
    -start_from bottom \
    -start 20.0

# -- M5: Horizontal fine mesh (for IR drop) --
add_stripes \
    -nets {VDD VSS} \
    -layer M5 \
    -direction horizontal \
    -width 1.0 \
    -spacing 0.5 \
    -set_to_set_distance 20.0 \
    -start_from left \
    -start 10.0

# ============================================================
# CPU Domain-Specific Stripes (VDD_CPU)
# ============================================================
add_stripes \
    -nets {VDD_CPU VSS} \
    -layer M7 \
    -direction horizontal \
    -width 2.5 \
    -spacing 1.5 \
    -set_to_set_distance 30.0 \
    -area [list 220 4500 6780 6780] \
    -start 4510.0

add_stripes \
    -nets {VDD_CPU VSS} \
    -layer M6 \
    -direction vertical \
    -width 2.5 \
    -spacing 1.5 \
    -set_to_set_distance 30.0 \
    -area [list 220 4500 6780 6780] \
    -start 230.0

# ============================================================
# GPU Domain-Specific Stripes (VDD_GPU)
# ============================================================
add_stripes \
    -nets {VDD_GPU VSS} \
    -layer M7 \
    -direction horizontal \
    -width 3.0 \
    -spacing 1.5 \
    -set_to_set_distance 35.0 \
    -area [list 3500 1500 6780 4300] \
    -start 1510.0

add_stripes \
    -nets {VDD_GPU VSS} \
    -layer M6 \
    -direction vertical \
    -width 3.0 \
    -spacing 1.5 \
    -set_to_set_distance 35.0 \
    -area [list 3500 1500 6780 4300] \
    -start 3510.0

# ============================================================
# Standard Cell Rail Connections (M1 followpin)
# ============================================================
set_db add_stripes_stacked_via_bottom_layer M1
set_db add_stripes_stacked_via_top_layer M5

# Route special nets (power/ground)
route_special \
    -connect {core_pin pad_pin block_pin pad_ring floating_stripe} \
    -layer_change_range {M1 M9} \
    -block_pin_target nearest_target \
    -pad_pin_port_connect {all_port one_geom} \
    -pad_pin_target nearest_target \
    -core_pin_target first_after_row_end \
    -floating_stripe_target {block_ring pad_ring ring stripe followpin} \
    -allow_jogging 1 \
    -crossover_via_layer_range {M1 M9} \
    -allow_layer_change 1 \
    -target_via_layer_range {M1 M9}

# ============================================================
# Via Stacking for PG
# ============================================================
edit_power_via \
    -top_layer M9 \
    -bottom_layer M1 \
    -via_array true \
    -orthogonal_only false

# ============================================================
# Verify Power Grid
# ============================================================
verify_pg_connectivity
check_pg_drc

puts "============================================"
puts " Power Grid Generation Complete"
puts " Layers: M5-M9 mesh"
puts " Domains: VDD, VDD_CPU, VDD_GPU, VDD_MEM,"
puts "          VDD_PCIE, VDD_AON, VSS"
puts "============================================"
