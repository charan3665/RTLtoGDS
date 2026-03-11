
# ============================================================
# func_ff_0p95v_m40c.sdc
# Scenario: func  Voltage: 0.95V  Temp: -40C
# ============================================================

# ---- Clock Definitions ----

create_clock -name refclk_25m -period 34.000 [get_ports refclk_25m] 
create_clock -name clk_core_0 -period 0.850 [get_ports clk_core_0] 
create_clock -name clk_core_1 -period 0.850 [get_ports clk_core_1] 
create_clock -name clk_l2 -period 1.700 [get_ports clk_l2] 
create_clock -name clk_l3 -period 3.400 [get_ports clk_l3] 
create_clock -name clk_noc -period 1.700 [get_ports clk_noc] 
create_clock -name clk_gpu -period 1.062 [get_ports clk_gpu] 
create_clock -name clk_pcie -period 3.400 [get_ports clk_pcie] 
create_clock -name clk_usb -period 14.167 [get_ports clk_usb] 
create_clock -name clk_eth -period 6.800 [get_ports clk_eth] 
create_clock -name clk_dma -period 3.400 [get_ports clk_dma] 
create_clock -name clk_crypto -period 2.125 [get_ports clk_crypto] 
create_clock -name clk_io -period 8.500 [get_ports clk_io] 
create_clock -name clk_mem -period 4.250 [get_ports clk_mem] 
create_clock -name clk_periph -period 17.000 [get_ports clk_periph] 
create_clock -name clk_debug -period 34.000 [get_ports clk_debug] 

# ---- Clock Uncertainty ----
set_clock_uncertainty 0.050 [all_clocks]

# ---- Generated Clocks ----
# These are defined in generated_clocks.sdc; source it here:
# source [file join $env(PROJ_ROOT) constraints/clocks/generated_clocks.sdc]

# ---- Input/Output Delays ----
set_input_delay  -clock refclk_25m -max [expr 34.0 * 0.4] [all_inputs]
set_input_delay  -clock refclk_25m -min [expr 34.0 * 0.1] [all_inputs]
set_output_delay -clock refclk_25m -max [expr 34.0 * 0.4] [all_outputs]
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
