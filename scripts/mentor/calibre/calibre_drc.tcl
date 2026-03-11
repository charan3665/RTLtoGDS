
# ============================================================
# calibre_drc.tcl - Mentor Calibre DRC
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

set calibre_cmd calibre

exec $calibre_cmd -drc \
    -hier \
    -turbo 32 \
    -i $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -runset $proj/tech/saed32nm_calibre_drc.rule \
    -hier_license 32

set drc_sum $proj/reports/calibre_drc.sum
if {[file exists $drc_sum]} {
    set f [open $drc_sum r]
    puts [read $f]
    close $f
}
