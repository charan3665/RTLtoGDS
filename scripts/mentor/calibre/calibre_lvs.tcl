
# ============================================================
# calibre_lvs.tcl - Mentor Calibre LVS
# ============================================================
set proj /u/saicha/industry_chip_rtl2gds

exec calibre -lvs \
    -hier \
    -turbo 16 \
    -i $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -spice $proj/output/soc_top_lvs.cdl \
    -runset $proj/tech/saed32nm_calibre_lvs.rule

# Check LVS result
set lvs_sum $proj/reports/calibre_lvs.rep
puts "LVS result in: $lvs_sum"
