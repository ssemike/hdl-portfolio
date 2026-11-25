
`timescale 1ns/1ps

module tb_uart_rx;

    localparam integer DATA_BITS = 8;
    localparam integer OS_FACTOR = 16;

    integer errors = 0;
    integer b;

    reg clk;
    reg rst;
    reg sample_tick;
    reg rx;

    wire [DATA_BITS-1:0] rx_data;
    wire rx_valid;
    wire frame_err;

    reg [DATA_BITS-1:0] tx_byte;
    reg [DATA_BITS-1:0] bad_byte;

    reg seen_valid;
    reg seen_frame_err;

    // DUT
    uart_rx #(
        .DATA_BITS(DATA_BITS),
        .OS_FACTOR(OS_FACTOR)
    ) dut (
        .clk(clk),
        .rst(rst),
        .sample_tick(sample_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .frame_err(frame_err)
    );

    // Clock: 100 MHz
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Monitor one-cycle DUT events
    always @(posedge clk) begin
        if (rst) begin
            seen_valid     <= 1'b0;
            seen_frame_err <= 1'b0;
        end else begin
            if (rx_valid)
                seen_valid <= 1'b1;

            if (frame_err)
                seen_frame_err <= 1'b1;
        end
    end

    // Send one UART bit
    task automatic send_bit;
        input bit_val;
        integer k;
        begin
            for (k = 0; k < OS_FACTOR; k = k + 1) begin
                @(negedge clk);
                rx = bit_val;
                sample_tick = 1'b1;

                @(posedge clk);
                #1;
            end
        end
    endtask

    // Main test sequence
    initial begin

        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        // Initialise signals
        rst         = 1'b0;
        sample_tick = 1'b0;
        rx          = 1'b1;

        tx_byte  = 8'hA5;
        bad_byte = 8'h3C;

        seen_valid     = 1'b0;
        seen_frame_err = 1'b0;

        // =====================================
        // TEST 1: RESET
        // =====================================

        @(negedge clk);
        rst = 1'b1;

        @(posedge clk);
        #1;

        if (rx_valid !== 1'b0 ||
            frame_err !== 1'b0 ||
            rx_data !== 8'h00) begin

            $display("FAIL [reset]");
            errors = errors + 1;

        end else begin
            $display("PASS [reset]");
        end

        // Release reset
        @(negedge clk);
        rst = 1'b0;

        // Allow synchronizer to settle
        repeat (3) @(posedge clk);

        // =====================================
        // TEST 2: VALID UART FRAME
        // =====================================

        seen_valid = 1'b0;

        send_bit(1'b0); // Start bit

        // Transmit 0xA5, LSB first
        for (b = 0; b < DATA_BITS; b = b + 1) begin
            send_bit(tx_byte[b]);
        end

        send_bit(1'b1); // Stop bit

        // Check received data
        if (seen_valid !== 1'b1) begin

            $display("FAIL [rx_valid_missing]");
            errors = errors + 1;

        end else if (rx_data !== tx_byte) begin

            $display("FAIL [rx_data]: got %02h, expected %02h",
                     rx_data, tx_byte);
            errors = errors + 1;

        end else begin

            $display("PASS [valid_frame]: received %02h", rx_data);

        end

        // =====================================
        // TEST 3: FRAMING ERROR
        // =====================================

        seen_frame_err = 1'b0;

        send_bit(1'b0); // Start bit

        // Transmit 0x3C, LSB first
        for (b = 0; b < DATA_BITS; b = b + 1) begin
            send_bit(bad_byte[b]);
        end

        send_bit(1'b0); // Invalid stop bit

        // Check framing error
        if (seen_frame_err !== 1'b1) begin

            $display("FAIL [frame_err]: framing error not detected");
            errors = errors + 1;

        end else begin

            $display("PASS [frame_err]: framing error detected");

        end

        // =====================================
        // FINAL RESULT
        // =====================================

        if (errors == 0) begin
            $display("==============================");
            $display("TEST PASSED");
            $display("==============================");
        end else begin
            $display("==============================");
            $display("TEST FAILED: %0d error(s)", errors);
            $display("==============================");
            $fatal(1);
        end

        $finish;

    end

endmodule
