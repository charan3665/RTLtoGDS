
# ============================================================
# multicycle_paths.sdc - Multi-Cycle Path Constraints
# ============================================================

# ---- CPU core to L2 cache (2-cycle path allowed) ----
# L2 operates at half the frequency of core; 2-cycle in core clock domain
set_multicycle_path 2 -setup -from [get_clocks clk_core_0] -to [get_clocks clk_l2]
set_multicycle_path 1 -hold  -from [get_clocks clk_core_0] -to [get_clocks clk_l2]
set_multicycle_path 2 -setup -from [get_clocks clk_core_1] -to [get_clocks clk_l2]
set_multicycle_path 1 -hold  -from [get_clocks clk_core_1] -to [get_clocks clk_l2]

# ---- L3 cache access (4-cycle in L2 clock) ----
set_multicycle_path 2 -setup -from [get_clocks clk_l2] -to [get_clocks clk_l3]
set_multicycle_path 1 -hold  -from [get_clocks clk_l2] -to [get_clocks clk_l3]

# ---- APB peripheral accesses (slow peripherals, 4-cycle) ----
set_multicycle_path 4 -setup -from [get_clocks clk_io] -to [get_clocks clk_periph]
set_multicycle_path 3 -hold  -from [get_clocks clk_io] -to [get_clocks clk_periph]

# ---- Crypto engine (deep pipeline, allow 3-cycle) ----
set_multicycle_path 3 -setup -through [get_pins u_crypto/u_aes/*]
set_multicycle_path 2 -hold  -through [get_pins u_crypto/u_aes/*]

# ---- SHA-256 round operations (allow 2-cycle) ----
set_multicycle_path 2 -setup -through [get_pins u_crypto/u_sha/*]
set_multicycle_path 1 -hold  -through [get_pins u_crypto/u_sha/*]

# ---- DMA descriptor table reads ----
set_multicycle_path 2 -setup -to [get_pins -hierarchical -filter "name =~ *dma_descriptor*"]
set_multicycle_path 1 -hold  -to [get_pins -hierarchical -filter "name =~ *dma_descriptor*"]

# ---- Register file outputs (6R3W, 10R6W - allow 2 cycles) ----
set_multicycle_path 2 -setup -from [get_cells -hierarchical -filter "name =~ *regfile*"]
set_multicycle_path 1 -hold  -from [get_cells -hierarchical -filter "name =~ *regfile*"]

# ---- NoC router pipeline (2-cycle) ----
set_multicycle_path 2 -setup -through [get_pins -hierarchical -filter "full_name =~ *noc_router*"]
set_multicycle_path 1 -hold  -through [get_pins -hierarchical -filter "full_name =~ *noc_router*"]
