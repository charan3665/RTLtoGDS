
# ============================================================
# dont_use.tcl - Cells Excluded from Synthesis/Optimization
# ============================================================

# ---- High-drive strength cells (use only where needed) ----
set_dont_use [get_lib_cells */BUFFD32*]
set_dont_use [get_lib_cells */BUFFD24*]
set_dont_use [get_lib_cells */INVD32*]
set_dont_use [get_lib_cells */INVD24*]

# ---- Scan-specific cells (not for synthesis) ----
set_dont_use [get_lib_cells */SDFFX*]

# ---- Level-shifting cells (inserted by UPF flow only) ----
set_dont_use [get_lib_cells */LSUPD*]
set_dont_use [get_lib_cells */LSDND*]

# ---- Retention flops (inserted by UPF flow only) ----
set_dont_use [get_lib_cells */RDFQX*]

# ---- Decap cells (inserted by chip finishing only) ----
set_dont_use [get_lib_cells */DCAP*]

# ---- Tie cells (inserted manually) ----
set_dont_use [get_lib_cells */TIEHI*]
set_dont_use [get_lib_cells */TIELO*]

# ---- Physical-only cells ----
set_dont_use [get_lib_cells */FILL*]
set_dont_use [get_lib_cells */ENDCAP*]
set_dont_use [get_lib_cells */TAPCELL*]

puts "Dont-use list applied: [llength [get_lib_cells -filter dont_use==true]] cells"
