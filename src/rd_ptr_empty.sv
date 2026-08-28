// ============================================================================
// Module: rd_ptr_empty
// Description: Handles read pointer increments, Gray encoding, and EMPTY evaluation.
// ============================================================================
module rd_ptr_empty #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic                rd_clk,
    input  logic                rd_rst_n,
    input  logic                rd_en,
    input  logic [ADDR_WIDTH:0] wr_ptr_gray_sync,
    output logic [ADDR_WIDTH:0] rd_ptr_bin,
    output logic [ADDR_WIDTH:0] rd_ptr_gray,
    output logic                empty
);

    logic [ADDR_WIDTH:0] rd_ptr_bin_next;
    logic [ADDR_WIDTH:0] rd_ptr_gray_next;
    logic                empty_val;

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en & ~empty);
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    assign empty_val = (rd_ptr_gray_next == wr_ptr_gray_sync);

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= '0;
            rd_ptr_gray <= '0;
            empty       <= 1'b1;
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
            empty       <= empty_val;
        end
    end

endmodule
