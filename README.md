//// OVERVIEW ////
This project implements a parameterizable, synthesizable Dual-Clock Asynchronous FIFO in SystemVerilog, designed for robust clock-domain crossing (CDC) between independent clock sources with arbitrary frequencies and phases.
By maintaining simultaneous Binary and Gray-code pointer registers, the architecture eliminates deep back-conversion XOR trees, computing FULL and EMPTY flags directly in the Gray domain through bitwise comparisons and MSB inversion.
This approach drastically minimizes gate count, reduces combinational path depth to O(Nlog2 N), and optimizes critical paths for maximum operational frequency fMAX.
It is also protected by 2 ffs against metastability.
