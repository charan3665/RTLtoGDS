
# ============================================================
# genus_read_design.tcl - RTL Read, Elaborate, Power Intent
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
set TOP soc_top

source $proj/scripts/cadence/genus/genus_setup.tcl

# ============================================================
# Read RTL
# ============================================================
set rtl_dirs [list \
    $proj/rtl/cpu/core0 \
    $proj/rtl/cpu/core1 \
    $proj/rtl/cpu/common \
    $proj/rtl/cpu \
    $proj/rtl/cache/l1i \
    $proj/rtl/cache/l1d \
    $proj/rtl/cache/l2 \
    $proj/rtl/cache/l3 \
    $proj/rtl/cache/common \
    $proj/rtl/memory/sram \
    $proj/rtl/memory/regfile \
    $proj/rtl/memory/rom \
    $proj/rtl/interconnect/axi4_xbar \
    $proj/rtl/interconnect/noc \
    $proj/rtl/interconnect/apb \
    $proj/rtl/interconnect/ahb \
    $proj/rtl/gpu/shader \
    $proj/rtl/gpu/rasterizer \
    $proj/rtl/gpu/texunit \
    $proj/rtl/gpu/common \
    $proj/rtl/dma \
    $proj/rtl/crypto \
    $proj/rtl/pcie \
    $proj/rtl/usb \
    $proj/rtl/ethernet \
    $proj/rtl/peripherals/uart \
    $proj/rtl/peripherals/spi \
    $proj/rtl/peripherals/i2c \
    $proj/rtl/peripherals/gpio \
    $proj/rtl/peripherals/timer \
    $proj/rtl/peripherals/wdt \
    $proj/rtl/peripherals/pwm \
    $proj/rtl/clock \
    $proj/rtl/power \
    $proj/rtl/debug \
    $proj/rtl/cdc \
    $proj/rtl/reset \
    $proj/rtl/security \
    $proj/rtl/top \
]

foreach dir $rtl_dirs {
    set vfiles [glob -nocomplain ${dir}/*.v]
    foreach vf $vfiles {
        read_hdl -verilog $vf
    }
}

puts "RTL read: [llength [get_db designs]] files"

# ============================================================
# Elaborate
# ============================================================
elaborate $TOP
check_design -unresolved

puts "Elaboration complete: $TOP"

# ============================================================
# Read Power Intent (UPF)
# ============================================================
read_power_intent -1801 $proj/upf/soc_top.upf
apply_power_intent
commit_power_intent

check_power_intent -all

puts "Power intent applied: 11 power domains"

# ============================================================
# Read Constraints
# ============================================================
read_sdc $proj/constraints/mcmm/func_ss_0p75v_125c.sdc
read_sdc $proj/constraints/clocks/generated_clocks.sdc
read_sdc $proj/constraints/clocks/clock_groups.sdc
read_sdc $proj/constraints/exceptions/false_paths.sdc
read_sdc $proj/constraints/exceptions/multicycle_paths.sdc
read_sdc $proj/constraints/exceptions/case_analysis.sdc
read_sdc $proj/constraints/exceptions/cdc_constraints.sdc

check_timing_intent

puts "Constraints loaded: 16 clocks, MCMM exceptions applied"
