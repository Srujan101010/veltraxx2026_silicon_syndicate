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

An asynchronous FIFO is one of the most common — and most dangerous — building blocks in multi-clock-domain SoCs. Because the write and read clocks have no fixed phase relationship, any signal moving between domains is susceptible to **metastability**. A naive implementation risks corrupted data, incorrect `full`/`empty` flags, or the FIFO overflowing/underflowing silently. This project solves that problem end-to-end: from RTL architecture, through simulation-based verification, to a fully placed-and-routed GDSII layout that is signed off across PVT corners.

---

## ✨ Key Architectural Features

* **Configurable Architecture:** Fully parameterizable Data Width ($W$) and FIFO Depth ($N$), set via Verilog/SystemVerilog parameters so the same RTL can be retargeted to different bus widths and buffer sizes without structural changes.
* **Safe CDC Synchronization:** Multi-stage (2-flop) synchronizer chains for write-to-read (`sync_w2r_ptr.sv`) and read-to-write (`sync_r2w_ptr.sv`) domain synchronization, reducing the probability of metastable propagation to negligible levels.
* **Gray-Coded Pointers:** Single-bit transition encoding across clock domain boundaries to eliminate multi-bit sampling hazards and bus skew metastability — only one bit ever changes per increment, so a synchronizer sampling mid-transition still resolves to either the old or new valid pointer value.
* **Glitch-Free Flags:** Robust generation of `full`, `empty`, `afull` (almost full), and `aempty` (almost empty) flags, derived combinationally from synchronized Gray pointers so they never produce spurious pulses.
* **Synchronized Resets:** Dedicated asynchronous-assert / synchronous-deassert reset bridges (`reset_sync.sv`) per clock domain, ensuring both domains exit reset cleanly with no reset-recovery timing violations.
* **Full PVT STA Signoff:** Validated with SDC constraints (`constraints/constraints.sdc`) across multiple corners (`nom_ff_n40C_1v95`, `nom_ss_100C_1v60`, `nom_tt_025C_1v80`, etc.) to guarantee timing closure under real-world process, voltage, and temperature variation.

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
│   ├── rcextraction/
│   ├── klayout_drc.log
│   ├── metrics.csv
│   ├── netgen-lvs.log
│   ├── openroad-floorplan.log
│   ├── openroad-generatepdn.log
│   ├── openroad-globalplacementskipio.log
│   ├── openroad-ioplacement.log
│   ├── openroad-globalrouting.log
│   ├── verilator-lint.log
│   └── yosys-sythesis.log
├── outputs/                      # OpenSTA corner analysis & physical layout
│   ├── nom_ff_n40C_1v95/         # Fast-Fast PVT corner timing & power reports
│   ├── max_ss_100C_1v60/         # Slow-Slow PVT corner reports
│   ├── min_tt_025C_1v80/
│   ├── min_ff_n40c_1v95/
│   ├── min_ss_100c_1v60/
│   ├── nom_ss_100C_1v60/
│   ├── nom_tt_025C_1v80/         # Typical corner reports
│   ├── rcextraction/             # RC extraction & parasitics outputs
│   ├── async_fifo.v              # Synthesized netlist
│   ├── async_fifo.klayout.gds    # GDSII layout output for fabrication
│   ├── irdrop.rpt                # IR drop analysis report
│   └── summary.rpt               # Combined metric summary report
├── src/                           # SystemVerilog RTL source files
│   ├── async_fifo.sv             # Top-level wrapper module
│   ├── fifomem.sv                # Dual-port memory array
│   ├── gray_to_bin.sv            # Gray-to-binary conversion logic
│   ├── rd_ptr_empty.sv           # Read pointer generation & empty flag logic
│   ├── reset_sync.sv             # Asynchronous reset synchronizer
│   ├── sync_r2w_ptr.sv           # Read-to-write domain synchronizer
│   ├── sync_w2r_ptr.sv           # Write-to-read domain synchronizer
│   └── wr_ptr_full.sv            # Write pointer generation & full flag logic
├── tb/
│   └── tb_async_fifo.sv          # Dynamic testbench & verification suite
│
└── README.md                     # Project documentation
```

---

## 🧩 System Architecture & Module Hierarchy

`async_fifo.sv` is the top-level module that instantiates and wires together every other block. Data flows through two clock domains that never communicate directly — only synchronized, Gray-coded pointers cross the boundary.

```text
                     ┌─────────────────────────────────────────────────┐
                     │                  async_fifo.sv                   │
                     │                (top-level wrapper)               │
                     └─────────────────────────────────────────────────┘
     WRITE DOMAIN (wclk)                                    READ DOMAIN (rclk)
┌──────────────────────────┐                        ┌──────────────────────────┐
│  reset_sync.sv (wclk)     │                        │  reset_sync.sv (rclk)     │
│  wr_ptr_full.sv           │                        │  rd_ptr_empty.sv          │
│   - binary + gray wptr    │                        │   - binary + gray rptr    │
│   - full flag logic       │                        │   - empty flag logic      │
└────────────┬──────────────┘                        └────────────┬──────────────┘
             │  gray wptr                                          │  gray rptr
             ▼                                                      ▼
   ┌───────────────────┐                                  ┌───────────────────┐
   │ sync_w2r_ptr.sv    │ ───── gray wptr, synced ───────► │  used by rd_ptr_   │
   │ (2-FF into rclk)   │                                  │  empty.sv           │
   └───────────────────┘                                  └───────────────────┘
   ┌───────────────────┐                                  ┌───────────────────┐
   │  used by wr_ptr_   │ ◄───── gray rptr, synced ─────── │ sync_r2w_ptr.sv    │
   │  full.sv            │                                  │ (2-FF into wclk)   │
   └───────────────────┘                                  └───────────────────┘
             │                                                      │
             ▼                                                      ▼
      write data, wr_en ──────────────►  fifomem.sv (dual-port RAM) ──────────► read data, rd_en
```

**Module responsibilities:**

| Module | Domain | Responsibility |
|---|---|---|
| `async_fifo.sv` | Top | Instantiates and connects all sub-modules; exposes the external interface (`wdata`, `wr_en`, `full`, `rdata`, `rd_en`, `empty`, clocks, resets). |
| `fifomem.sv` | Both | Dual-port memory array (`2^ADDR_WIDTH × DATA_WIDTH`) written on `wclk` and read on `rclk`. |
| `wr_ptr_full.sv` | Write | Maintains the binary and Gray-coded write pointer; compares the synchronized read pointer against the write pointer to generate `full` / `afull`. |
| `rd_ptr_empty.sv` | Read | Maintains the binary and Gray-coded read pointer; compares the synchronized write pointer against the read pointer to generate `empty` / `aempty`. |
| `gray_to_bin.sv` | Both | Converts a Gray-coded pointer back to binary so it can be used to index `fifomem.sv`. |
| `sync_w2r_ptr.sv` | Read | Two-flop synchronizer that brings the write pointer safely into the read clock domain. |
| `sync_r2w_ptr.sv` | Write | Two-flop synchronizer that brings the read pointer safely into the write clock domain. |
| `reset_sync.sv` | Both | Per-domain reset bridge: asynchronous assert, synchronous de-assert, instantiated once for `wclk` and once for `rclk`. |

---

## ⏱️ Clock Domain Crossing (CDC) & Timing Strategy

Crossing pointer values between two unrelated clocks is the central hazard this design solves. The strategy rests on three pillars:

1. **Gray coding before crossing.** Binary pointers are converted to Gray code before they leave their home domain. Since only one bit toggles per increment, a synchronizer that samples the bus mid-transition can only ever capture the pointer's previous value or its next value — never a corrupted intermediate value.
2. **Two-flop synchronizers.** `sync_w2r_ptr.sv` and `sync_r2w_ptr.sv` each pass the incoming Gray pointer through two back-to-back flip-flops clocked by the destination domain. This gives any metastable event a full clock period to resolve before the value is used, pushing the mean time between failures (MTBF) to acceptably safe levels for the target frequencies.
3. **Conservative, synchronized flag generation.** `full` and `empty` are computed only from the *synchronized* (already-crossed) pointers, never from a raw cross-domain comparison. This guarantees the flags are always pessimistic in the safe direction — the FIFO reports `full` a cycle earlier if in doubt, and reports `empty` a cycle later if in doubt — so no data is ever written into a full FIFO or read out of an empty one.

**Reset strategy:** each domain gets its own `reset_sync.sv` instance. Reset asserts asynchronously the instant it's triggered (so it can never be gated by a stopped or missing clock), but de-asserts synchronously to that domain's own clock, eliminating reset-recovery/removal timing violations at the reset boundary.

**Timing signoff:** `constraints/constraints.sdc` defines independent clock groups for `wclk` and `rclk` (declared asynchronous to each other so STA doesn't attempt — and fail — to time a false path), along with `set_false_path` exceptions across the synchronizer boundaries where appropriate. Static timing analysis is run with OpenSTA across the full PVT corner matrix (fast-fast, slow-slow, and typical-typical, at multiple voltage/temperature points) to confirm setup and hold closure under best-case, worst-case, and nominal silicon behavior.

---

## 🔬 Verification & Testbench Environment

The design is verified with `tb/tb_async_fifo.sv`, a self-checking SystemVerilog testbench that exercises the FIFO under realistic asynchronous conditions.

**Verification approach:**
- **Independent, unrelated clock generation** for the write and read domains (non-integer frequency ratios) to genuinely stress the CDC logic rather than relying on a convenient common clock edge.
- **Constrained-random stimulus** for write/read enables and data, to hit corner-case interleavings that directed tests would likely miss.
- **Self-checking scoreboard** that models expected FIFO behavior and compares it against actual output data, flagging any mismatch, dropped word, or duplicated word.
- **Flag correctness checks** — actively driving the FIFO to its `full` and `empty` boundaries (and the `afull`/`aempty` thresholds) to confirm flags assert and de-assert at exactly the right pointer values, with no glitches.
- **Reset behavior checks** — asserting reset mid-transaction in each domain independently to confirm both domains recover cleanly without stale pointer or flag state.

**Simulation & lint flow:**
- RTL is linted with Verilator (`logs/verilator-lint.log`) to catch width mismatches, unused signals, and other structural issues before synthesis.
- Functional simulation is run to validate behavior at the RTL level prior to handoff to the physical design flow.

---

## 🏗️ ASIC Physical Design & Synthesis Outputs

Once RTL is verified, the design is carried through the full **OpenLane / OpenROAD** RTL-to-GDSII flow targeting the **SkyWater 130nm** (`sky130_fd_sc_hd`) standard cell library.

**Flow stages & corresponding artifacts:**

| Stage | Tool | Log / Output |
|---|---|---|
| Synthesis | Yosys | `logs/yosys-sythesis.log`, `outputs/async_fifo.v` (synthesized netlist) |
| Floorplanning | OpenROAD | `logs/openroad-floorplan.log` |
| Power Distribution Network | OpenROAD (PDN gen) | `logs/openroad-generatepdn.log` |
| I/O Placement | OpenROAD | `logs/openroad-ioplacement.log` |
| Global Placement | OpenROAD | `logs/openroad-globalplacementskipio.log` |
| Global Routing | OpenROAD | `logs/openroad-globalrouting.log` |
| Parasitic (RC) Extraction | OpenROAD | `logs/rcextraction/`, `outputs/rcextraction/` |
| Static Timing Analysis | OpenSTA | Per-corner reports in `outputs/<corner>/` (e.g. `nom_tt_025C_1v80`, `max_ss_100C_1v60`, `nom_ff_n40C_1v95`) |
| IR Drop Analysis | OpenROAD | `outputs/irdrop.rpt` |
| Design Rule Check (DRC) | KLayout | `logs/klayout_drc.log` |
| Layout vs. Schematic (LVS) | Netgen | `logs/netgen-lvs.log` |
| Final Layout | OpenROAD / KLayout | `outputs/async_fifo.klayout.gds` |
| Summary Metrics | — | `outputs/metrics.csv`, `outputs/summary.rpt` |

**PVT corner coverage:** timing and power are signed off across fast-fast, slow-slow, and typical-typical process corners at multiple voltage/temperature points (e.g. `nom_ff_n40C_1v95`, `nom_ss_100C_1v60`, `nom_tt_025C_1v80`, `min_ff_n40c_1v95`, `min_ss_100c_1v60`, `min_tt_025C_1v80`), giving confidence that the design meets timing across the full range of expected silicon behavior — not just under nominal conditions.

The final `async_fifo.klayout.gds` is a DRC-clean, LVS-matched layout ready for fabrication handoff on the SkyWater 130nm open-source PDK.

---

## 🚀 Getting Started

### Prerequisites
- [LibreLane](https://github.com/librelane/librelane) (successor to OpenLane) and [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) (or the LibreLane Docker/Nix environment)
- [Yosys](https://github.com/YosysHQ/yosys) for synthesis
- [Verilator](https://www.veripool.org/verilator/) for RTL linting
- A SystemVerilog simulator (e.g. Icarus Verilog, Verilator, or a commercial simulator) for running the testbench
- [KLayout](https://www.klayout.de/) for DRC/GDS viewing and [Netgen](http://opencircuitdesign.com/netgen/) for LVS
- The SkyWater 130nm open-source PDK (`sky130_fd_sc_hd`)

### 1. Clone the repository
```bash
git clone https://github.com/<your-org>/veltraxx2026_silicon_syndicate.git
cd veltraxx2026_silicon_syndicate
```

### 2. Run RTL lint
```bash
verilator --lint-only -Isrc src/async_fifo.sv
```

### 3. Run functional simulation
```bash
# Example using Icarus Verilog
iverilog -g2012 -o sim_out tb/tb_async_fifo.sv src/*.sv
vvp sim_out (for opensource)
```

### 4. Run the LibreLane physical design flow
```bash
python -m librelane --dockerized /home/jayanth/librelane/designs/asyncfifo/config.json
```

### 5. Review signoff artifacts
- Timing reports: `outputs/<corner_name>/`
- DRC results: `logs/klayout_drc.log`
- LVS results: `logs/netgen-lvs.log`
- Final GDS: `outputs/async_fifo.klayout.gds`
- Summary: `outputs/summary.rpt`, `outputs/metrics.csv`

---

## 📄 License

This project is licensed under the **MIT License** — see the badge above. You are free to use, modify, and distribute this design with attribution.
