
# calibre_erc.tcl - Mentor Calibre ERC
set proj /u/saicha/industry_chip_rtl2gds
exec calibre -erc -turbo 8 \
    -i $proj/output/soc_top.gds.gz -topcell soc_top \
    -runset $proj/tech/saed32nm_calibre_erc.rule
