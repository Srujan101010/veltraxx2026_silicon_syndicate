# Silicon Syndicate — Veltraxx 2026

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Target PDK](https://img.shields.io/badge/PDK-SkyWater%20130nm-orange)
![EDA Tool](https://img.shields.io/badge/Flow-OpenLane%20%2F%20Yosys-green)

Welcome to the official design submission by team **Silicon Syndicate** for **Veltraxx 2026**. 

This repository contains the complete SystemVerilog/RTL design, testbench verification environment, synthesis scripts, and OpenLane physical design flow for our digital IC submission.

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Repository Structure](#-repository-structure)
- [Architecture & Design Details](#-architecture--design-details)
- [Verification & Simulation](#-verification--simulation)
- [ASIC Flow & Synthesis (Sky130)](#-asic-flow--synthesis-sky130)
  - [Synthesis Metrics](#synthesis-metrics)
- [Getting Started](#-getting-started)
- [License & Acknowledgments](#-license--acknowledgments)

---

## 🔒 Overview

Our project focuses on delivering a robust, efficient, and fully verifiable hardware design targeting the **SkyWater 130nm High-Density (`sky130_fd_sc_hd`)** standard cell library. The implementation prioritizes low-area footprint, correct cross-clock domain synchronization, and clean synthesis mapping using open-source EDA tools.

---

## ✨ Key Features

* **RTL Implementation:** Modular, parameterized SystemVerilog / Verilog code designed for readability and synthesis compatibility.
* **CDC & Synchronization:** Robust handling of multi-clock or asynchronous interfaces using standard double-flop synchronizers and Gray code pointer conversion.
* **OpenLane Integration:** Fully automated open-source ASIC flow setup targeting the Sky130 PDK.
* **Complete Verification:** Rigorous testbench suite checking corner cases, boundary conditions, and flag assertions (Full/Empty/Overflow/Underflow).

---

## 📁 Repository Structure

```text
├── rtl/                   # SystemVerilog / Verilog RTL source files
│   ├── top.v              # Top-level module
│   └── ...                # Submodules
├── tb/                    # Testbenches & verification suites
│   └── tb_top.v           # Top-level testbench
├── openlane/              # OpenLane build configurations & runs
│   └── config.json        # OpenLane flow configuration settings
├── docs/                  # Design diagrams, waveforms, and notes
├── Makefile               # Simulation and synthesis automation
└── README.md              # Project documentation
