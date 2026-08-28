`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.08.2026 13:25:01
// Design Name: 
// Module Name: reset_sync
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
// Module: reset_sync
// Description: Asynchronous reset assertion with synchronous de-assertion.
// ============================================================================
module reset_sync (
    input  logic clk,
    input  logic arst_n,
    output logic srst_n
);

    (* ASYNC_REG = "TRUE" *) logic sync_ff1;
    (* ASYNC_REG = "TRUE" *) logic sync_ff2;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= sync_ff1;
        end
    end

    assign srst_n = sync_ff2;

endmodule
