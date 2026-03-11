
# ============================================================
# pt_power.tcl - Power Analysis with Switching Activity
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

source $proj/scripts/synopsys/pt/pt_setup.tcl

# ---- Read switching activity (from simulation VCD) ----
read_saif \
    -input $proj/work/sim/soc_top_func.saif \
    -instance soc_top_tb/u_soc

# ---- Or use toggle rate estimation ----
set_switching_activity -static_probability 0.5 -toggle_rate 0.25 \
    -base_clock clk_core_0 [all_registers]

# ---- Power Analysis ----
update_power

# ---- Leakage Power ----
report_power \
    -nosplit \
    -analysis_effort high \
    -file $proj/reports/power_total.rpt

# ---- Hierarchical Power ----
report_power \
    -hierarchy all \
    -file $proj/reports/power_hier.rpt

# ---- Cell-level Power ----
report_power \
    -cell_power_threshold 1e-6 \
    -file $proj/reports/power_cells.rpt

# ---- Power Domain Breakdown ----
foreach pd {PD_CPU0 PD_CPU1 PD_GPU PD_MEM PD_IO PD_PERIPH PD_CRYPTO PD_PCIE PD_USB PD_ETH} {
    report_power -power_domain $pd -file $proj/reports/power_${pd}.rpt
}

puts "Power analysis complete"
