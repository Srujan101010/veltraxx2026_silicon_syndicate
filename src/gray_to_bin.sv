// ============================================================================
// Module: gray_to_bin
// Description: Converts Gray-coded pointer to binary with parallel XOR reduction tree.
// ============================================================================
module gray_to_bin #(
    parameter int ADDR_WIDTH = 4
)(
    input  logic [ADDR_WIDTH:0] gray_in,
    output logic [ADDR_WIDTH:0] bin_out
);

    localparam int PTR_WIDTH = ADDR_WIDTH + 1;

    always_comb begin
        for (int i = 0; i < PTR_WIDTH; i++) begin
            bin_out[i] = ^(gray_in >> i);
        end
    end

endmodule