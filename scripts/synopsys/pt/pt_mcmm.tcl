
# ============================================================
# pt_mcmm.tcl - Multi-Corner Multi-Mode STA Setup
# 12 corners with all clock domains
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_setup.tcl

# ---- Create all 12 corners ----
set corner_configs {
    {func_tt_0p85v_25c      tt    0.85  25  cbest   cworst  func}
    {func_ss_0p75v_m40c     ss    0.75 -40  cworst  cworst  func}
    {func_ss_0p75v_125c     ss    0.75  125 cworst  cworst  func}
    {func_ff_0p95v_m40c     ff    0.95 -40  cbest   cbest   func}
    {func_ff_0p95v_0c       ff    0.95   0  cbest   cbest   func}
    {func_tt_0p85v_85c      tt    0.85  85  cworst  cworst  func}
    {scan_ss_0p75v_125c     ss    0.75  125 cworst  cworst  scan}
    {scan_ff_0p95v_m40c     ff    0.95 -40  cbest   cbest   scan}
    {func_ss_aging_0p75v_125c ss  0.75  125 cworst_aging cworst_aging func}
    {func_tt_0p85v_85c_cmax tt    0.85  85  cmax    cmax    func}
    {func_tt_0p85v_25c_cmin tt    0.85  25  cmin    cmin    func}
    {func_ss_0p75v_125c_cmax ss   0.75  125 cmax    cmax    func}
}

foreach cfg $corner_configs {
    set name   [lindex $cfg 0]
    set pvt    [lindex $cfg 1]
    set volt   [lindex $cfg 2]
    set temp   [lindex $cfg 3]
    set rc_min [lindex $cfg 4]
    set rc_max [lindex $cfg 5]
    set mode   [lindex $cfg 6]

    create_scenario $name
    current_scenario $name
    source $proj/constraints/mcmm/${name}.sdc

    read_parasitics -corner $name \
        -min $proj/output/soc_top_${rc_min}.spef.gz \
        -max $proj/output/soc_top_${rc_max}.spef.gz

    set_operating_conditions \
        -analysis_type on_chip_variation \
        -min saed32rvt_${pvt}${volt}_${temp}_min \
        -max saed32rvt_${pvt}${volt}_${temp}_max
}

# Enable all scenarios
set_scenario_options -setup true -hold true -leakage_power true \
    -scenarios [all_scenarios]

puts "MCMM: [llength [all_scenarios]] scenarios configured"
