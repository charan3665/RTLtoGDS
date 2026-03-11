
# ============================================================
# sram_placement.tcl - SRAM Macro Placement
# All SRAM banks with coordinates, orientation, and halos
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# Halo definition for all SRAMs: 5um on each side
proc place_sram {inst x y orient} {
    set_fixed_cell -name $inst -location [list $x $y] -orientation $orient
    set_keepout_margin -type soft -all_macros \
        -north 5 -south 5 -east 5 -west 5 \
        [get_cells $inst]
}

# ---- L1I Cache SRAMs (Tag + Data per core) ----
# Core 0: 4 banks (4-way)
place_sram u_l1i0/u_data0  600  1100  R0
place_sram u_l1i0/u_data1  800  1100  R0
place_sram u_l1i0/u_data2  600  1300  R0
place_sram u_l1i0/u_data3  800  1300  R0

# ---- L1D Cache SRAMs ----
place_sram u_l1d0/u_data0  1000  1100  R0
place_sram u_l1d0/u_data1  1200  1100  R0
place_sram u_l1d0/u_data2  1000  1300  R0
place_sram u_l1d0/u_data3  1200  1300  R0

# ---- L2 Cache SRAMs (8-way, 1024 sets, 64B/line = 512KB) ----
# 16 SRAM macros of 512x128: 8 ways x 2 banks
for {set w 0} {$w < 8} {incr w} {
    set x [expr {2500 + $w * 200}]
    place_sram u_l2/u_data_arr_way${w}_bank0  $x  2600  R0
    place_sram u_l2/u_data_arr_way${w}_bank1  $x  2800  R0
}
# L2 Tag SRAMs (8-way, 1024 sets)
for {set w 0} {$w < 8} {incr w} {
    set x [expr {2500 + $w * 200}]
    place_sram u_l2/u_tag_arr_way${w}  $x  2500  R0
}

# ---- L3 Slice SRAMs (4 slices, 16-way each) ----
# Each slice: 16 * (4096 sets * 512 bits / 8) = 4MB
# 32 SRAMs of 4096x64 per slice
for {set s 0} {$s < 4} {incr s} {
    set base_x [expr {500 + $s * 1500}]
    for {set w 0} {$w < 16} {incr w} {
        set x [expr {$base_x + ($w % 8) * 150}]
        set y [expr {4100 + ($w / 8) * 300}]
        place_sram u_l3/gen_slices[${s}]/u_slice/data_bank${w}  $x  $y  R0
    end
}

# ---- Register File SRAMs ----
# Physical register file (128 x 64): uses regfile_10r6w_128x64
place_sram u_cpu/u_core0/u_prf/u_sram_rd  1600  1100  R0
place_sram u_cpu/u_core0/u_prf/u_sram_wr  1600  1300  R0
place_sram u_cpu/u_core1/u_prf/u_sram_rd  1800  1100  R0
place_sram u_cpu/u_core1/u_prf/u_sram_wr  1800  1300  R0

# ---- ROB / Issue Queue SRAMs ----
place_sram u_cpu/u_core0/u_rob_sram  650  1500  R0
place_sram u_cpu/u_core1/u_rob_sram  850  1500  R0

# ---- GPU Local Memory SRAMs ----
for {set sm 0} {$sm < 4} {incr sm} {
    set x [expr {4100 + $sm * 300}]
    place_sram u_gpu/gen_sm[${sm}]/u_sm/lmem  $x  700  R0
}

# ---- Boot ROM / Config ROM ----
place_sram u_boot_rom   300  5500  R0
place_sram u_config_rom 500  5500  R0

puts "SRAM placement complete"
