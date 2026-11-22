`timescale 1ns/1ps

module tb_uart_rx;
    localparam integer DATA_BITS = 8;
    localparam integer OS_FACTOR = 16;

    integer errors = 0;
    integer b;
    integer t;
    integer wait_cycles;
    reg     got_valid;

    reg                 clk;
    reg                 rst;
    reg                 sample_tick;
    reg                 rx;
    wire [DATA_BITS-1:0] rx_data;
    wire                rx_valid;
    wire                frame_err;

    reg  [DATA_BITS-1:0] tx_byte;

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

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic send_bit;
        input bit_val;
        integer k;
        begin
            for (k = 0; k < OS_FACTOR; k = k + 1) begin
                @(negedge clk);
                rst         = 1'b0;
                sample_tick = 1'b1;
                rx          = bit_val;
                @(posedge clk);
                #1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        tx_byte   = 8'hA5;
        got_valid = 1'b0;

        // 1. Reset check
        @(negedge clk);
        rst         = 1'b1;
        sample_tick = 1'b0;
        rx          = 1'b1;
        @(posedge clk);
        #1;
        if (rx_valid !== 1'b0 || frame_err !== 1'b0 || rx_data !== 8'h00) begin
            $display("FAIL [reset] at t=%0t", $time);
            errors = errors + 1;
        end

        // Allow 2 idle cycles for synchronizer to settle to 1
        send_bit(1'b1);

        // 2. Valid 8N1 frame for 8'hA5 (LSB first)
        send_bit(1'b0); // Start bit
        for (b = 0; b < DATA_BITS; b = b + 1) begin
            send_bit(tx_byte[b]);
        end
        send_bit(1'b1); // Valid stop bit

        // Wait up to a few cycles for rx_valid pulse
        wait_cycles = 0;
        while (!got_valid && wait_cycles < 20) begin
            if (rx_valid === 1'b1) begin
                got_valid = 1'b1;
                if (rx_data !== tx_byte) begin
                    $display("FAIL [rx_data]: got 8'h%02h, expected 8'h%02h",
                             rx_data, tx_byte);
                    errors = errors + 1;
                end
            end
            @(negedge clk);
            sample_tick = 1'b1;
            rx          = 1'b1;
            @(posedge clk);
            #1;
            wait_cycles = wait_cycles + 1;
        end

        if (!got_valid) begin
            $display("FAIL [rx_valid_missing]: never saw rx_valid=1");
            errors = errors + 1;
        end

        // 3. Framing error test (stop bit = 0)
        send_bit(1'b0); // Start bit
        for (b = 0; b < DATA_BITS; b = b + 1) begin
            send_bit(8'h3C >> b);
        end
        send_bit(1'b0); // Bad stop bit

        // Step a couple cycles and check frame_err
        for (t = 0; t < 3; t = t + 1) begin
            @(negedge clk);
            sample_tick = 1'b1;
            rx          = 1'b1;
            @(posedge clk);
            #1;
        end

        if (frame_err !== 1'b1) begin
            $display("FAIL [frame_err]: expected frame_err=1, got %b", frame_err);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED (%0d error(s))", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule
