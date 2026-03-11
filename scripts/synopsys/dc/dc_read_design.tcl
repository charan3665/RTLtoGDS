
# ============================================================
# dc_read_design.tcl - Read RTL Sources
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
source $proj/scripts/synopsys/dc/dc_setup.tcl

analyze -format verilog {
    $proj/rtl/cpu/core0/physical_regfile.v
    $proj/rtl/cpu/core0/branch_predictor.v
    $proj/rtl/cpu/core0/fpu.v
    $proj/rtl/cpu/core0/csr_unit.v
    $proj/rtl/cpu/core0/rob.v
    $proj/rtl/cpu/core0/lsu.v
    $proj/rtl/cpu/core0/execution_units.v
    $proj/rtl/cpu/core0/issue_queue.v
    $proj/rtl/cpu/core0/rename_unit.v
    $proj/rtl/cpu/core0/decode_unit.v
    $proj/rtl/cpu/core0/fetch_unit.v
    $proj/rtl/cpu/core0/cpu_core0_top.v
    $proj/rtl/cpu/core1/cpu_core1_top.v
    $proj/rtl/cpu/common/mmu.v
    $proj/rtl/cpu/common/itlb.v
    $proj/rtl/cpu/common/dtlb.v
    $proj/rtl/cpu/cpu_cluster.v
}

# Cache
analyze -format verilog [glob $proj/rtl/cache/*/*.v]
# Memory
analyze -format verilog [glob $proj/rtl/memory/*/*.v]
# Interconnect
analyze -format verilog [glob $proj/rtl/interconnect/*/*.v]
# GPU
analyze -format verilog [glob $proj/rtl/gpu/*/*.v]
# IP blocks
analyze -format verilog [glob $proj/rtl/dma/*.v]
analyze -format verilog [glob $proj/rtl/crypto/*.v]
analyze -format verilog [glob $proj/rtl/pcie/*.v]
analyze -format verilog [glob $proj/rtl/usb/*.v]
analyze -format verilog [glob $proj/rtl/ethernet/*.v]
analyze -format verilog [glob $proj/rtl/peripherals/*/*.v]
# Infrastructure
analyze -format verilog [glob $proj/rtl/clock/*.v]
analyze -format verilog [glob $proj/rtl/power/*.v]
analyze -format verilog [glob $proj/rtl/debug/*.v]
analyze -format verilog [glob $proj/rtl/cdc/*.v]
analyze -format verilog [glob $proj/rtl/reset/*.v]
analyze -format verilog [glob $proj/rtl/security/*.v]
# Top level
analyze -format verilog $proj/rtl/top/soc_top.v

elaborate soc_top
link
uniquify

puts "Design read complete: [get_object_name [current_design]]"
puts "Cell count: [llength [get_cells -hierarchical]]"
