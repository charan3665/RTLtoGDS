
# ============================================================
# clock_latency.sdc - Clock Source and Network Latency
# ============================================================

# Clock source latency (from PLL output to design boundary)
set_clock_latency -source 0.100 [get_clocks clk_core_0]
set_clock_latency -source 0.100 [get_clocks clk_core_1]
set_clock_latency -source 0.150 [get_clocks clk_l2]
set_clock_latency -source 0.200 [get_clocks clk_l3]
set_clock_latency -source 0.150 [get_clocks clk_noc]
set_clock_latency -source 0.120 [get_clocks clk_gpu]
set_clock_latency -source 0.300 [get_clocks clk_pcie]
set_clock_latency -source 0.400 [get_clocks clk_usb]
set_clock_latency -source 0.250 [get_clocks clk_eth]
set_clock_latency -source 0.200 [get_clocks clk_dma]
set_clock_latency -source 0.150 [get_clocks clk_crypto]
set_clock_latency -source 0.200 [get_clocks clk_io]
set_clock_latency -source 0.200 [get_clocks clk_mem]
set_clock_latency -source 0.300 [get_clocks clk_periph]
set_clock_latency -source 0.500 [get_clocks clk_debug]

# Pre-CTS clock network latency estimates (post-CTS: use actual)
set_clock_latency 0.200 [get_clocks clk_core_0]
set_clock_latency 0.200 [get_clocks clk_core_1]
set_clock_latency 0.300 [get_clocks clk_l2]
set_clock_latency 0.400 [get_clocks clk_l3]
set_clock_latency 0.350 [get_clocks clk_noc]
set_clock_latency 0.250 [get_clocks clk_gpu]

# Clock transition times
set_clock_transition 0.050 [get_clocks clk_core_0]
set_clock_transition 0.050 [get_clocks clk_core_1]
set_clock_transition 0.080 [get_clocks clk_l2]
set_clock_transition 0.100 [get_clocks clk_l3]
set_clock_transition 0.100 [get_clocks {clk_noc clk_gpu clk_dma clk_crypto clk_mem}]
set_clock_transition 0.150 [get_clocks {clk_io clk_periph clk_debug clk_usb clk_eth clk_pcie}]
