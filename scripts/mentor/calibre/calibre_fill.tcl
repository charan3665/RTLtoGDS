
# calibre_fill.tcl - Calibre Metal/Dummy Fill
set proj /u/saicha/industry_chip_rtl2gds
exec calibre -drc -runset $proj/tech/saed32nm_fill.rule \
    -i $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -runset_variable METAL_FILL yes \
    -o $proj/output/soc_top_filled.gds.gz
