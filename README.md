//// OVERVIEW ////
This project implements a parameterizable, synthesizable Dual-Clock Asynchronous FIFO in SystemVerilog, designed for robust clock-domain crossing (CDC) between independent clock sources with arbitrary frequencies and phases.
By maintaining simultaneous Binary and Gray-code pointer registers, the architecture eliminates deep back-conversion XOR trees, computing FULL and EMPTY flags directly in the Gray domain through bitwise comparisons and MSB inversion.
This approach drastically minimizes gate count, reduces combinational path depth to O(Nlog2 N), and optimizes critical paths for maximum operational frequency fMAX.
It is also protected by 2 ffs against metastability.

//// REQUIREMENTS////
vivado,openlane,librelane

as of 22:23 28=08=2026

DATA_WIDTH  = 8
ADDR_WIDTH  = 4
FIFO DEPTH  = 16

Write clock : wr_clk
Read clock  : rd_clk

Clock domains:
    Independent / asynchronous

CDC:
    Binary pointers converted to Gray code
    Gray pointers synchronized using 2-stage synchronizers

Write-side status:
    FULL
    ALMOST-FULL

Read-side status:
    EMPTY
    ALMOST-EMPTY

Read data:
    Registered on rd_clk

Protection:
    Writes blocked when FULL
    Reads blocked when EMPTY

Verification:
    RTL simulation: PASS
    Post-synthesis functional simulation: PASS
    Errors: 0

