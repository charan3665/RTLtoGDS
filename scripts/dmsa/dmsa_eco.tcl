
# ============================================================
# dmsa_eco.tcl - DMSA-based ECO Generation
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
source $proj/scripts/dmsa/dmsa_setup.tcl

# ---- Identify failing scenarios ----
set failing_scenarios {}
foreach scen $dmsa_scenarios {
    set f [open $proj/reports/dmsa_qor_${scen}.rpt r]
    while {[gets $f line] >= 0} {
        if {[regexp {WNS.*:\s*([-0-9.]+)} $line m wns]} {
            if {$wns < -0.050} { lappend failing_scenarios $scen }
        }
    }
    close $f
}

puts "Failing scenarios: $failing_scenarios"

# ---- Generate ECO for each failing scenario ----
foreach scen $failing_scenarios {
    pt_shell -x "
        source $proj/scripts/synopsys/pt/pt_setup.tcl
        current_scenario $scen
        source $proj/constraints/mcmm/${scen}.sdc
        read_parasitics $proj/output/soc_top_${scen}.spef.gz
        update_timing
        fix_eco_timing -setup -hold -effort high -max_paths 100
        write_changes -format icc2 -output $proj/work/eco/${scen}_changes.tcl
    "
}

# ---- Apply ECOs in ICC2 ----
foreach scen $failing_scenarios {
    if {[file exists $proj/work/eco/${scen}_changes.tcl]} {
        puts "Applying ECO for scenario: $scen"
        icc2_shell -x "
            open_block $proj/work/soc_top.dlib:soc_top@route_opt_done
            source $proj/work/eco/${scen}_changes.tcl
            route_eco
            save_block -label eco_${scen}_done
        "
    }
}
puts "DMSA ECO complete"
