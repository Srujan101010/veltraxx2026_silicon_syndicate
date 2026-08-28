// ============================================================================
// Module: async_fifo
// Description: Top-level asynchronous FIFO with synchronized dynamic threshold safeguards.
// ============================================================================
module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
)(
    // Write Domain
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    input  logic [ADDR_WIDTH:0]   afull_thresh,
    output logic                  afull,

    // Read Domain
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty,
    input  logic [ADDR_WIDTH:0]   aempty_thresh,
    output logic                  aempty
);

    localparam int PTR_WIDTH = ADDR_WIDTH + 1;

    // Resets
    logic wr_rst_sync_n;
    logic rd_rst_sync_n;

    reset_sync u_wr_reset_sync (
        .clk    (wr_clk),
        .arst_n (wr_rst_n),
        .srst_n (wr_rst_sync_n)
    );

    reset_sync u_rd_reset_sync (
        .clk    (rd_clk),
        .arst_n (rd_rst_n),
        .srst_n (rd_rst_sync_n)
    );

    // Pointers
    logic [PTR_WIDTH-1:0] wr_ptr_bin, wr_ptr_gray;
    logic [PTR_WIDTH-1:0] rd_ptr_bin, rd_ptr_gray;
    logic [PTR_WIDTH-1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
    logic [PTR_WIDTH-1:0] rd_ptr_bin_sync, wr_ptr_bin_sync;

    // Memory
    logic mem_wr_en;
    assign mem_wr_en = wr_en & ~full;

    fifomem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifomem (
        .wr_clk  (wr_clk),
        .wr_en   (mem_wr_en),
        .wr_addr (wr_ptr_bin[ADDR_WIDTH-1:0]),
        .wr_data (wr_data),
        .rd_addr (rd_ptr_bin[ADDR_WIDTH-1:0]),
        .rd_data (rd_data)
    );

    // Synchronizers
    sync_w2r_ptr #(.ADDR_WIDTH(ADDR_WIDTH)) u_sync_w2r (
        .rd_clk           (rd_clk),
        .rd_rst_n         (rd_rst_sync_n),
        .wr_ptr_gray      (wr_ptr_gray),
        .wr_ptr_gray_sync (wr_ptr_gray_sync)
    );

    sync_r2w_ptr #(.ADDR_WIDTH(ADDR_WIDTH)) u_sync_r2w (
        .wr_clk           (wr_clk),
        .wr_rst_n         (wr_rst_sync_n),
        .rd_ptr_gray      (rd_ptr_gray),
        .rd_ptr_gray_sync (rd_ptr_gray_sync)
    );

    // Full & Empty logic
    wr_ptr_full #(.ADDR_WIDTH(ADDR_WIDTH)) u_wr_ptr_full (
        .wr_clk           (wr_clk),
        .wr_rst_n         (wr_rst_sync_n),
        .wr_en            (wr_en),
        .rd_ptr_gray_sync (rd_ptr_gray_sync),
        .wr_ptr_bin       (wr_ptr_bin),
        .wr_ptr_gray      (wr_ptr_gray),
        .full             (full)
    );

    rd_ptr_empty #(.ADDR_WIDTH(ADDR_WIDTH)) u_rd_ptr_empty (
        .rd_clk           (rd_clk),
        .rd_rst_n         (rd_rst_sync_n),
        .rd_en            (rd_en),
        .wr_ptr_gray_sync (wr_ptr_gray_sync),
        .rd_ptr_bin       (rd_ptr_bin),
        .rd_ptr_gray      (rd_ptr_gray),
        .empty            (empty)
    );

    // Gray to Binary Converters
    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH)) u_gray2bin_r2w (
        .gray_in (rd_ptr_gray_sync),
        .bin_out (rd_ptr_bin_sync)
    );

    gray_to_bin #(.ADDR_WIDTH(ADDR_WIDTH)) u_gray2bin_w2r (
        .gray_in (wr_ptr_gray_sync),
        .bin_out (wr_ptr_bin_sync)
    );

    // Write Domain Almost Full Logic
    logic [PTR_WIDTH-1:0] wr_ptr_bin_next_wm;
    logic [PTR_WIDTH-1:0] occupancy_wr_next;
    logic [ADDR_WIDTH:0]  afull_thresh_latched;

    assign wr_ptr_bin_next_wm = wr_ptr_bin + (wr_en & ~full);
    assign occupancy_wr_next  = wr_ptr_bin_next_wm - rd_ptr_bin_sync;

    always_ff @(posedge wr_clk or negedge wr_rst_sync_n) begin
        if (!wr_rst_sync_n) begin
            afull                <= 1'b0;
            afull_thresh_latched <= '0;
        end else begin
            afull_thresh_latched <= afull_thresh; // Dynamic threshold latch guard
            afull                <= (occupancy_wr_next >= afull_thresh_latched);
        end
    end

    // Read Domain Almost Empty Logic
    logic [PTR_WIDTH-1:0] rd_ptr_bin_next_wm;
    logic [PTR_WIDTH-1:0] occupancy_rd_next;
    logic [ADDR_WIDTH:0]  aempty_thresh_latched;

    assign rd_ptr_bin_next_wm = rd_ptr_bin + (rd_en & ~empty);
    assign occupancy_rd_next  = wr_ptr_bin_sync - rd_ptr_bin_next_wm;

    always_ff @(posedge rd_clk or negedge rd_rst_sync_n) begin
        if (!rd_rst_sync_n) begin
            aempty                <= 1'b1;
            aempty_thresh_latched <= '0;
        end else begin
            aempty_thresh_latched <= aempty_thresh; // Dynamic threshold latch guard
            aempty                <= (occupancy_rd_next <= aempty_thresh_latched);
        end
    end

endmodule