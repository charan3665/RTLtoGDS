
# ============================================================
# icc2_hier_top.tcl - Hierarchical Top-Level Assembly
# Assembles pre-placed blocks into top-level
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ---- Open/Create top library ----
open_lib $proj/work/soc_top.dlib

# ---- Abstract views for sub-blocks ----
set blocks {
    cpu_core0_top cpu_core1_top
    l1i_cache l1d_cache l2_cache l3_cache
    gpu_top dma_controller crypto_top
    pcie_top usb_top eth_top
    axi4_crossbar clock_gen_top
}

foreach block $blocks {
    read_block -from_ascii $proj/work/blocks/${block}_abstract.dlib:${block}
}

# ---- Assemble top ----
open_block $proj/work/soc_top.dlib:soc_top
link_block -design soc_top

# ---- Inherit constraints from blocks ----
read_upf -scope u_cpu  $proj/upf/soc_top.upf
commit_upf

# ---- Top-level routing ----
route_global_in_top

# ---- Top-level timing closure ----
report_timing -max_paths 50 -file $proj/reports/hier_top_timing.rpt

save_block -label hier_assembly_done
