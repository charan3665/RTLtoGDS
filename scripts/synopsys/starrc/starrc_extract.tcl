
# ============================================================
# starrc_extract.tcl - Run StarRC for All Corners
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
source $proj/scripts/synopsys/starrc/starrc_setup.tcl

set corners {
    {tt_0p85v_25c   typical   $proj/output/soc_top_tt_0p85v_25c.spef.gz}
    {ss_0p75v_125c  worstcase $proj/output/soc_top_ss_0p75v_125c.spef.gz}
    {ff_0p95v_m40c  bestcase  $proj/output/soc_top_ff_0p95v_m40c.spef.gz}
}

foreach c $corners {
    set cname  [lindex $c 0]
    set ctype  [lindex $c 1]
    set output [lindex $c 2]
    puts "Extracting parasitics for corner: $cname ($ctype)"
    run_starrc $ctype $proj/output/soc_top.gds $proj/output/soc_top.def $output
    puts "Extraction complete: $output"
}

# Also extract with coupling for SI analysis
run_starrc typical \
    $proj/output/soc_top.gds \
    $proj/output/soc_top.def \
    $proj/output/soc_top_tt_0p85v_25c_ccouple.spef.gz
