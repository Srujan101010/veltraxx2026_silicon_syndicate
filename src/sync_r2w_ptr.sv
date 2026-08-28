// ============================================================================
// Module: sync_r2w_ptr
// Description: Synchronizes read Gray pointer into write clock domain.
// ============================================================================
module sync_r2w_ptr #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic                wr_clk,
    input  logic                wr_rst_n,
    input  logic [ADDR_WIDTH:0] rd_ptr_gray,
    output logic [ADDR_WIDTH:0] rd_ptr_gray_sync
);

    (* ASYNC_REG = "TRUE" *) logic [ADDR_WIDTH:0] sync_stage1;
    (* ASYNC_REG = "TRUE" *) logic [ADDR_WIDTH:0] sync_stage2;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            sync_stage1 <= '0;
            sync_stage2 <= '0;
        end else begin
            sync_stage1 <= rd_ptr_gray;
            sync_stage2 <= sync_stage1;
        end
    end

    assign rd_ptr_gray_sync = sync_stage2;

endmodule