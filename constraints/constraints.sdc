# ==============================================================================
# SDC Constraints for async_fifo (OpenSTA / OpenROAD Compatible)
# ==============================================================================

# 1. Clock Definitions
create_clock -name wr_clk -period 10.000 [get_ports wr_clk]
create_clock -name rd_clk -period 25.000 [get_ports rd_clk]

# 2. Clock Uncertainty & Transition Constraints
set_clock_uncertainty -setup 0.200 [get_clocks {wr_clk rd_clk}]
set_clock_uncertainty -hold  0.100 [get_clocks {wr_clk rd_clk}]
set_clock_transition 0.150 [get_clocks {wr_clk rd_clk}]

# 3. Clock Domain Crossing Isolation (CDC)
set_clock_groups -asynchronous \
    -group [get_clocks wr_clk] \
    -group [get_clocks rd_clk]

# 4. Input & Output Delays
set_input_delay  1.500 -clock wr_clk [get_ports {wr_en wr_data[*] afull_thresh[*]}]
set_output_delay 1.500 -clock wr_clk [get_ports {full afull}]

set_input_delay  1.500 -clock rd_clk [get_ports {rd_en aempty_thresh[*]}]
set_output_delay 1.500 -clock rd_clk [get_ports {rd_data[*] empty aempty}]

# 5. Reset Path Handling
set_false_path -from [get_ports {wr_rst_n rd_rst_n}]

# 6. Global Design Rules & Drive/Load Settings
set_max_fanout 8 [current_design]
set_max_transition 0.750 [current_design]

set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 [get_ports {wr_en wr_data[*] afull_thresh[*] rd_en aempty_thresh[*] wr_rst_n rd_rst_n}]
set_load 0.015 [all_outputs]
