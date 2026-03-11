
# ============================================================
# icv_erc.tcl - IC Validator Electrical Rule Check
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

icv -gds $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -runset $proj/tech/saed32nm_erc.rs \
    -erc \
    -output_directory $proj/reports/icv_erc \
    -jobs 16

report_erc -output $proj/reports/erc_summary.rpt
