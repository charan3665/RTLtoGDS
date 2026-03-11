
# ============================================================
# dmsa_run.tcl - Launch Distributed DMSA Workers
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
source $proj/scripts/dmsa/dmsa_setup.tcl

# ---- Launch one PT worker per scenario ----
foreach assignment $worker_assignments {
    set wid  [lindex $assignment 0]
    set scen [lindex $assignment 1]

    set worker_script [open $proj/work/dmsa/worker_${wid}.tcl w]
    puts $worker_script "
set proj $proj
source \$proj/scripts/synopsys/pt/pt_setup.tcl
create_scenario $scen
current_scenario $scen
source \$proj/constraints/mcmm/${scen}.sdc
read_parasitics -corner $scen \$proj/output/soc_top_${scen}.spef.gz
update_timing -full
report_timing -max_paths 100 -slack_lesser_than 0.2 -file \$proj/reports/dmsa_worker_${wid}_${scen}.rpt
report_qor -file \$proj/reports/dmsa_qor_${scen}.rpt
write_sdf -corner $scen -output \$proj/output/sdf/${scen}.sdf
exit 0
"
    close $worker_script

    # Launch worker (adjust submit command to cluster scheduler)
    exec bsub -J dmsa_w${wid} -o $proj/logs/dmsa_w${wid}.log \
        pt_shell -f $proj/work/dmsa/worker_${wid}.tcl &
}

puts "Launched $dmsa_num_workers DMSA workers"
