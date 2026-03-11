
# ============================================================
# innovus_mmmc.tcl - Multi-Mode Multi-Corner (MMMC) View Setup
# 12+ Corners, Functional + Scan Modes
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

# ============================================================
# Library Sets (per-corner timing libraries)
# ============================================================

# -- SS 0.75V -40C --
create_library_set -name ls_ss_0p75v_m40c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ss0p75vm40c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ss0p75vm40c.lib \
        ${sram_dir}/sram_sp_256x64_ss0p75vm40c.lib \
        ${sram_dir}/sram_sp_512x128_ss0p75vm40c.lib \
        ${sram_dir}/sram_sp_1024x64_ss0p75vm40c.lib \
        ${sram_dir}/sram_sp_2048x32_ss0p75vm40c.lib \
        ${sram_dir}/sram_sp_4096x64_ss0p75vm40c.lib \
        ${sram_dir}/sram_dp_256x64_ss0p75vm40c.lib \
        ${sram_dir}/sram_dp_512x128_ss0p75vm40c.lib \
    ]

# -- SS 0.75V 125C --
create_library_set -name ls_ss_0p75v_125c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ss0p75v125c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ss0p75v125c.lib \
        ${sram_dir}/sram_sp_256x64_ss0p75v125c.lib \
        ${sram_dir}/sram_sp_512x128_ss0p75v125c.lib \
        ${sram_dir}/sram_sp_1024x64_ss0p75v125c.lib \
        ${sram_dir}/sram_sp_2048x32_ss0p75v125c.lib \
        ${sram_dir}/sram_sp_4096x64_ss0p75v125c.lib \
        ${sram_dir}/sram_dp_256x64_ss0p75v125c.lib \
        ${sram_dir}/sram_dp_512x128_ss0p75v125c.lib \
    ]

# -- TT 0.85V 25C --
create_library_set -name ls_tt_0p85v_25c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_tt0p85v25c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_tt0p85v25c.lib \
        ${sram_dir}/sram_sp_256x64_tt0p85v25c.lib \
        ${sram_dir}/sram_sp_512x128_tt0p85v25c.lib \
        ${sram_dir}/sram_sp_1024x64_tt0p85v25c.lib \
        ${sram_dir}/sram_sp_2048x32_tt0p85v25c.lib \
        ${sram_dir}/sram_sp_4096x64_tt0p85v25c.lib \
        ${sram_dir}/sram_dp_256x64_tt0p85v25c.lib \
        ${sram_dir}/sram_dp_512x128_tt0p85v25c.lib \
    ]

# -- TT 0.85V 85C --
create_library_set -name ls_tt_0p85v_85c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_tt0p85v85c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_tt0p85v85c.lib \
        ${sram_dir}/sram_sp_256x64_tt0p85v85c.lib \
        ${sram_dir}/sram_sp_512x128_tt0p85v85c.lib \
        ${sram_dir}/sram_sp_1024x64_tt0p85v85c.lib \
        ${sram_dir}/sram_sp_2048x32_tt0p85v85c.lib \
        ${sram_dir}/sram_sp_4096x64_tt0p85v85c.lib \
        ${sram_dir}/sram_dp_256x64_tt0p85v85c.lib \
        ${sram_dir}/sram_dp_512x128_tt0p85v85c.lib \
    ]

# -- FF 0.95V -40C --
create_library_set -name ls_ff_0p95v_m40c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ff0p95vm40c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ff0p95vm40c.lib \
        ${sram_dir}/sram_sp_256x64_ff0p95vm40c.lib \
        ${sram_dir}/sram_sp_512x128_ff0p95vm40c.lib \
        ${sram_dir}/sram_sp_1024x64_ff0p95vm40c.lib \
        ${sram_dir}/sram_sp_2048x32_ff0p95vm40c.lib \
        ${sram_dir}/sram_sp_4096x64_ff0p95vm40c.lib \
        ${sram_dir}/sram_dp_256x64_ff0p95vm40c.lib \
        ${sram_dir}/sram_dp_512x128_ff0p95vm40c.lib \
    ]

# -- FF 0.95V 0C --
create_library_set -name ls_ff_0p95v_0c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ff0p95v0c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ff0p95v0c.lib \
        ${sram_dir}/sram_sp_256x64_ff0p95v0c.lib \
        ${sram_dir}/sram_sp_512x128_ff0p95v0c.lib \
        ${sram_dir}/sram_sp_1024x64_ff0p95v0c.lib \
        ${sram_dir}/sram_sp_2048x32_ff0p95v0c.lib \
        ${sram_dir}/sram_sp_4096x64_ff0p95v0c.lib \
        ${sram_dir}/sram_dp_256x64_ff0p95v0c.lib \
        ${sram_dir}/sram_dp_512x128_ff0p95v0c.lib \
    ]

# -- SS Aging 0.75V 125C (HCI/NBTI degraded) --
create_library_set -name ls_ss_aging_0p75v_125c \
    -timing [list \
        ${lib_dir}/lib/stdcell_hvt/nldm/saed28hvt_ss_aging_0p75v125c.lib \
        ${lib_dir}/lib/stdcell_lvt/nldm/saed28lvt_ss_aging_0p75v125c.lib \
    ]

# ============================================================
# RC Corners (parasitic extraction technology)
# ============================================================
create_rc_corner -name rc_typical \
    -qrc_tech ${qrc_dir}/saed28nm_1p9m_Ctypical.tch \
    -temperature 25

create_rc_corner -name rc_cmax \
    -qrc_tech ${qrc_dir}/saed28nm_1p9m_Cmax.tch \
    -temperature 125

create_rc_corner -name rc_cmin \
    -qrc_tech ${qrc_dir}/saed28nm_1p9m_Cmin.tch \
    -temperature -40

create_rc_corner -name rc_cmax_125c \
    -qrc_tech ${qrc_dir}/saed28nm_1p9m_Cmax.tch \
    -temperature 125

create_rc_corner -name rc_cmin_m40c \
    -qrc_tech ${qrc_dir}/saed28nm_1p9m_Cmin.tch \
    -temperature -40

# ============================================================
# Delay Corners (library_set + rc_corner)
# ============================================================
create_delay_corner -name dc_func_tt_25c       -library_set ls_tt_0p85v_25c      -rc_corner rc_typical
create_delay_corner -name dc_func_ss_m40c      -library_set ls_ss_0p75v_m40c     -rc_corner rc_cmin_m40c
create_delay_corner -name dc_func_ss_125c      -library_set ls_ss_0p75v_125c     -rc_corner rc_cmax_125c
create_delay_corner -name dc_func_ff_m40c      -library_set ls_ff_0p95v_m40c     -rc_corner rc_cmin_m40c
create_delay_corner -name dc_func_ff_0c        -library_set ls_ff_0p95v_0c       -rc_corner rc_cmin
create_delay_corner -name dc_func_tt_85c       -library_set ls_tt_0p85v_85c      -rc_corner rc_typical
create_delay_corner -name dc_func_ss_125c_cmax -library_set ls_ss_0p75v_125c     -rc_corner rc_cmax
create_delay_corner -name dc_func_tt_25c_cmin  -library_set ls_tt_0p85v_25c      -rc_corner rc_cmin
create_delay_corner -name dc_func_tt_85c_cmax  -library_set ls_tt_0p85v_85c      -rc_corner rc_cmax
create_delay_corner -name dc_func_ss_aging     -library_set ls_ss_aging_0p75v_125c -rc_corner rc_cmax_125c
create_delay_corner -name dc_scan_ss_125c      -library_set ls_ss_0p75v_125c     -rc_corner rc_cmax_125c
create_delay_corner -name dc_scan_ff_m40c      -library_set ls_ff_0p95v_m40c     -rc_corner rc_cmin_m40c

# ============================================================
# Constraint Modes (SDC per mode)
# ============================================================
create_constraint_mode -name cm_func \
    -sdc_files [list \
        $proj/constraints/mcmm/func_tt_0p85v_25c.sdc \
        $proj/constraints/clocks/generated_clocks.sdc \
        $proj/constraints/clocks/clock_groups.sdc \
        $proj/constraints/clocks/clock_latency.sdc \
        $proj/constraints/exceptions/false_paths.sdc \
        $proj/constraints/exceptions/multicycle_paths.sdc \
        $proj/constraints/exceptions/max_delay.sdc \
        $proj/constraints/exceptions/case_analysis.sdc \
        $proj/constraints/exceptions/cdc_constraints.sdc \
    ]

create_constraint_mode -name cm_scan \
    -sdc_files [list \
        $proj/constraints/mcmm/scan_ss_0p75v_125c.sdc \
        $proj/constraints/clocks/generated_clocks.sdc \
        $proj/constraints/exceptions/false_paths.sdc \
    ]

# ============================================================
# Analysis Views (delay_corner + constraint_mode)
# ============================================================
create_analysis_view -name av_func_tt_25c       -delay_corner dc_func_tt_25c       -constraint_mode cm_func
create_analysis_view -name av_func_ss_m40c      -delay_corner dc_func_ss_m40c      -constraint_mode cm_func
create_analysis_view -name av_func_ss_125c      -delay_corner dc_func_ss_125c      -constraint_mode cm_func
create_analysis_view -name av_func_ff_m40c      -delay_corner dc_func_ff_m40c      -constraint_mode cm_func
create_analysis_view -name av_func_ff_0c        -delay_corner dc_func_ff_0c        -constraint_mode cm_func
create_analysis_view -name av_func_tt_85c       -delay_corner dc_func_tt_85c       -constraint_mode cm_func
create_analysis_view -name av_func_ss_125c_cmax -delay_corner dc_func_ss_125c_cmax -constraint_mode cm_func
create_analysis_view -name av_func_tt_25c_cmin  -delay_corner dc_func_tt_25c_cmin  -constraint_mode cm_func
create_analysis_view -name av_func_tt_85c_cmax  -delay_corner dc_func_tt_85c_cmax  -constraint_mode cm_func
create_analysis_view -name av_func_ss_aging     -delay_corner dc_func_ss_aging     -constraint_mode cm_func
create_analysis_view -name av_scan_ss_125c      -delay_corner dc_scan_ss_125c      -constraint_mode cm_scan
create_analysis_view -name av_scan_ff_m40c      -delay_corner dc_scan_ff_m40c      -constraint_mode cm_scan

# ============================================================
# Set Active Views
# ============================================================
set_analysis_view \
    -setup [list \
        av_func_ss_125c \
        av_func_ss_m40c \
        av_func_ss_125c_cmax \
        av_func_ss_aging \
        av_func_tt_85c_cmax \
        av_scan_ss_125c \
    ] \
    -hold [list \
        av_func_ff_m40c \
        av_func_ff_0c \
        av_func_tt_25c_cmin \
        av_func_tt_25c \
        av_scan_ff_m40c \
    ]

puts "MMMC: 12 analysis views configured (6 setup, 5 hold)"
