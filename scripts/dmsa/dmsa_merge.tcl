
# ============================================================
# dmsa_merge.tcl - Merge DMSA Results
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
source $proj/scripts/dmsa/dmsa_setup.tcl

# Wait for all workers to complete
proc wait_for_workers {scenarios} {
    global proj
    set all_done 0
    while {!$all_done} {
        set all_done 1
        foreach s $scenarios {
            if {![file exists $proj/reports/dmsa_qor_${s}.rpt]} {
                set all_done 0
                after 30000
                break
            }
        }
    }
    puts "All DMSA workers complete"
}

wait_for_workers $dmsa_scenarios

# ---- Aggregate WNS/TNS/NVP across all scenarios ----
set f_out [open $proj/reports/dmsa_summary.rpt w]
puts $f_out "DMSA Multi-Scenario Summary"
puts $f_out "==========================="
puts $f_out [format "%-40s %10s %12s %10s" "Scenario" "WNS(ns)" "TNS(ns)" "NVP"]

foreach scen $dmsa_scenarios {
    set rpt_file $proj/reports/dmsa_qor_${scen}.rpt
    if {[file exists $rpt_file]} {
        set f [open $rpt_file]
        while {[gets $f line] >= 0} {
            if {[regexp {WNS.*:\s*([-0-9.]+)} $line m wns]} {
                if {[regexp {TNS.*:\s*([-0-9.]+)} $line m tns]} {
                    if {[regexp {NVP.*:\s*([-0-9.]+)} $line m nvp]} {
                        puts $f_out [format "%-40s %10.3f %12.3f %10.0f" $scen $wns $tns $nvp]
                    }
                }
            }
        }
        close $f
    }
}
close $f_out
puts "DMSA merge complete: $proj/reports/dmsa_summary.rpt"
