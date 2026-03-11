
# ============================================================
# pt_dmsa.tcl - Distributed Multi-Scenario Analysis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_setup.tcl

# ---- DMSA Setup ----
# Launch distributed workers for each scenario
set_host_options \
    -max_cores 64 \
    -submit_command {bsub -q pri_q -n {num_cores} -R "rusage[mem=8192]"} \
    -num_processes 12

# ---- Create all 12 scenarios in distributed mode ----
create_distributed_pt_workers \
    -num_workers 12 \
    -scenarios [list \
        func_tt_0p85v_25c func_ss_0p75v_m40c func_ss_0p75v_125c \
        func_ff_0p95v_m40c func_ff_0p95v_0c func_tt_0p85v_85c \
        scan_ss_0p75v_125c scan_ff_0p95v_m40c \
        func_ss_aging_0p75v_125c func_tt_0p85v_85c_cmax \
        func_tt_0p85v_25c_cmin func_ss_0p75v_125c_cmax \
    ]

# ---- Each worker loads its scenario ----
foreach scen [all_scenarios] {
    current_scenario $scen
    source $proj/constraints/mcmm/${scen}.sdc
    read_parasitics -corner $scen $proj/output/soc_top_${scen}.spef.gz
}

# ---- Run distributed analysis ----
update_timing -nworkers 12 -full

# ---- Collect results ----
report_timing -scenarios [all_scenarios] -max_paths 50 \
    -file $proj/reports/dmsa_timing.rpt

report_qor -scenarios [all_scenarios] \
    -file $proj/reports/dmsa_qor.rpt

puts "DMSA complete: $(llength [all_scenarios]) scenarios in parallel"
