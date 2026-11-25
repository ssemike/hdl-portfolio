`timescale 1ns/1ps

module i2c_master #(
    parameter integer CLK_DIV = 4
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [6:0] slave_addr,
    input  wire [7:0] tx_data,
    input  wire       sda_in,
    output reg        scl,
    output reg        sda_out,
    output reg        sda_oe,
    output reg        busy,
    output reg        done,
    output reg        nack_err
);

    localparam [3:0] S_IDLE      = 4'd0;
    localparam [3:0] S_START_A   = 4'd1;
    localparam [3:0] S_START_B   = 4'd2;
    localparam [3:0] S_ADDR_LOW  = 4'd3;
    localparam [3:0] S_ADDR_HIGH = 4'd4;
    localparam [3:0] S_ACK1_LOW  = 4'd5;
    localparam [3:0] S_ACK1_HIGH = 4'd6;
    localparam [3:0] S_DATA_LOW  = 4'd7;
    localparam [3:0] S_DATA_HIGH = 4'd8;
    localparam [3:0] S_ACK2_LOW  = 4'd9;
    localparam [3:0] S_ACK2_HIGH = 4'd10;
    localparam [3:0] S_STOP_LOW  = 4'd11;
    localparam [3:0] S_STOP_HIGH = 4'd12;
    localparam [3:0] S_STOP_DONE = 4'd13;

    localparam integer EFF_DIV = (CLK_DIV < 2) ? 2 : CLK_DIV;

    reg [3:0]  state;
    reg [31:0] div_cnt;
    reg [2:0]  bit_cnt;
    reg [7:0]  shift_reg;

    wire div_tick = (div_cnt == EFF_DIV - 1);

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            div_cnt   <= 32'd0;
            bit_cnt   <= 3'd0;
            shift_reg <= 8'd0;
            scl       <= 1'b1;
            sda_out   <= 1'b1;
            sda_oe    <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
            nack_err  <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    sda_oe  <= 1'b0;
                    busy    <= 1'b0;
                    div_cnt <= 32'd0;
                    bit_cnt <= 3'd0;
                    if (start) begin
                        busy      <= 1'b1;
                        nack_err  <= 1'b0;
                        shift_reg <= {slave_addr, 1'b0}; // 7-bit address + write (0)
                        state     <= S_START_A;
                    end
                end

                S_START_A: begin
                    // SCL high, drive SDA low to form START
                    scl     <= 1'b1;
                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_START_B;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_START_B: begin
                    // Pull SCL low so first address bit can be placed on SDA
                    scl <= 1'b0;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        bit_cnt <= 3'd0;
                        state   <= S_ADDR_LOW;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_ADDR_LOW: begin
                    scl     <= 1'b0;
                    sda_out <= shift_reg[7];
                    sda_oe  <= ~shift_reg[7]; // Drive 0 when bit is 0; release (1) when bit is 1
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_ADDR_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_ADDR_HIGH: begin
                    scl <= 1'b1;
                    if (div_tick) begin
                        div_cnt   <= 32'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 3'd0;
                            state   <= S_ACK1_LOW;
                        end else begin
                            bit_cnt <= bit_cnt + 3'd1;
                            state   <= S_ADDR_LOW;
                        end
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_ACK1_LOW: begin
                    scl     <= 1'b0;
                    sda_oe  <= 1'b0; // Release SDA for slave ACK
                    sda_out <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_ACK1_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_ACK1_HIGH: begin
                    scl <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        if (sda_in !== 1'b0) begin
                            nack_err <= 1'b1;
                        end
                        shift_reg <= tx_data;
                        bit_cnt   <= 3'd0;
                        state     <= S_DATA_LOW;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_DATA_LOW: begin
                    scl     <= 1'b0;
                    sda_out <= shift_reg[7];
                    sda_oe  <= ~shift_reg[7];
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_DATA_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_DATA_HIGH: begin
                    scl <= 1'b1;
                    if (div_tick) begin
                        div_cnt   <= 32'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 3'd0;
                            state   <= S_ACK2_LOW;
                        end else begin
                            bit_cnt <= bit_cnt + 3'd1;
                            state   <= S_DATA_LOW;
                        end
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_ACK2_LOW: begin
                    scl     <= 1'b0;
                    sda_oe  <= 1'b0; // Release SDA for slave data ACK
                    sda_out <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_ACK2_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_ACK2_HIGH: begin
                    scl <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        if (sda_in !== 1'b0) begin
                            nack_err <= 1'b1;
                        end
                        state <= S_STOP_LOW;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_STOP_LOW: begin
                    scl     <= 1'b0;
                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_STOP_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_STOP_HIGH: begin
                    // SCL high with SDA held low before releasing SDA high for STOP
                    scl     <= 1'b1;
                    sda_out <= 1'b0;
                    sda_oe  <= 1'b1;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        state   <= S_STOP_DONE;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                S_STOP_DONE: begin
                    // Release SDA high while SCL is high -> STOP condition
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    sda_oe  <= 1'b0;
                    if (div_tick) begin
                        div_cnt <= 32'd0;
                        busy    <= 1'b0;
                        done    <= 1'b1;
                        state   <= S_IDLE;
                    end else begin
                        div_cnt <= div_cnt + 32'd1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
