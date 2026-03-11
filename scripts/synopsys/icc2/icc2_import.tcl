
# ============================================================
# icc2_import.tcl - Design Import into ICC2 Block
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/icc2/icc2_setup.tcl

# ---- Create Library/Block ----
create_lib -technology $proj/tech/saed32nm.tf \
    -ref_libs [list \
        $proj/lib/saed32rvt_tt0p85v25c.ndm \
        $proj/lib/saed32rvt_ss0p75vm40c.ndm \
        $proj/lib/saed32rvt_ff0p95vm40c.ndm \
        $proj/lib/saed32_sram_macros.ndm \
    ] \
    $proj/work/soc_top.dlib

open_block $proj/work/soc_top.dlib:soc_top

# ---- Read Netlist (post-synthesis) ----
read_verilog -library soc_top \
    [glob $proj/work/syn_out/soc_top_mapped.v]

link_block

# ---- Read UPF ----
read_upf $proj/upf/soc_top.upf
commit_upf

# ---- Set Design Top ----
current_design soc_top

# ---- Read Floorplan (DEF) ----
read_def $proj/floorplan/init.def

# ---- Apply Constraints ----
foreach scen [get_object_name [get_scenarios]] {
    current_scenario $scen
    source $proj/constraints/mcmm/${scen}.sdc
}
source $proj/constraints/clocks/generated_clocks.sdc
source $proj/constraints/clocks/clock_groups.sdc
source $proj/constraints/exceptions/false_paths.sdc
source $proj/constraints/exceptions/multicycle_paths.sdc
source $proj/constraints/exceptions/cdc_constraints.sdc

# ---- Apply Don't-Use ----
source $proj/lib/dont_use.tcl

# ---- Save ----
save_block -label import_done

puts "Import complete: [get_object_name [current_design]]"
