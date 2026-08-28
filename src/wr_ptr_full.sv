`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.08.2026 13:29:15
// Design Name: 
// Module Name: wr_ptr_full
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// ============================================================================
// Module: wr_ptr_full
// Description: Handles write pointer increments, Gray encoding, and FULL evaluation.
// ============================================================================
module wr_ptr_full #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic                wr_clk,
    input  logic                wr_rst_n,
    input  logic                wr_en,
    input  logic [ADDR_WIDTH:0] rd_ptr_gray_sync,
    output logic [ADDR_WIDTH:0] wr_ptr_bin,
    output logic [ADDR_WIDTH:0] wr_ptr_gray,
    output logic                full
);

    logic [ADDR_WIDTH:0] wr_ptr_bin_next;
    logic [ADDR_WIDTH:0] wr_ptr_gray_next;
    logic                full_val;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en & ~full);
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    assign full_val = (wr_ptr_gray_next[ADDR_WIDTH:ADDR_WIDTH-1] == ~rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1]) &&
                       (wr_ptr_gray_next[ADDR_WIDTH-2:0] == rd_ptr_gray_sync[ADDR_WIDTH-2:0]);

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= '0;
            wr_ptr_gray <= '0;
            full        <= 1'b0;
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
            full        <= full_val;
        end
    end

endmodule