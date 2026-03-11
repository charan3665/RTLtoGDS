
# ============================================================
# icc2_setup.tcl - ICC2 Environment and Library Setup
# Synopsys IC Compiler II Hierarchical Flow
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ---- Tool Version Check ----
set icc2_version [get_app_var tool_version]
puts "ICC2 Version: $icc2_version"

# ---- License ----
set_host_options -max_cores 32

# ---- Technology Setup ----
source $proj/tech/tech_setup.tcl

# ---- Library Setup ----
source $proj/lib/lib_setup.tcl

# ---- Timing Library (NDM) ----
set_lib_cell_purpose -include {hold setup ccd} [get_lib_cells */BUFFD*]
set_lib_cell_purpose -include {hold setup ccd} [get_lib_cells */INVD*]
set_lib_cell_purpose -include {cts}            [get_lib_cells */CKBD*]
set_lib_cell_purpose -include {cts}            [get_lib_cells */CKINVD*]

# ---- MCMM Scenario Setup ----
# Remove default mode/corner
remove_modes -all
remove_corners -all
remove_scenarios -all

# Create corners
foreach corner_name {
    tt_0p85v_25c ss_0p75v_125c ff_0p95v_m40c
    ss_0p75v_m40c ff_0p95v_0c tt_0p85v_85c
} {
    create_corner $corner_name
    set_parasitic_parameters -early_spec ${corner_name}_cbest \
                             -late_spec  ${corner_name}_cworst \
                             -corner     [get_corners $corner_name]
}

# Create modes
create_mode func_mode
create_mode scan_mode

# Create scenarios (mode x corner)
set corner_list {tt_0p85v_25c ss_0p75v_125c ff_0p95v_m40c ss_0p75v_m40c ff_0p95v_0c tt_0p85v_85c}
foreach c $corner_list {
    create_scenario func_${c}
    current_scenario func_${c}
    set_mode func_mode
    set_corner $c
    source $proj/constraints/mcmm/func_${c}.sdc
    set_scenario_options -setup true -hold true -leakage_power true -dynamic_power true
}

create_scenario scan_ss_0p75v_125c
current_scenario scan_ss_0p75v_125c
set_mode scan_mode
set_corner ss_0p75v_125c
source $proj/constraints/mcmm/scan_ss_0p75v_125c.sdc

# ---- Enable all scenarios ----
set_scenario_options -scenarios [get_scenarios] -setup true -hold true

# ---- NDR Rules ----
# Core-to-L2 clock tree: 2x width, 2x spacing
create_routing_rule CLK_2X_NDR \
    -multiplier_spacing 2 \
    -multiplier_width   2 \
    -cuts {via_class_default}

create_clock_routing_rules CLK_NDR_RULE \
    -layers {M4 M5 M6} \
    -routing_rule CLK_2X_NDR

# Power mesh shielding for clocks
set_routing_options -signal_net_shielding true

puts "ICC2 setup complete: [llength [get_scenarios]] scenarios configured"
