
# ============================================================
# dc_compile.tcl - Synthesis Compile
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds
source $proj/scripts/synopsys/dc/dc_read_design.tcl
source $proj/scripts/synopsys/dc/dc_constraints.tcl

# ---- Compile ----
compile_ultra \
    -no_autoungroup \
    -no_seq_output_inversion \
    -gate_clock \
    -retime \
    -incremental

# ---- Write netlist ----
write -format verilog -output $proj/work/syn_out/soc_top_mapped.v -hierarchy

# ---- Write SDC ----
write_sdc $proj/work/syn_out/soc_top_mapped.sdc

# ---- Write SPEF Constraints ----
write_parasitics -format sdf -output $proj/work/syn_out/soc_top.sdf

puts "Synthesis complete"
