# Industry-Grade SoC RTL-to-GDSII Full Flow

## Overview

This repository contains a complete, industry-grade SoC design flow for a 28nm RISC-V-based System-on-Chip (SoC). The project covers the full RTL-to-GDSII implementation from architecture through physical signoff.

### Chip Specifications
- **Process**: SAED32 28nm CMOS
- **Die Area**: 7mm × 7mm (49mm²)
- **Core Utilization**: ~70%
- **CPU**: Dual-core Out-of-Order RISC-V RV64IMAFDC (OoO, 4-wide issue)
- **Cache**: 32KB L1I/D (per core), 512KB L2, 16MB L3 (4-slice)
- **GPU**: 4-SM SIMT GPU with shader, rasterizer, texture pipeline
- **Interconnect**: 8×8 AXI4 crossbar, 4×4 mesh NoC
- **Memory**: 7 SRAM configurations, dual-port register files
- **Peripherals**: PCIe Gen4×4, USB 2.0, GbE, UART, SPI, I2C, GPIO, Timer, WDT, PWM
- **Security**: Secure boot, firewall, PMP, AES/SHA-256/TRNG
- **Power**: 11 power domains, DVFS (0.75V–0.95V), retention, clock gating
- **Clocks**: 15+ clock domains (1GHz CPU → 25MHz debug), DFS

---

## Directory Structure

```
industry_chip_rtl2gds_full_flow/
├── rtl/                    # RTL source files (~160 Verilog modules)
│   ├── cpu/               # Dual-core OoO RISC-V (core0, core1, MMU/TLB)
│   ├── cache/             # L1I, L1D, L2, L3, coherence
│   ├── memory/            # SRAM macros, register files, ROM
│   ├── interconnect/      # AXI4 crossbar, NoC, APB, AHB bridges
│   ├── gpu/               # Shader, rasterizer, texture pipeline
│   ├── dma/               # 8-channel DMA controller
│   ├── crypto/            # AES-256, SHA-256, TRNG, PKA
│   ├── pcie/              # PCIe Gen4 x4 controller
│   ├── usb/               # USB 2.0 controller
│   ├── ethernet/          # GbE MAC+PHY interface
│   ├── peripherals/       # UART, SPI, I2C, GPIO, Timer, WDT, PWM
│   ├── clock/             # PLL, DFS, ICG cells, clock gen top
│   ├── power/             # Power switches, retention, isolation, DVFS
│   ├── debug/             # JTAG TAP, Debug Module, DTM, trace
│   ├── cdc/               # CDC synchronizers (2FF, gray FIFO, handshake)
│   ├── reset/             # POR, reset controller, sync
│   ├── security/          # Secure boot, firewall, PMP, key store
│   └── top/               # soc_top.v (integration of all blocks)
├── constraints/
│   ├── mcmm/             # 12 SDC corner files (TT/SS/FF, -40C to 125C)
│   ├── clocks/           # Generated clocks, clock groups, latency
│   └── exceptions/       # False paths, MCPs, max delay, CDC, case
├── upf/
│   └── soc_top.upf       # UPF 2.1: 11 power domains, DVFS, retention
├── floorplan/
│   ├── floorplan.tcl     # Die/core setup, macro/SRAM placement, PG grid
│   ├── macro_placement.tcl
│   ├── sram_placement.tcl
│   ├── pin_placement.tcl
│   ├── power_grid.tcl    # Multi-domain PG mesh (M5–M9)
│   └── keepout.tcl       # Voltage area, blockages, keepout margins
├── scripts/
│   ├── synopsys/
│   │   ├── icc2/        # ICC2 hierarchical flow (11 scripts)
│   │   ├── pt/          # PrimeTime MCMM + SI + DMSA (7 scripts)
│   │   ├── dc/          # Design Compiler synthesis (5 scripts)
│   │   ├── starrc/      # StarRC parasitic extraction (2 scripts)
│   │   ├── icv/         # IC Validator DRC/LVS/ERC/Antenna/Density
│   │   └── ansys/       # RedHawk IR/EM/thermal (4 scripts)
│   ├── mentor/calibre/  # Calibre DRC/LVS/ERC/PERC/Fill (5 scripts)
│   └── dmsa/            # Distributed multi-scenario analysis (4 scripts)
├── testbench/
│   └── tb_soc_top.v     # Comprehensive testbench with all clock domains
├── lib/
│   ├── lib_setup.tcl    # SAED32 28nm library paths
│   └── dont_use.tcl     # Excluded cells list
├── tech/
│   └── tech_setup.tcl   # Technology file, routing layers, DRC rulesets
└── doc/
    ├── README.md        # This file
    └── module_list.txt  # All ~160 RTL modules
```

---

## Implementation Flow

### 1. RTL Synthesis (Design Compiler)
```bash
dc_shell-xg-t -f scripts/synopsys/dc/dc_compile.tcl
```

### 2. Physical Implementation (ICC2)
```bash
icc2_shell -f scripts/synopsys/icc2/icc2_import.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_floorplan.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_place_opt.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_cts.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_route.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_route_opt.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_chip_finish.tcl
icc2_shell -f scripts/synopsys/icc2/icc2_signoff.tcl
```

### 3. Parasitic Extraction (StarRC)
```bash
StarXtract -cmd scripts/synopsys/starrc/starrc_extract.tcl
```

### 4. Timing Signoff (PrimeTime MCMM + DMSA)
```bash
pt_shell -f scripts/synopsys/pt/pt_mcmm.tcl
pt_shell -f scripts/synopsys/pt/pt_sta.tcl
pt_shell -f scripts/synopsys/pt/pt_si.tcl
# Run DMSA in parallel:
tcsh scripts/dmsa/dmsa_run.tcl
```

### 5. Physical Verification
```bash
# DRC (ICV or Calibre)
icv_shell -f scripts/synopsys/icv/icv_drc.tcl
calibre -drc -runset scripts/mentor/calibre/calibre_drc.tcl

# LVS
icv_shell -f scripts/synopsys/icv/icv_lvs.tcl

# Power Integrity
redhawk -f scripts/synopsys/ansys/run_ir_drop.tcl
```

---

## Clock Architecture

| Domain | Frequency | Source | Use |
|--------|-----------|--------|-----|
| clk_core_0/1 | 1 GHz | PLL ÷1 | CPU cores |
| clk_l2 | 500 MHz | PLL ÷2 | L2 cache |
| clk_l3 | 250 MHz | PLL ÷4 | L3 / NoC |
| clk_noc | 500 MHz | PLL ÷2 | NoC fabric |
| clk_gpu | 800 MHz | PLL ÷2 (2nd) | GPU SMs |
| clk_pcie | 250 MHz | PLL ÷4 | PCIe TL/DL |
| clk_usb | 60 MHz | PLL ÷16 | USB SIE |
| clk_eth | 125 MHz | PLL ÷8 | GbE MAC |
| clk_dma | 250 MHz | PLL ÷4 | DMA engine |
| clk_crypto | 400 MHz | PLL ÷2.5 | AES/SHA |
| clk_io | 100 MHz | PLL ÷10 | IO ring |
| clk_mem | 200 MHz | PLL ÷5 | LPDDR ctrl |
| clk_periph | 50 MHz | PLL ÷20 | APB peripherals |
| clk_debug | 25 MHz | PLL ÷40 | JTAG debug |
| tck | <25 MHz | External | JTAG TAP |

---

## Power Domains

| Domain | Block | Nominal V | Modes |
|--------|-------|-----------|-------|
| PD_ALWAYS_ON | PMU, AO, clkgen, debug | 0.85V | Always on |
| PD_CPU0 | Core 0 | 0.75–0.95V DVFS | ON/RET/OFF |
| PD_CPU1 | Core 1 | 0.75–0.95V DVFS | ON/RET/OFF |
| PD_GPU | GPU SMs | 0.85V | ON/OFF |
| PD_MEM | L1/L2/L3 caches | 0.85V | ON/RET/OFF |
| PD_IO | GPIO/UART/Timer | 3.3V IO | ON/OFF |
| PD_PERIPH | SPI/I2C/WDT/PWM | 0.85V | ON/OFF |
| PD_CRYPTO | AES/SHA/PKA | 0.85V | ON/OFF |
| PD_PCIE | PCIe controller | 0.85V/1.8V IO | ON/OFF |
| PD_USB | USB 2.0 | 0.85V/3.3V IO | ON/OFF |
| PD_ETH | Ethernet MAC | 0.85V/1.8V IO | ON/OFF |

---

## MCMM Corners

| Corner | PVT | RC | Use |
|--------|-----|----|-----|
| func_tt_0p85v_25c | TT 0.85V 25°C | Typ | Nominal |
| func_ss_0p75v_m40c | SS 0.75V -40°C | Worst | Setup slow |
| func_ss_0p75v_125c | SS 0.75V 125°C | Worst | Setup hot |
| func_ff_0p95v_m40c | FF 0.95V -40°C | Best | Hold fast |
| func_ff_0p95v_0c | FF 0.95V 0°C | Best | Hold fast |
| func_tt_0p85v_85c | TT 0.85V 85°C | Worst | Nominal hot |
| scan_ss_0p75v_125c | SS 0.75V 125°C | Worst | Scan timing |
| scan_ff_0p95v_m40c | FF 0.95V -40°C | Best | Scan hold |
| func_ss_aging_0p75v_125c | SS+aging | Worst+ | 10yr EOL |
| func_tt_0p85v_85c_cmax | TT Cmax | Cmax | Worst cap |
| func_tt_0p85v_25c_cmin | TT Cmin | Cmin | Best cap |
| func_ss_0p75v_125c_cmax | SS Cmax | Cmax | Worst all |

---

## Running Simulation

```bash
# VCS simulation
vcs -sverilog -timescale=1ns/1ps \
    +incdir+rtl \
    rtl/top/soc_top.v \
    testbench/tb_soc_top.v \
    -o sim_soc_top

./sim_soc_top +define+DUMP_VCD

# Alternatively with Questa
vsim -do "do scripts/questa_run.do" testbench/tb_soc_top
```
