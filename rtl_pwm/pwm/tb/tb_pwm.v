`timescale 1ns/1ps

module tb_pwm;
    localparam integer WIDTH  = 4;
    localparam integer PERIOD = 10;

    integer errors = 0;
    integer i;
    integer high_count;

    reg             clk;
    reg             rst;
    reg             en;
    reg [WIDTH-1:0] duty;
    wire            pwm_out;

    pwm #(
        .WIDTH(WIDTH),
        .PERIOD(PERIOD)
    ) dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .duty(duty),
        .pwm_out(pwm_out)
    );

    // 10 ns clock period (posedge at t = 5, 15, 25, ...)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic run_period_and_check;
        input      [WIDTH-1:0] t_duty;
        input      integer     expected_highs;
        input      [8*40-1:0]  msg;
        begin
            high_count = 0;
            for (i = 0; i < PERIOD; i = i + 1) begin
                @(negedge clk);
                rst  = 1'b0;
                en   = 1'b1;
                duty = t_duty;

                @(posedge clk);
                #1;
                if (pwm_out === 1'b1) begin
                    high_count = high_count + 1;
                end else if (pwm_out !== 1'b0) begin
                    $display("FAIL [%0s] unknown pwm_out=%b at t=%0t",
                             msg, pwm_out, $time);
                    errors = errors + 1;
                end
            end

            if (high_count !== expected_highs) begin
                $display("FAIL [%0s]: got %0d high cycles, expected %0d",
                         msg, high_count, expected_highs);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_pwm.vcd");
        $dumpvars(0, tb_pwm);

        // 1. Synchronous reset
        @(negedge clk);
        rst  = 1'b1;
        en   = 1'b1;
        duty = 4'd5;
        @(posedge clk);
        #1;
        if (pwm_out !== 1'b0) begin
            $display("FAIL [rst_clears_pwm] at t=%0t: got %b, expected 0",
                     $time, pwm_out);
            errors = errors + 1;
        end

        // Align cleanly to start of period at cnt == 0
        run_period_and_check(4'd0, 0, "duty_0_percent");
        run_period_and_check(4'd3, 3, "duty_30_percent");
        run_period_and_check(4'd10, PERIOD, "duty_100_percent");

        // 5. Disable holds pwm_out low
        @(negedge clk);
        rst  = 1'b0;
        en   = 1'b0;
        duty = 4'd5;
        @(posedge clk);
        #1;
        if (pwm_out !== 1'b0) begin
            $display("FAIL [disabled_low] at t=%0t: got %b, expected 0",
                     $time, pwm_out);
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