
# ============================================================
# run_em_analysis.tcl - Electromigration Analysis
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

redhawk -em \
    -technology $proj/tech/saed32nm_em.ict \
    -gds $proj/output/soc_top.gds.gz \
    -def $proj/output/soc_top.def.gz \
    -spef $proj/output/soc_top_tt_0p85v_25c.spef.gz \
    -saif $proj/work/sim/soc_top_func.saif \
    -temperature 125 \
    -lifetime 100000 \
    -output_directory $proj/reports/em_analysis

report_em_violations \
    -output $proj/reports/em_analysis/em_violations.rpt \
    -threshold 1.2

puts "EM analysis complete. Violations in: $proj/reports/em_analysis/em_violations.rpt"
