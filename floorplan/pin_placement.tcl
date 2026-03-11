
# ============================================================
# pin_placement.tcl - IO Pin Placement
# ============================================================

# ---- Power/Ground stripes on all four sides ----
# Left/Right: VDD, VSS alternating
# Top/Bottom: VDD_CPU0, VDD_CPU1, VDD_GPU, VDD_MEM, VDD_IO

# ---- Clock pins (top side) ----
set_pin_physical_constraints -pin_name refclk_25m \
    -layers {M6} -side 3 -offset 500

# ---- JTAG pins (left side, grouped) ----
set_pin_physical_constraints -pin_name tck -layers {M4} -side 4 -offset 300
set_pin_physical_constraints -pin_name tms -layers {M4} -side 4 -offset 350
set_pin_physical_constraints -pin_name tdi -layers {M4} -side 4 -offset 400
set_pin_physical_constraints -pin_name tdo -layers {M4} -side 4 -offset 450

# ---- PCIe pins (right side, differential) ----
for {set i 0} {$i < 4} {incr i} {
    set offset [expr {300 + $i * 150}]
    set_pin_physical_constraints -pin_name pcie_rxp[$i] -layers {M6} -side 2 -offset $offset
    set_pin_physical_constraints -pin_name pcie_rxn[$i] -layers {M6} -side 2 -offset [expr {$offset+75}]
    set_pin_physical_constraints -pin_name pcie_txp[$i] -layers {M6} -side 2 -offset [expr {$offset+1000}]
    set_pin_physical_constraints -pin_name pcie_txn[$i] -layers {M6} -side 2 -offset [expr {$offset+1075}]
}

# ---- DDR memory pins (bottom) ----
set_pin_physical_constraints -pin_name ddr_dq -layers {M5} -side 1 -offset 1000 -width 100
set_pin_physical_constraints -pin_name ddr_addr -layers {M5} -side 1 -offset 2000 -width 50

# ---- GPIO (left side) ----
set_pin_physical_constraints -pin_name gpio -layers {M4} -side 4 -offset 1000 -width 20

# ---- UART, SPI, I2C (bottom-left) ----
set_pin_physical_constraints -pin_name uart0_rxd -layers {M3} -side 1 -offset 400
set_pin_physical_constraints -pin_name uart0_txd -layers {M3} -side 1 -offset 450

# ---- Ethernet RGMII (right side) ----
set_pin_physical_constraints -pin_name rgmii_rxd -layers {M5} -side 2 -offset 2500 -width 20

# ---- Reset and misc (top) ----
set_pin_physical_constraints -pin_name ext_rst_n -layers {M4} -side 3 -offset 600
set_pin_physical_constraints -pin_name test_mode -layers {M4} -side 3 -offset 700
