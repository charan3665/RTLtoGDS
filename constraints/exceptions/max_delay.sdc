
# ============================================================
# max_delay.sdc - Max Delay Constraints (inter-domain)
# ============================================================

# ---- CDC synchronizer input paths ----
# Paths INTO 2-FF synchronizer first stage must meet half-cycle capture
set_max_delay 0.8 -datapath_only \
    -to [get_pins -hierarchical -filter "name =~ *stage1*" -of_objects [get_cells -hierarchical -filter "ref_name =~ *cdc_sync*"]]

set_max_delay 0.8 -datapath_only \
    -to [get_pins -hierarchical -filter "name =~ *q0a*"]

set_max_delay 0.8 -datapath_only \
    -to [get_pins -hierarchical -filter "name =~ *q1a*"]

# ---- Gray code pointer paths in async FIFO ----
set_max_delay 1.5 -datapath_only \
    -from [get_pins -hierarchical -filter "name =~ *wr_ptr*"] \
    -to   [get_pins -hierarchical -filter "name =~ *sync_chain*"]

set_max_delay 1.5 -datapath_only \
    -from [get_pins -hierarchical -filter "name =~ *rd_ptr*"] \
    -to   [get_pins -hierarchical -filter "name =~ *sync_chain*"]

# ---- Retention flop save paths (can be slow) ----
set_max_delay 5.0 -from [get_pins -hierarchical -filter "name =~ *RET*"] \
    -to [get_pins -hierarchical -filter "name =~ *shadow*"]

# ---- Level shifter inputs ----
set_max_delay 2.0 -to [get_cells -hierarchical -filter "ref_name =~ *level_shift*"]
