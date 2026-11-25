
`timescale 1ns/1ps

module uart_rx #(
    parameter integer DATA_BITS = 8,
    parameter integer OS_FACTOR = 16
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 sample_tick,
    input  wire                 rx,
    output reg  [DATA_BITS-1:0] rx_data,
    output reg                  rx_valid,
    output reg                  frame_err
);

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    localparam integer EFF_OS  = (OS_FACTOR < 4) ? 4 : OS_FACTOR;
    localparam integer HALF_OS = EFF_OS / 2;
    localparam integer FULL_OS = EFF_OS - 1;

    reg                 rx_sync_0;
    reg                 rx_sync_1;
    reg [1:0]           state;
    reg [31:0]          os_cnt;
    reg [31:0]          bit_idx;
    reg [DATA_BITS-1:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;

            state     <= STATE_IDLE;
            os_cnt    <= 32'd0;
            bit_idx   <= 32'd0;

            shift_reg <= {DATA_BITS{1'b0}};
            rx_data   <= {DATA_BITS{1'b0}};

            rx_valid  <= 1'b0;
            frame_err <= 1'b0;

        end else begin

            // Synchronize asynchronous UART input
            rx_sync_0 <= rx;
            rx_sync_1 <= rx_sync_0;

            // Event outputs: one-clock-cycle pulses
            rx_valid  <= 1'b0;
            frame_err <= 1'b0;

            case (state)

                // --------------------------------
                // IDLE: Wait for start bit
                // --------------------------------
                STATE_IDLE: begin
                    os_cnt  <= 32'd0;
                    bit_idx <= 32'd0;

                    if (rx_sync_1 == 1'b0) begin
                        state <= STATE_START;
                    end
                end

                // --------------------------------
                // START: Verify start bit at midpoint
                // --------------------------------
                STATE_START: begin
                    if (sample_tick) begin
                        if (os_cnt == HALF_OS - 1) begin
                            os_cnt <= 32'd0;

                            if (rx_sync_1 == 1'b0) begin
                                state <= STATE_DATA;
                            end else begin
                                // False start
                                state <= STATE_IDLE;
                            end

                        end else begin
                            os_cnt <= os_cnt + 32'd1;
                        end
                    end
                end

                // --------------------------------
                // DATA: Sample each data bit
                // --------------------------------
                STATE_DATA: begin
                    if (sample_tick) begin
                        if (os_cnt == FULL_OS) begin
                            os_cnt <= 32'd0;

                            // UART transmits LSB first
                            shift_reg <= {
                                rx_sync_1,
                                shift_reg[DATA_BITS-1:1]
                            };

                            if (bit_idx == DATA_BITS - 1) begin
                                bit_idx <= 32'd0;
                                state   <= STATE_STOP;
                            end else begin
                                bit_idx <= bit_idx + 32'd1;
                            end

                        end else begin
                            os_cnt <= os_cnt + 32'd1;
                        end
                    end
                end

                // --------------------------------
                // STOP: Validate stop bit
                // --------------------------------
                STATE_STOP: begin
                    if (sample_tick) begin
                        if (os_cnt == FULL_OS) begin
                            os_cnt <= 32'd0;
                            state  <= STATE_IDLE;

                            if (rx_sync_1 == 1'b1) begin
                                rx_data  <= shift_reg;
                                rx_valid <= 1'b1;
                            end else begin
                                frame_err <= 1'b1;
                            end

                        end else begin
                            os_cnt <= os_cnt + 32'd1;
                        end
                    end
                end

                default: begin
                    state  <= STATE_IDLE;
                    os_cnt <= 32'd0;
                end

            endcase
        end
    end

endmodule
