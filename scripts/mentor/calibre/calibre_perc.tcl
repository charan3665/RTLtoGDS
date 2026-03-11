
# calibre_perc.tcl - Calibre PERC (Power/ESD/Latch-up)
set proj /u/saicha/industry_chip_rtl2gds
exec calibre -perc -turbo 16 \
    -i $proj/output/soc_top.gds.gz \
    -topcell soc_top \
    -netlist $proj/output/soc_top_lvs.cdl \
    -runset $proj/tech/saed32nm_calibre_perc.rule \
    -power {VDD VDD_CPU0 VDD_CPU1 VDD_GPU VDD_MEM VDD_IO VDD_CRYPTO} \
    -gnd   {VSS}
