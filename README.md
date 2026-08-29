# Silicon Syndicate — Veltraxx 2026

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Target PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm-orange)
![EDA Tool](https://img.shields.io/badge/Flow-OpenLane%20%2F%20OpenROAD-green)

Welcome to the official repository of team **Silicon Syndicate** for **Veltraxx 2026**.

This project presents a robust, parameterizable **Asynchronous FIFO** silicon design targeting the **SkyWater 130nm (`sky130_fd_sc_hd`)** standard cell library. The design is architected to safely cross data between unrelated clock domains while ensuring complete data integrity, glitch-free control signaling, and full STA signoff across multiple PVT corners.

---

## 📌 Table of Contents

- [Problem Statement](#-problem-statement)
- [Key Architectural Features](#-key-architectural-features)
- [Repository Structure](#-repository-structure)
- [System Architecture & Module Hierarchy](#-system-architecture--module-hierarchy)
- [Clock Domain Crossing (CDC) & Timing Strategy](#-clock-domain-crossing-cdc--timing-strategy)
- [Verification & Testbench Environment](#-verification--testbench-environment)
- [ASIC Physical Design & Synthesis Outputs](#-asic-physical-design--synthesis-outputs)
- [Getting Started](#-getting-started)
- [License](#-license)

---

## 🎯 Problem Statement

> **Design a highly robust, parameterizable asynchronous FIFO (configurable depth $N$ and data width $W$) to guarantee reliable data transfer between two independent, non-integer-multiple clock domains. The architecture must successfully navigate Clock Domain Crossing (CDC) hazards, ensuring absolute data integrity and glitch-free control signaling despite unrelated clock frequencies and dynamic phase shifts.**

---

## ✨ Key Architectural Features

* **Configurable Architecture:** Fully parameterizable Data Width ($W$) and FIFO Depth ($N$).
* **Safe CDC Synchronization:** Multi-stage synchronizer chains for write-to-read (`sync_w2r_ptr.sv`) and read-to-write (`sync_r2w_ptr.sv`) domain synchronization.
* **Gray-Coded Pointers:** Single-bit transition encoding across clock domain boundaries to eliminate multi-bit sampling hazards and bus skew meta-stability.
* **Glitch-Free Flags:** Robust generation of `full`, `empty`, `afull` (almost full), and `aempty` (almost empty) flags.
* **Synchronized Resets:** Dedicated asynchronous assertion with synchronous de-assertion reset bridges (`reset_sync.sv`) per clock domain.
* **Full PVT STA Signoff:** Validated with SDC constraints (`constraints/constraints.sdc`) across multiple corners (`nom_ff_n40C_1v95`, `nom_ss_100C_1v60`, `nom_tt_025C_1v80`, etc.).

---

## 📁 Repository Structure

```text
veltraxx2026_silicon_syndicate/
├── constraints/
│   ├── config.json               # OpenLane flow configuration file
│   └── constraints.sdc           # OpenSTA / OpenROAD SDC timing constraints
├── docs/
│   ├── Block diagram.png         # Hardware architecture block diagram
│   └── Technical Specs.docx      # Comprehensive technical specs
├── logs/                         # Physical design & synthesis execution logs
|   ├── rcextraction/
|   ├── klayout_drc.log/
|   ├── metrics.csv/
|   ├── netgen-lvs.log/
|   ├── openroad-floorplan.log/
|   ├── openroad-generatepdn.log/
|   ├── openroad-globalplacementskipio.log/
|   ├── openroad-ioplacement.log/
|   ├── openroad-globalrouting.log/
|   ├── verilator-lint.log/
|   └── yosys-sythesis.log  
├── outputs/                      # OpenSTA corner analysis & physical layout
│   ├── nom_ff_n40C_1v95/        # Fast-Fast PVT Corner timing & power reports
│   ├── max_ss_100C_1v60/        # Slow-Slow PVT Corner reports
│   ├── min_tt_025C_1v80/
|   ├── min_ff_n40c_1v95/
|   ├── min_ss_100c_1v60/
|   ├── min_tt_025C_1v80/
|   ├── nom_ss_100C_1v60/
|   ├── nom_tt_025C_1v80/   # Typical Corner reports
│   ├── rcextraction/            # RC extraction & parasitics outputs
│   ├── async_fifo.v             # Synthesized netlist
│   ├── async_fifo.klayout.gds   # GDSII Layout output for fabrication
│   ├── irdrop.rpt               # IR Drop Analysis Report
│   └── summary.rpt              # Combined metric summary report
├── src/                          # SystemVerilog RTL Source Files
│   ├── async_fifo.sv            # Top-level wrapper module
│   ├── fifomem.sv               # Dual-port memory array
│   ├── gray_to_bin.sv           # Gray-to-Binary conversion logic
│   ├── rd_ptr_empty.sv          # Read pointer generation & empty flag logic
│   ├── reset_sync.sv            # Asynchronous reset synchronizer
│   ├── sync_r2w_ptr.sv          # Read-to-write domain synchronizer
│   ├── sync_w2r_ptr.sv          # Write-to-read domain synchronizer
│   └── wr_ptr_full.sv           # Write pointer generation & full flag logic
├── tb/
    └──tb_async_fifo.sv/
     
├── tb/
│   └── fifotb.sv                # Dynamic testbench & verification suite
└── README.md                     # Project documentation
