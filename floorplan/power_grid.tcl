
# ============================================================
# power_grid.tcl - Power Grid / IR Drop Network
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ---- Ring around core ----
create_pg_ring_pattern ring_pattern \
    -horizontal_layer M8 -horizontal_width 8.0 \
    -vertical_layer   M9 -vertical_width   8.0 \
    -nets {VDD VSS}

set_pg_strategy ring_strat \
    -core \
    -pattern ring_pattern \
    -nets {VDD VSS}
compile_pg -strategies ring_strat

# ---- Main VDD/VSS mesh (M8/M9) ----
create_pg_mesh_pattern main_mesh \
    -horizontal_layer M8 -horizontal_width 4.0 -horizontal_pitch 100.0 \
    -vertical_layer   M9 -vertical_width   4.0 -vertical_pitch   100.0 \
    -nets {VDD VSS}

set_pg_strategy main_mesh_strat \
    -core \
    -pattern main_mesh \
    -nets {VDD VSS}
compile_pg -strategies main_mesh_strat

# ---- CPU0/CPU1 local VDD_CPU mesh ----
create_pg_mesh_pattern cpu_mesh \
    -horizontal_layer M6 -horizontal_width 2.0 -horizontal_pitch 40.0 \
    -vertical_layer   M7 -vertical_width   2.0 -vertical_pitch   40.0 \
    -nets {VDD_CPU0}

set_pg_strategy cpu0_mesh_strat \
    -blockage u_cpu/u_core0 \
    -pattern cpu_mesh \
    -nets {VDD_CPU0}
compile_pg -strategies cpu0_mesh_strat

# ---- GPU local mesh ----
create_pg_mesh_pattern gpu_mesh \
    -horizontal_layer M6 -horizontal_width 2.0 -horizontal_pitch 50.0 \
    -vertical_layer   M7 -vertical_width   2.0 -vertical_pitch   50.0 \
    -nets {VDD_GPU}

set_pg_strategy gpu_mesh_strat \
    -blockage u_gpu \
    -pattern gpu_mesh \
    -nets {VDD_GPU}
compile_pg -strategies gpu_mesh_strat

# ---- L2/L3 memory mesh (VDD_MEM) ----
create_pg_mesh_pattern mem_mesh \
    -horizontal_layer M6 -horizontal_width 2.5 -horizontal_pitch 60.0 \
    -vertical_layer   M7 -vertical_width   2.5 -vertical_pitch   60.0 \
    -nets {VDD_MEM}
set_pg_strategy mem_mesh_strat -blockage {u_l2 u_l3} -pattern mem_mesh -nets {VDD_MEM}
compile_pg -strategies mem_mesh_strat

# ---- Crypto/PCIe/USB/ETH domains ----
create_pg_mesh_pattern io_mesh \
    -horizontal_layer M5 -horizontal_width 1.5 -horizontal_pitch 30.0 \
    -vertical_layer   M6 -vertical_width   1.5 -vertical_pitch   30.0 \
    -nets {VDD_IO}
set_pg_strategy io_mesh_strat -blockage {u_crypto u_pcie u_usb u_eth u_gpio u_uart0} -pattern io_mesh -nets {VDD_IO}
compile_pg -strategies io_mesh_strat

# ---- Standard cell power stripes (M1) ----
create_pg_std_cell_conn_pattern stdcell_conn \
    -layers {M1} \
    -rail_width 0.12

# ---- Verify ----
check_pg_connectivity -check_std_cells
check_pg_via_chains
report_pg_net_connectivity
