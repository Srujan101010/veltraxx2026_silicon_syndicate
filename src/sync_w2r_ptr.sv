// ============================================================================
// Module: sync_w2r_ptr
// Description: Synchronizes write Gray pointer into read clock domain.
// ============================================================================
module sync_w2r_ptr #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic                rd_clk,
    input  logic                rd_rst_n,
    input  logic [ADDR_WIDTH:0] wr_ptr_gray,
    output logic [ADDR_WIDTH:0] wr_ptr_gray_sync
);

    (* ASYNC_REG = "TRUE" *) logic [ADDR_WIDTH:0] sync_stage1;
    (* ASYNC_REG = "TRUE" *) logic [ADDR_WIDTH:0] sync_stage2;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            sync_stage1 <= '0;
            sync_stage2 <= '0;
        end else begin
            sync_stage1 <= wr_ptr_gray;
            sync_stage2 <= sync_stage1;
        end
    end

    assign wr_ptr_gray_sync = sync_stage2;

endmodule