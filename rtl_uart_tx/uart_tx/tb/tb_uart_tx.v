`timescale 1ns/1ps

module tb_uart_tx;
    localparam integer DATA_BITS = 8;

    integer errors = 0;
    integer b;

    reg                 clk;
    reg                 rst;
    reg                 baud_tick;
    reg                 tx_start;
    reg [DATA_BITS-1:0] data_in;
    reg [DATA_BITS-1:0] expected_byte;
    wire                tx;
    wire                busy;

    uart_tx #(.DATA_BITS(DATA_BITS)) dut (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    // 10 ns clock period (posedge at t = 5, 15, 25, ...)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic step_clk;
        input      t_rst;
        input      t_tick;
        input      t_start;
        input [DATA_BITS-1:0] t_data;
        begin
            @(negedge clk);
            rst       = t_rst;
            baud_tick = t_tick;
            tx_start  = t_start;
            data_in   = t_data;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        expected_byte = 8'hA5;

        // 1. Reset check
        step_clk(1'b1, 1'b0, 1'b0, 8'h00);
        if (tx !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [reset] at t=%0t: tx=%b busy=%b (expected tx=1 busy=0)",
                     $time, tx, busy);
            errors = errors + 1;
        end

        // 2. Start transmission of 8'hA5
        step_clk(1'b0, 1'b1, 1'b1, expected_byte);
        if (busy !== 1'b1) begin
            $display("FAIL [start_busy] at t=%0t: expected busy=1, got %b",
                     $time, busy);
            errors = errors + 1;
        end

        // Start bit (0)
        step_clk(1'b0, 1'b1, 1'b0, 8'h00);
        if (tx !== 1'b0) begin
            $display("FAIL [start_bit] at t=%0t: expected tx=0, got %b",
                     $time, tx);
            errors = errors + 1;
        end

        // 8 data bits (LSB first)
        for (b = 0; b < DATA_BITS; b = b + 1) begin
            step_clk(1'b0, 1'b1, 1'b0, 8'h00);
            if (tx !== expected_byte[b]) begin
                $display("FAIL [bit_%0d] at t=%0t: got tx=%b, expected %b",
                         b, $time, tx, expected_byte[b]);
                errors = errors + 1;
            end
        end

        // Stop bit (1)
        step_clk(1'b0, 1'b1, 1'b0, 8'h00);
        if (tx !== 1'b1) begin
            $display("FAIL [stop_bit] at t=%0t: expected tx=1, got %b",
                     $time, tx);
            errors = errors + 1;
        end

        // Return to idle
        step_clk(1'b0, 1'b1, 1'b0, 8'h00);
        if (tx !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [return_idle] at t=%0t: tx=%b busy=%b (expected tx=1 busy=0)",
                     $time, tx, busy);
            errors = errors + 1;
        end

        // 3. Mid-frame reset check
        step_clk(1'b0, 1'b1, 1'b1, 8'hFF);
        step_clk(1'b1, 1'b0, 1'b0, 8'h00);
        if (tx !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [mid_frame_reset] at t=%0t: tx=%b busy=%b",
                     $time, tx, busy);
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