// ============================================================================
// File: tb_async_fifo.sv
// Description:
//   Self-checking testbench for asynchronous FIFO.
//
//   Verification principles:
//     - Inputs are driven on negedge.
//     - DUT samples inputs on posedge.
//     - Reference queue tracks ONLY accepted writes.
//     - Expected data is removed ONLY when an accepted read is observed.
//     - Registered read-data is checked with explicit one-cycle latency.
//     - Each test starts with a known reference-model state.
// ============================================================================

`timescale 1ns / 1ps

module tb_async_fifo;

    // =========================================================================
    // PARAMETERS
    // =========================================================================

    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4;
    localparam int DEPTH      = 1 << ADDR_WIDTH;

    real wr_clk_period = 10.0;
    real rd_clk_period = 25.0;

    // =========================================================================
    // DUT SIGNALS
    // =========================================================================

    logic                  wr_clk   = 1'b0;
    logic                  wr_rst_n = 1'b0;
    logic                  wr_en    = 1'b0;
    logic [DATA_WIDTH-1:0] wr_data  = '0;
    logic                  full;

    logic [ADDR_WIDTH:0]   afull_thresh = 12;
    logic                  afull;

    logic                  rd_clk   = 1'b0;
    logic                  rd_rst_n = 1'b0;
    logic                  rd_en    = 1'b0;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  empty;

    logic [ADDR_WIDTH:0]   aempty_thresh = 3;
    logic                  aempty;

    // =========================================================================
    // REFERENCE MODEL
    //
    // The reference queue contains exactly the data accepted by the DUT.
    //
    // IMPORTANT:
    //   A write is accepted only when:
    //       wr_en && !full
    //
    //   A read is accepted only when:
    //       rd_en && !empty
    //
    // Registered rd_data is checked one rd_clk later.
    // =========================================================================

    mailbox #(logic [DATA_WIDTH-1:0]) ref_mbx = new();

    int error_count     = 0;
    int total_writes    = 0;
    int total_reads     = 0;
    int accepted_writes = 0;
    int accepted_reads  = 0;

    // Number of accepted reads for which rd_data is still expected.
    int pending_read_count = 0;

    // =========================================================================
    // DUT
    // =========================================================================

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk        (wr_clk),
        .wr_rst_n      (wr_rst_n),
        .wr_en         (wr_en),
        .wr_data       (wr_data),
        .full          (full),
        .afull_thresh  (afull_thresh),
        .afull         (afull),

        .rd_clk        (rd_clk),
        .rd_rst_n      (rd_rst_n),
        .rd_en         (rd_en),
        .rd_data       (rd_data),
        .empty         (empty),
        .aempty_thresh (aempty_thresh),
        .aempty        (aempty)
    );

    // =========================================================================
    // CLOCK GENERATION
    // =========================================================================

    initial begin
        forever #(wr_clk_period / 2.0)
            wr_clk = ~wr_clk;
    end

    initial begin
        forever #(rd_clk_period / 2.0)
            rd_clk = ~rd_clk;
    end

    // =========================================================================
    // WAVEFORM
    // =========================================================================

    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, tb_async_fifo);
    end

    // =========================================================================
    // WRITE MONITOR / REFERENCE MODEL
    //
    // Inputs are driven on negedge, therefore they are stable before posedge.
    // =========================================================================

    always @(posedge wr_clk) begin

        if (wr_rst_n && wr_en) begin

            total_writes++;

            if (!full) begin

                accepted_writes++;

                // Store exactly what the DUT accepted.
                ref_mbx.put(wr_data);

                $display(
                    "[%0t ns] [WRITE ACCEPTED] Data: 0x%0h",
                    $time,
                    wr_data
                );

            end
            else begin

                $display(
                    "[%0t ns] [WRITE BLOCKED] FIFO FULL, Data: 0x%0h ignored",
                    $time,
                    wr_data
                );

            end

        end

    end

    // =========================================================================
    // READ MONITOR
    //
    // The DUT has registered rd_data.
    //
    // At clock N:
    //     rd_en && !empty
    //          -> read transaction accepted
    //
    // At clock N+1:
    //     rd_data corresponds to that read.
    //
    // The mailbox is popped at the same time that the corresponding
    // registered data is checked.
    // =========================================================================

    logic pending_read = 1'b0;

    always @(posedge rd_clk) begin

        logic [DATA_WIDTH-1:0] expected_data;

        if (!rd_rst_n) begin

            pending_read <= 1'b0;

        end
        else begin

            // -----------------------------------------------------------------
            // CHECK RESULT OF PREVIOUS ACCEPTED READ
            // -----------------------------------------------------------------

            if (pending_read) begin

                if (ref_mbx.try_get(expected_data)) begin

                    if (rd_data !== expected_data) begin

                        $error(
                            "[%0t ns] [FAIL: DATA MISMATCH] Read: 0x%0h | Expected: 0x%0h",
                            $time,
                            rd_data,
                            expected_data
                        );

                        error_count++;

                    end
                    else begin

                        $display(
                            "[%0t ns] [READ MATCH] Data: 0x%0h verified successfully.",
                            $time,
                            rd_data
                        );

                    end

                end
                else begin

                    $error(
                        "[%0t ns] [FAIL: EXTRA READ] DUT produced data but reference queue is empty!",
                        $time
                    );

                    error_count++;

                end

            end

            // -----------------------------------------------------------------
            // RECORD CURRENT ACCEPTED READ
            // -----------------------------------------------------------------

            pending_read <= rd_en && !empty;

            if (rd_en && !empty) begin

                total_reads++;
                accepted_reads++;

            end

        end

    end

    // =========================================================================
    // WAIT FOR ALL PENDING READ DATA TO BE CHECKED
    // =========================================================================

    task automatic wait_for_pending_read();

        if (pending_read) begin
            @(posedge rd_clk);
        end

        // Allow NBA updates and monitor activity to settle.
        #1;

    endtask

    // =========================================================================
    // DRAIN FIFO
    //
    // rd_en is driven before the next sampling edge.
    // =========================================================================

    task automatic drain_fifo();

        int safety_count;

        safety_count = 0;

        // Continue while DUT reports data available.
        while (!empty && safety_count < (DEPTH * 4)) begin

            @(negedge rd_clk);

            if (!empty)
                rd_en = 1'b1;
            else
                rd_en = 1'b0;

            safety_count++;

        end

        @(negedge rd_clk);
        rd_en = 1'b0;

        // Allow the final registered read result to be checked.
        wait_for_pending_read();

        // Give the synchronized pointer state time to settle.
        repeat (3) @(posedge rd_clk);

    endtask

    // =========================================================================
    // CLEAR REFERENCE MODEL
    // =========================================================================

    task automatic clear_mailbox();

        logic [DATA_WIDTH-1:0] dummy;

        while (ref_mbx.try_get(dummy));

        pending_read = 1'b0;

    endtask

    // =========================================================================
    // VERIFY REFERENCE MODEL IS EMPTY
    // =========================================================================

    task automatic verify_reference_empty(
        input string test_name
    );

        #1;

        if (ref_mbx.num() != 0) begin

            $error(
                "[%0t ns] [FAIL: %s] Reference queue contains %0d item(s)!",
                $time,
                test_name,
                ref_mbx.num()
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS: %s] Reference queue empty.",
                $time,
                test_name
            );

        end

    endtask

    // =========================================================================
    // TEST BOUNDARY
    //
    // Before starting a new independent test:
    //   1. Disable stimulus.
    //   2. Wait for pending registered read.
    //   3. Verify reference queue.
    //   4. Clear it if necessary.
    // =========================================================================

    task automatic prepare_next_test();

        @(negedge wr_clk);
        wr_en = 1'b0;

        @(negedge rd_clk);
        rd_en = 1'b0;

        wait_for_pending_read();

        if (ref_mbx.num() != 0) begin

            $display(
                "[%0t ns] [INFO] Clearing %0d leftover reference item(s) at test boundary.",
                $time,
                ref_mbx.num()
            );

            clear_mailbox();

        end

    endtask

    // =========================================================================
    // MAIN TEST SEQUENCE
    // =========================================================================

    initial begin

        $display("\n========================================================");
        $display("        STARTING ASYNC FIFO VERIFICATION");
        $display("========================================================\n");

        // =====================================================================
        // INITIAL RESET
        // =====================================================================

        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;

        wr_en = 1'b0;
        rd_en = 1'b0;

        #40;

        wr_rst_n = 1'b1;

        #20;

        rd_rst_n = 1'b1;

        repeat (3) @(posedge wr_clk);
        repeat (2) @(posedge rd_clk);

        // =====================================================================
        // TEST 1: RESET
        // =====================================================================

        $display("\n--- [TEST 1] Initial Reset & Power-On State ---");

        if (!empty || full || afull || !aempty) begin

            $error(
                "[%0t ns] [FAIL] Incorrect initial flag states! full=%0b empty=%0b afull=%0b aempty=%0b",
                $time,
                full,
                empty,
                afull,
                aempty
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS] Reset values verified correctly.",
                $time
            );

        end

        // =====================================================================
        // TEST 2: THRESHOLD FLAGS
        // =====================================================================

        $display("\n--- [TEST 2] Testing Threshold Flags ---");

        prepare_next_test();

        afull_thresh  = 12;
        aempty_thresh = 3;

        // ------------------------------------------------------------
        // Write exactly 12 known values.
        // ------------------------------------------------------------

        for (int i = 0; i < 12; i++) begin

            @(negedge wr_clk);

            wr_en   = 1'b1;
            wr_data = 8'hA0 + i;

        end

        @(negedge wr_clk);
        wr_en = 1'b0;

        // Allow local AFULL calculation to settle.
        repeat (3) @(posedge wr_clk);

        if (!afull) begin

            $error(
                "[%0t ns] [FAIL] afull failed to assert at fill count 12! afull=%0b",
                $time,
                afull
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS] afull asserted correctly at threshold.",
                $time
            );

        end

        // Drain all data and wait for final registered read.
        drain_fifo();

        repeat (3) @(posedge rd_clk);

        if (!aempty) begin

            $error(
                "[%0t ns] [FAIL] aempty failed to assert when FIFO is empty!",
                $time
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS] aempty asserted correctly.",
                $time
            );

        end

        verify_reference_empty("TEST 2");

        // =====================================================================
        // TEST 3: FULL / OVERFLOW
        // =====================================================================

        $display("\n--- [TEST 3] Testing FULL Flag & Overflow Protection ---");

        prepare_next_test();

        // Fill until FULL.
        while (!full) begin

            @(negedge wr_clk);

            wr_en   = 1'b1;
            wr_data = $urandom_range(8'h01, 8'hFE);

        end

        // Intentionally attempt one write while FULL.
        @(negedge wr_clk);

        wr_en   = 1'b1;
        wr_data = 8'hFF;

        @(negedge wr_clk);
        wr_en = 1'b0;

        if (!full) begin

            $error(
                "[%0t ns] [FAIL] FULL flag failed to remain asserted!",
                $time
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS] FULL flag verified and overflow write ignored.",
                $time
            );

        end

        // =====================================================================
        // TEST 4: EMPTY / UNDERFLOW
        // =====================================================================

        $display("\n--- [TEST 4] Testing EMPTY Flag & Underflow Protection ---");

        drain_fifo();

        repeat (3) @(posedge rd_clk);

        // Attempt read while empty.
        @(negedge rd_clk);
        rd_en = 1'b1;

        @(negedge rd_clk);
        rd_en = 1'b0;

        if (!empty) begin

            $error(
                "[%0t ns] [FAIL] EMPTY flag deasserted during underflow attempt!",
                $time
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS] EMPTY flag verified and underflow ignored.",
                $time
            );

        end

        verify_reference_empty("TEST 4");

        // =====================================================================
        // TEST 5: SINGLE ELEMENT CDC
        // =====================================================================

      // =====================================================================
        // TEST 5: SINGLE ELEMENT CDC
        // =====================================================================
        
        $display("\n--- [TEST 5] Single-Element CDC Sync Latency Test ---");
        
        prepare_next_test();
        
        // ---------------------------------------------------------------------
        // Write exactly one value.
        // ---------------------------------------------------------------------
        
        @(negedge wr_clk);
        
        wr_en   = 1'b1;
        wr_data = 8'h55;
        
        @(negedge wr_clk);
        
        wr_en = 1'b0;
        
        // ---------------------------------------------------------------------
        // Wait for the write pointer to cross into the read clock domain.
        //
        // The clocks are asynchronous, so we wait for EMPTY to deassert.
        // The repeat provides a generous timeout without requiring any
        // additional variable declarations.
        // ---------------------------------------------------------------------
        
        fork
        
            begin : wait_for_data
                wait (!empty);
            end
        
            begin : cdc_timeout
                repeat (20) @(posedge rd_clk);
        
                if (empty) begin
                    $error(
                        "[%0t ns] [FAIL] CDC timeout: FIFO remained EMPTY after 20 rd_clk cycles.",
                        $time
                    );
                    error_count++;
                end
            end
        
        join_any
        
        disable wait_for_data;
        disable cdc_timeout;
        
        // ---------------------------------------------------------------------
        // If data became visible, drain the FIFO.
        // ---------------------------------------------------------------------
        
        if (!empty) begin
            drain_fifo();
        end
        
        // ---------------------------------------------------------------------
        // Verify that the reference queue is empty.
        // ---------------------------------------------------------------------
        
        verify_reference_empty("TEST 5");

        // =====================================================================
        // TEST 6: MID-BURST RESET
        // =====================================================================

        $display("\n--- [TEST 6] Mid-Burst Asynchronous Reset ---");

        prepare_next_test();

        for (int i = 0; i < 8; i++) begin

            @(negedge wr_clk);

            wr_en   = 1'b1;
            wr_data = i + 1;

        end

        @(negedge wr_clk);
        wr_en = 1'b0;

        // Reset while FIFO is active.
        #15;

        wr_rst_n = 1'b0;
        rd_rst_n = 1'b0;

        clear_mailbox();

        #30;

        wr_rst_n = 1'b1;
        rd_rst_n = 1'b1;

        repeat (3) @(posedge wr_clk);
        repeat (3) @(posedge rd_clk);

        if (!empty || full) begin

            $error(
                "[%0t ns] [FAIL] Mid-burst reset failed! empty=%0b full=%0b",
                $time,
                empty,
                full
            );

            error_count++;

        end
        else begin

            $display(
                "[%0t ns] [PASS] Mid-burst reset successfully cleared FIFO state.",
                $time
            );

        end

        verify_reference_empty("TEST 6");

        // =====================================================================
        // TEST 7: POINTER WRAPAROUND
        // =====================================================================

        $display("\n--- [TEST 7] Pointer Wraparound ---");

        prepare_next_test();

        for (int k = 0; k < (DEPTH * 8); k++) begin

            // ------------------------------------------------------------
            // WRITE SIDE
            // ------------------------------------------------------------

            @(negedge wr_clk);

            if (!full) begin

                wr_en   = 1'b1;
                wr_data = k[DATA_WIDTH-1:0];

            end
            else begin

                wr_en = 1'b0;

            end

            // ------------------------------------------------------------
            // READ SIDE
            // ------------------------------------------------------------

            @(negedge rd_clk);

            if (!empty)
                rd_en = 1'b1;
            else
                rd_en = 1'b0;

        end

        @(negedge wr_clk);
        wr_en = 1'b0;

        @(negedge rd_clk);
        rd_en = 1'b0;

        drain_fifo();

        verify_reference_empty("TEST 7");

        // =====================================================================
        // TEST 8: CLOCK RATIO STRESS
        // =====================================================================

        $display("\n--- [TEST 8] Dynamic Clock Ratio Change & Stress Traffic ---");

        prepare_next_test();

        wr_clk_period = 30.0;
        rd_clk_period = 8.0;

        fork

            // ------------------------------------------------------------
            // WRITE PROCESS
            // ------------------------------------------------------------

            begin

                repeat (150) begin

                    @(negedge wr_clk);

                    if (!full) begin

                        wr_en   = $urandom_range(0, 1);
                        wr_data = $urandom();

                    end
                    else begin

                        wr_en = 1'b0;

                    end

                end

                @(negedge wr_clk);
                wr_en = 1'b0;

            end

            // ------------------------------------------------------------
            // READ PROCESS
            // ------------------------------------------------------------

            begin

                repeat (300) begin

                    @(negedge rd_clk);

                    if (!empty)
                        rd_en = $urandom_range(0, 1);
                    else
                        rd_en = 1'b0;

                end

                @(negedge rd_clk);
                rd_en = 1'b0;

            end

        join

        #100;

        drain_fifo();

        repeat (5) @(posedge rd_clk);

        verify_reference_empty("TEST 8");

        // =====================================================================
        // FINAL SUMMARY
        // =====================================================================

        $display("\n========================================================");
        $display("                 VERIFICATION SUMMARY");
        $display("========================================================");

        $display(
            " Total Write Attempts  : %0d",
            total_writes
        );

        $display(
            " Accepted Writes        : %0d",
            accepted_writes
        );

        $display(
            " Total Read Attempts    : %0d",
            total_reads
        );

        $display(
            " Accepted Reads         : %0d",
            accepted_reads
        );

        $display(
            " Reference Queue        : %0d item(s)",
            ref_mbx.num()
        );

        $display(
            " Total Error Count      : %0d",
            error_count
        );

        $display("--------------------------------------------------------");

        if ((error_count == 0) &&
            (ref_mbx.num() == 0)) begin

            $display(" STATUS: [*** TEST PASSED ***]");

        end
        else begin

            $display(" STATUS: [*** TEST FAILED ***]");

        end

        $display("========================================================\n");

        $finish;

    end

endmodule
