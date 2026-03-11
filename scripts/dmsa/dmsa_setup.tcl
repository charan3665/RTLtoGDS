
# ============================================================
# dmsa_setup.tcl - DMSA Master Setup
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

set dmsa_scenarios {
    func_tt_0p85v_25c      func_ss_0p75v_m40c     func_ss_0p75v_125c
    func_ff_0p95v_m40c     func_ff_0p95v_0c        func_tt_0p85v_85c
    scan_ss_0p75v_125c     scan_ff_0p95v_m40c
    func_ss_aging_0p75v_125c func_tt_0p85v_85c_cmax
    func_tt_0p85v_25c_cmin   func_ss_0p75v_125c_cmax
}

set dmsa_num_workers [llength $dmsa_scenarios]
set dmsa_master_host [exec hostname]

# Load balancing: assign one worker per scenario
proc assign_workers {scenarios} {
    global proj
    set assignments {}
    set worker_id 0
    foreach s $scenarios {
        lappend assignments [list $worker_id $s]
        incr worker_id
    }
    return $assignments
}

set worker_assignments [assign_workers $dmsa_scenarios]
puts "DMSA: $dmsa_num_workers workers assigned to $dmsa_num_workers scenarios"
