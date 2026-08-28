// ============================================================================
// Module: fifomem
// Description:
//   Dual-clock FIFO storage.
//   Write operation occurs on wr_clk.
//   Read data is registered on rd_clk for deterministic read timing.
// ============================================================================

module fifomem #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
)(
    input  logic                  wr_clk,
    input  logic                  wr_en,
    input  logic [ADDR_WIDTH-1:0] wr_addr,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic                  rd_clk,
    input  logic                  rd_en,
    input  logic                  rd_valid,
    input  logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);

    localparam int DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // ------------------------------------------------------------------------
    // WRITE PORT
    // ------------------------------------------------------------------------
    always_ff @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // ------------------------------------------------------------------------
    // READ PORT
    //
    // rd_valid means that a read was actually accepted:
    //     rd_en && !empty
    //
    // rd_data is therefore updated only for a valid FIFO read.
    // ------------------------------------------------------------------------
    always_ff @(posedge rd_clk) begin
        if (rd_valid) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
