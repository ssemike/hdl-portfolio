`timescale 1ns/1ps

module tb_tick_gen;
    localparam integer DIV = 5;

    integer errors = 0;
    integer i;

    reg  clk;
    reg  rst;
    reg  en;
    wire tick;

    tick_gen #(.DIV(DIV)) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .tick(tick)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic step_and_check;
        input                 t_rst;
        input                 t_en;
        input                 expected_tick;
        input     [8*40-1:0]  msg;
        begin
            @(negedge clk);
            rst = t_rst;
            en  = t_en;

            @(posedge clk);
            #1;
            if (tick !== expected_tick) begin
                $display("FAIL [%0s] at t=%0t: got tick=%b, expected %b",
                         msg, $time, tick, expected_tick);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_tick_gen.vcd");
        $dumpvars(0, tb_tick_gen);

        rst = 1'b1;
        en  = 1'b0;

        // 1. Reset holds tick low
        step_and_check(1'b1, 1'b1, 1'b0, "rst_asserted");

        // 2. First full DIV=5 cycle: counts 0, 1, 2, 3 (tick=0), then 4 (tick=1)
        for (i = 0; i < DIV - 1; i = i + 1) begin
            step_and_check(1'b0, 1'b1, 1'b0, "pre_tick_cycle");
        end
        step_and_check(1'b0, 1'b1, 1'b1, "tick_pulse_cycle_1");

        // 3. Second full DIV=5 cycle immediately following
        for (i = 0; i < DIV - 1; i = i + 1) begin
            step_and_check(1'b0, 1'b1, 1'b0, "cycle2_pre_tick");
        end
        step_and_check(1'b0, 1'b1, 1'b1, "tick_pulse_cycle_2");

        // 4. Pause with en=0: tick stays 0 and counter holds
        step_and_check(1'b0, 1'b0, 1'b0, "disabled_hold_1");
        step_and_check(1'b0, 1'b0, 1'b0, "disabled_hold_2");

        // 5. Synchronous reset mid-operation
        step_and_check(1'b1, 1'b1, 1'b0, "mid_run_reset");
        for (i = 0; i < DIV - 1; i = i + 1) begin
            step_and_check(1'b0, 1'b1, 1'b0, "post_reset_pre_tick");
        end
        step_and_check(1'b0, 1'b1, 1'b1, "post_reset_tick");

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED (%0d error(s))", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule