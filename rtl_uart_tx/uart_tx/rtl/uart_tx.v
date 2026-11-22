`timescale 1ns/1ps

module uart_tx #(
    parameter integer DATA_BITS = 8
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 baud_tick,
    input  wire                 tx_start,
    input  wire [DATA_BITS-1:0] data_in,
    output reg                  tx,
    output wire                 busy
);

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    reg [1:0]           state;
    reg [DATA_BITS-1:0] shift_reg;
    reg [2:0]           bit_idx;

    assign busy = (state != STATE_IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state     <= STATE_IDLE;
            shift_reg <= {DATA_BITS{1'b0}};
            bit_idx   <= 3'd0;
            tx        <= 1'b1;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx      <= 1'b1;
                    bit_idx <= 3'd0;
                    if (tx_start) begin
                        shift_reg <= data_in;
                        state     <= STATE_START;
                    end
                end

                STATE_START: begin
                    tx <= 1'b0;
                    if (baud_tick) begin
                        state <= STATE_DATA;
                    end
                end

                STATE_DATA: begin
                    tx <= shift_reg[0];
                    if (baud_tick) begin
                        shift_reg <= {1'b0, shift_reg[DATA_BITS-1:1]};
                        if (bit_idx == 3'(DATA_BITS - 1)) begin
                            bit_idx <= 3'd0;
                            state   <= STATE_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end
                end

                STATE_STOP: begin
                    tx <= 1'b1;
                    if (baud_tick) begin
                        state <= STATE_IDLE;
                    end
                end

                default: begin
                    state <= STATE_IDLE;
                    tx    <= 1'b1;
                end
            endcase
        end
    end

endmodule
