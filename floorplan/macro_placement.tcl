
# ============================================================
# macro_placement.tcl - Hard Macro Placement
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ---- L3 Cache Slices (4 x 4MB slices, top half of die) ----
set_fixed_cell -name u_l3/gen_slices[0]/u_slice -location {500 4000}  -orientation R0
set_fixed_cell -name u_l3/gen_slices[1]/u_slice -location {2000 4000} -orientation R0
set_fixed_cell -name u_l3/gen_slices[2]/u_slice -location {3500 4000} -orientation R0
set_fixed_cell -name u_l3/gen_slices[3]/u_slice -location {5000 4000} -orientation R0

# ---- L2 Cache (center, 512KB) ----
set_fixed_cell -name u_l2 -location {2500 2500} -orientation R0

# ---- CPU Cluster (left side) ----
set_fixed_cell -name u_cpu/u_core0 -location {500  500}  -orientation R0
set_fixed_cell -name u_cpu/u_core1 -location {500  2000} -orientation R0

# ---- GPU (right side) ----
set_fixed_cell -name u_gpu -location {4000 500} -orientation R0

# ---- PCIe Controller (bottom right) ----
set_fixed_cell -name u_pcie -location {5000 500} -orientation R0

# ---- Crypto Engine ----
set_fixed_cell -name u_crypto -location {3800 1500} -orientation R0

# ---- DMA Controller ----
set_fixed_cell -name u_dma -location {3800 2500} -orientation R0

# ---- Clock Generator (center-top) ----
set_fixed_cell -name u_clkgen -location {3000 5500} -orientation R0

# ---- Debug Module (top-left corner) ----
set_fixed_cell -name u_dm -location {300 5800} -orientation R0

# ---- USB Controller (bottom-left) ----
set_fixed_cell -name u_usb -location {300 300} -orientation R0

# ---- Ethernet (bottom-center) ----
set_fixed_cell -name u_eth -location {2000 300} -orientation R0

# ---- AXI Crossbar (center) ----
set_fixed_cell -name u_xbar -location {2800 1800} -orientation R0

report_placement_status -macro
