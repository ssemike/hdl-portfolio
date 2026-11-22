`timescale 1ns/1ps

module pwm #(
    parameter integer WIDTH  = 8,
    parameter integer PERIOD = 100
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    input  wire [WIDTH-1:0] duty,
    output reg              pwm_out
);

    localparam integer EFF_PERIOD = (PERIOD < 1) ? 1 : PERIOD;
    localparam [WIDTH-1:0] LAST_CNT   = WIDTH'(EFF_PERIOD - 1);
    localparam [WIDTH-1:0] STEP_ONE   = {{(WIDTH-1){1'b0}}, 1'b1};

    reg [WIDTH-1:0] cnt;
    reg [WIDTH-1:0] duty_q;
    reg [WIDTH-1:0] next_cnt;
    reg [WIDTH-1:0] active_duty;

    always @(*) begin
        if (cnt >= LAST_CNT) begin
            next_cnt = {WIDTH{1'b0}};
        end else begin
            next_cnt = cnt + STEP_ONE;
        end

        if (cnt == {WIDTH{1'b0}}) begin
            active_duty = duty;
        end else begin
            active_duty = duty_q;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            cnt     <= {WIDTH{1'b0}};
            duty_q  <= {WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else if (en) begin
            cnt     <= next_cnt;
            duty_q  <= active_duty;
            pwm_out <= (next_cnt < active_duty) ? 1'b1 : 1'b0;
        end else begin
            pwm_out <= 1'b0;
        end
    end

endmodule
