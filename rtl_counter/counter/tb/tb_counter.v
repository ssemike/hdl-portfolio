`timescale 1ns/1ps

module tb_counter;
    localparam integer WIDTH = 4;

    integer errors = 0;

    reg              clk;
    reg              rst;
    reg              load;
    reg  [WIDTH-1:0] data_in4;
    wire [WIDTH-1:0] count4;

    counter #(.WIDTH(WIDTH)) dut4 (
        .clk(clk),
        .rst(rst),
        .load(load),
        .data_in(data_in4),
        .count(count4)
    );

    // 100 MHz style clock (10 ns period: posedge at 5, 15, 25, ...)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Helper task: drive stimulus cleanly after a clock edge, advance one
    // full clock cycle, and check count4 against an expected value.
    task automatic apply_and_check;
        input                  t_rst;
        input                  t_load;
        input      [WIDTH-1:0] t_data;
        input      [WIDTH-1:0] expected;
        input      [8*40-1:0]  label;
        begin
            @(negedge clk);
            rst      = t_rst;
            load     = t_load;
            data_in4 = t_data;

            // Wait for the active posedge that samples inputs and updates count,
            // then sample after non-blocking assignments settle.
            @(posedge clk);
            #1;
            if (count4 !== expected) begin
                $display("ERROR [%0s] at t=%0t: got %0h, expected %0h",
                         label, $time, count4, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_counter.vcd");
        $dumpvars(0, tb_counter);

        rst      = 1'b1;
        load     = 1'b0;
        data_in4 = {WIDTH{1'b0}};

        // 1. Synchronous reset check
        apply_and_check(1'b1, 1'b0, 4'h0, 4'h0, "reset_asserted");
        apply_and_check(1'b0, 1'b0, 4'h0, 4'h1, "first_count_after_reset");
        apply_and_check(1'b0, 1'b0, 4'h0, 4'h2, "second_count_after_reset");

        // 2. Parallel load check
        apply_and_check(1'b0, 1'b1, 4'hA, 4'hA, "load_0xA");
        apply_and_check(1'b0, 1'b0, 4'h0, 4'hB, "count_after_load_0xB");

        // 3. Reset priority over load
        apply_and_check(1'b1, 1'b1, 4'hF, 4'h0, "rst_overrides_load");

        // 4. Rollover / wrap-around from 4'hF -> 4'h0
        apply_and_check(1'b0, 1'b1, 4'hF, 4'hF, "load_max_0xF");
        apply_and_check(1'b0, 1'b0, 4'h0, 4'h0, "wrap_0xF_to_0x0");
        apply_and_check(1'b0, 1'b0, 4'h0, 4'h1, "count_after_wrap_0x1");

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED with %0d error(s)", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule