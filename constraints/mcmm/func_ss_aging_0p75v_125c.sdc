
# ============================================================
# func_ss_aging_0p75v_125c.sdc
# Scenario: func  Voltage: 0.75V  Temp: 125C
# ============================================================

# ---- Clock Definitions ----

create_clock -name refclk_25m -period 50.000 [get_ports refclk_25m] 
create_clock -name clk_core_0 -period 1.250 [get_ports clk_core_0] 
create_clock -name clk_core_1 -period 1.250 [get_ports clk_core_1] 
create_clock -name clk_l2 -period 2.500 [get_ports clk_l2] 
create_clock -name clk_l3 -period 5.000 [get_ports clk_l3] 
create_clock -name clk_noc -period 2.500 [get_ports clk_noc] 
create_clock -name clk_gpu -period 1.562 [get_ports clk_gpu] 
create_clock -name clk_pcie -period 5.000 [get_ports clk_pcie] 
create_clock -name clk_usb -period 20.834 [get_ports clk_usb] 
create_clock -name clk_eth -period 10.000 [get_ports clk_eth] 
create_clock -name clk_dma -period 5.000 [get_ports clk_dma] 
create_clock -name clk_crypto -period 3.125 [get_ports clk_crypto] 
create_clock -name clk_io -period 12.500 [get_ports clk_io] 
create_clock -name clk_mem -period 6.250 [get_ports clk_mem] 
create_clock -name clk_periph -period 25.000 [get_ports clk_periph] 
create_clock -name clk_debug -period 50.000 [get_ports clk_debug] 

# ---- Clock Uncertainty ----
set_clock_uncertainty 0.200 [all_clocks]

# ---- Generated Clocks ----
# These are defined in generated_clocks.sdc; source it here:
# source [file join $env(PROJ_ROOT) constraints/clocks/generated_clocks.sdc]

# ---- Input/Output Delays ----
set_input_delay  -clock refclk_25m -max [expr 50.0 * 0.4] [all_inputs]
set_input_delay  -clock refclk_25m -min [expr 50.0 * 0.1] [all_inputs]
set_output_delay -clock refclk_25m -max [expr 50.0 * 0.4] [all_outputs]
set_output_delay -clock refclk_25m -min 0.0 [all_outputs]

# ---- Drive Strength ----
set_driving_cell -lib_cell BUFFD4BWP28NM [all_inputs]

# ---- Load ----
set_load 0.05 [all_outputs]

# ---- Timing Derate (OCV) ----
set_timing_derate -early 0.95
set_timing_derate -late  1.05

# ---- Operating Conditions ----
set_operating_conditions -analysis_type bc_wc
