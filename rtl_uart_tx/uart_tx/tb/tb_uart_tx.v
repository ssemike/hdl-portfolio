
`timescale 1ns/1ps

module tb_uart_tx;

    localparam integer DATA_BITS = 8;
    localparam integer BAUD_DIV  = 16;

    integer errors = 0;
    integer b;

    reg clk;
    reg rst;
    reg baud_tick;
    reg tx_start;
    reg [DATA_BITS-1:0] data_in;

    reg [DATA_BITS-1:0] expected_byte;

    wire tx;
    wire busy;

    uart_tx #(
        .DATA_BITS(DATA_BITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    // Clock: 100 MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Wait for one baud tick
    task automatic wait_baud;
        integer k;
        begin
            for (k = 0; k < BAUD_DIV; k = k + 1) begin
                @(negedge clk);
                baud_tick = (k == BAUD_DIV - 1);

                @(posedge clk);
                #1;
            end

            baud_tick = 1'b0;
        end
    endtask

    // Main test
    initial begin

        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        rst = 1'b0;
        baud_tick = 1'b0;
        tx_start = 1'b0;
        data_in = 8'h00;

        expected_byte = 8'hA5;

        // =================================
        // TEST 1: RESET
        // =================================

        @(negedge clk);
        rst = 1'b1;

        @(posedge clk);
        #1;

        if (tx !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [reset]");
            errors = errors + 1;
        end else begin
            $display("PASS [reset]");
        end

        @(negedge clk);
        rst = 1'b0;

        // =================================
        // TEST 2: START TRANSMISSION
        // =================================

        @(negedge clk);
        data_in = expected_byte;
        tx_start = 1'b1;

        @(posedge clk);
        #1;

        if (busy !== 1'b1) begin
            $display("FAIL [start_busy]");
            errors = errors + 1;
        end else begin
            $display("PASS [start_busy]");
        end

        @(negedge clk);
        tx_start = 1'b0;

        // =================================
        // TEST 3: START BIT
        // =================================

        wait_baud();

        if (tx !== 1'b0) begin
            $display("FAIL [start_bit]: got %b expected 0", tx);
            errors = errors + 1;
        end else begin
            $display("PASS [start_bit]");
        end

        // =================================
        // TEST 4: DATA BITS
        // =================================

        for (b = 0; b < DATA_BITS; b = b + 1) begin

            wait_baud();

            if (tx !== expected_byte[b]) begin
                $display(
                    "FAIL [data_bit_%0d]: got %b expected %b",
                    b, tx, expected_byte[b]
                );
                errors = errors + 1;
            end else begin
                $display("PASS [data_bit_%0d]: %b",
                         b, tx);
            end

        end

        // =================================
        // TEST 5: STOP BIT
        // =================================

        wait_baud();

        if (tx !== 1'b1) begin
            $display("FAIL [stop_bit]: got %b expected 1", tx);
            errors = errors + 1;
        end else begin
            $display("PASS [stop_bit]");
        end

        // =================================
        // TEST 6: RETURN TO IDLE
        // =================================

        wait_baud();

        if (tx !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [return_idle]: tx=%b busy=%b",
                     tx, busy);
            errors = errors + 1;
        end else begin
            $display("PASS [return_idle]");
        end

        // =================================
        // TEST 7: MID-TRANSMISSION RESET
        // =================================

        @(negedge clk);
        data_in = 8'hFF;
        tx_start = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        tx_start = 1'b0;

        // Advance into transmission
        wait_baud();

        @(negedge clk);
        rst = 1'b1;
        baud_tick = 1'b0;

        @(posedge clk);
        #1;

        if (tx !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [mid_frame_reset]");
            errors = errors + 1;
        end else begin
            $display("PASS [mid_frame_reset]");
        end

        @(negedge clk);
        rst = 1'b0;

        // =================================
        // FINAL RESULT
        // =================================

        if (errors == 0) begin
            $display("==============================");
            $display("TEST PASSED");
            $display("==============================");
        end else begin
            $display("==============================");
            $display("TEST FAILED (%0d error(s))", errors);
            $display("==============================");
            $fatal(1);
        end

        $finish;

    end

endmodule
