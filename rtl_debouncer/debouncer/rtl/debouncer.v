`timescale 1ns/1ps

module debouncer #(
    parameter integer STABLE_TICKS = 4,
    parameter integer WIDTH        = 4
) (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire noisy_in,
    output reg  clean_out
);

    reg             sync_0;
    /* verilator lint_off UNUSEDSIGNAL */
    reg             sync_1; // retained as second synchronizer stage
    /* verilator lint_on UNUSEDSIGNAL */
    reg [WIDTH-1:0] cnt;
    localparam [WIDTH-1:0] STABLE_LIMIT = WIDTH'(STABLE_TICKS - 1);

    always @(posedge clk) begin
        if (rst) begin
            sync_0    <= 1'b0;
            sync_1    <= 1'b0;
            cnt       <= {WIDTH{1'b0}};
            clean_out <= 1'b0;
        end else begin
            // 2-stage synchronizer for raw external input
            sync_0 <= noisy_in;
            sync_1 <= sync_0;

            if (tick) begin
                if (sync_0 == clean_out) begin
                    cnt <= {WIDTH{1'b0}};
                end else if (cnt == STABLE_LIMIT) begin
                    clean_out <= sync_0;
                    cnt       <= {WIDTH{1'b0}};
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end
        end
    end

endmodule
