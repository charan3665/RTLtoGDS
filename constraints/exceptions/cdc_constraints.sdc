
# ============================================================
# cdc_constraints.sdc - CDC-specific constraints
# ============================================================

# ---- Mark all CDC synchronizer cells ----
# Prevent optimization from merging/removing sync stages
set_dont_touch [get_cells -hierarchical -filter "ref_name =~ *cdc_sync_2ff*"]
set_dont_touch [get_cells -hierarchical -filter "ref_name =~ *cdc_reset_sync*"]

# ---- CDC gray FIFO pointer paths ----
# Gray-coded pointers: only one bit changes at a time - safe to capture
set_max_delay -datapath_only 2.0 \
    -from [get_cells -hierarchical -filter "ref_name =~ *cdc_gray_fifo*/wr_ptr_reg*"] \
    -to   [get_cells -hierarchical -filter "ref_name =~ *cdc_gray_fifo*/sync_wr*"]

set_max_delay -datapath_only 2.0 \
    -from [get_cells -hierarchical -filter "ref_name =~ *cdc_gray_fifo*/rd_ptr_reg*"] \
    -to   [get_cells -hierarchical -filter "ref_name =~ *cdc_gray_fifo*/sync_rd*"]

# ---- Clock domain crossing buses (through handshake) ----
# These paths are false in timing analysis (handshake ensures stability)
set_false_path -through [get_pins -hierarchical -filter "name =~ *cdc_handshake*/data_latch*"]

# ---- Pulse synchronizer: source toggle ----
set_max_delay -datapath_only 1.5 \
    -from [get_pins -hierarchical -filter "name =~ *cdc_pulse_sync*/toggle_reg*"] \
    -to   [get_pins -hierarchical -filter "name =~ *cdc_pulse_sync*/u_sync/stage1*"]

# ---- Isolation cells: treat as constants during CDC analysis ----
set_case_analysis 1 [get_pins -hierarchical -filter "name =~ *isolation_cell*/ISO_EN"]
