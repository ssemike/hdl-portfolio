`timescale 1ns/1ps

module tb_debouncer;
    localparam integer STABLE_TICKS = 3;
    localparam integer WIDTH        = 4;

    integer errors = 0;
    integer i;

    reg  clk;
    reg  rst;
    reg  tick;
    reg  noisy_in;
    wire clean_out;

    debouncer #(
        .STABLE_TICKS(STABLE_TICKS),
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .noisy_in(noisy_in),
        .clean_out(clean_out)
    );

    // 10 ns clock period (posedge at t = 5, 15, 25, ...)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic step_and_check;
        input      t_rst;
        input      t_tick;
        input      t_noisy;
        input      expected_clean;
        input [8*40-1:0] msg;
        begin
            @(negedge clk);
            rst      = t_rst;
            tick     = t_tick;
            noisy_in = t_noisy;

            @(posedge clk);
            #1;
            if (clean_out !== expected_clean) begin
                $display("FAIL [%0s] at t=%0t: got clean_out=%b, expected %b",
                         msg, $time, clean_out, expected_clean);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_debouncer.vcd");
        $dumpvars(0, tb_debouncer);

        // 1. Reset state
        step_and_check(1'b1, 1'b0, 1'b0, 1'b0, "rst_asserted");

        // 2. Bounce chatter (not enough consecutive ticks to switch)
        // Edge 1: noisy_in=1 -> sync_0=1, sync_1=0, clean_out=0
        step_and_check(1'b0, 1'b1, 1'b1, 1'b0, "bounce_1_sync0");
        // Edge 2: noisy_in=0 -> sync_0=0, sync_1=1 (tick1: cnt becomes 1), clean_out=0
        step_and_check(1'b0, 1'b1, 1'b0, 1'b0, "bounce_2_sync1");
        // Edge 3: noisy_in=0 -> sync_0=0, sync_1=0 (tick2: cnt resets to 0), clean_out=0
        step_and_check(1'b0, 1'b1, 1'b0, 1'b0, "bounce_3_back_to_0");

        // 3. Sustained press (noisy_in=1 held steady)
        // Edge 4: noisy_in=1 -> sync_0=1, sync_1=0, clean_out=0
        step_and_check(1'b0, 1'b1, 1'b1, 1'b0, "press_sync0");
        // Edge 5: noisy_in=1 -> sync_0=1, sync_1=1 (tick1: cnt=1), clean_out=0
        step_and_check(1'b0, 1'b1, 1'b1, 1'b0, "press_tick1");
        // Edge 6: noisy_in=1 -> sync_0=1, sync_1=1 (tick2: cnt=2), clean_out=0
        step_and_check(1'b0, 1'b1, 1'b1, 1'b0, "press_tick2");
        // Edge 7: noisy_in=1 -> sync_0=1, sync_1=1 (tick3: cnt==2 -> clean_out=1!)
        step_and_check(1'b0, 1'b1, 1'b1, 1'b1, "press_settled_high");

        // Extra steady cycles keep clean_out=1
        for (i = 0; i < 2; i = i + 1) begin
            step_and_check(1'b0, 1'b1, 1'b1, 1'b1, "hold_high");
        end

        // 4. Sustained release (noisy_in=0 held steady)
        // Edge 10: noisy_in=0 -> sync_0=0, sync_1=1, clean_out=1
        step_and_check(1'b0, 1'b1, 1'b0, 1'b1, "release_sync0");
        // Edge 11: noisy_in=0 -> sync_0=0, sync_1=0 (tick1: cnt=1), clean_out=1
        step_and_check(1'b0, 1'b1, 1'b0, 1'b1, "release_tick1");
        // Edge 12: noisy_in=0 -> sync_0=0, sync_1=0 (tick2: cnt=2), clean_out=1
        step_and_check(1'b0, 1'b1, 1'b0, 1'b1, "release_tick2");
        // Edge 13: noisy_in=0 -> sync_0=0, sync_1=0 (tick3: cnt==2 -> clean_out=0!)
        step_and_check(1'b0, 1'b1, 1'b0, 1'b0, "release_settled_low");

        // 5. Synchronous reset
        step_and_check(1'b1, 1'b0, 1'b1, 1'b0, "mid_run_reset");

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED (%0d error(s))", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule
