`timescale 1ns/1ps

module spi_master #(
    parameter integer DATA_WIDTH = 8,
    parameter integer CLK_DIV    = 2
) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire                  miso,
    output reg                   sclk,
    output reg                   mosi,
    output reg                   cs_n,
    output reg                   busy,
    output reg                   done,
    output reg  [DATA_WIDTH-1:0] rx_data
);

    localparam integer EFF_DIV = (CLK_DIV < 1) ? 1 : CLK_DIV;

    reg [31:0]           clk_cnt;
    reg [31:0]           bit_cnt;
    reg [DATA_WIDTH-1:0] tx_shift;
    reg [DATA_WIDTH-1:0] rx_shift;

    always @(posedge clk) begin
        if (rst) begin
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            cs_n     <= 1'b1;
            busy     <= 1'b0;
            done     <= 1'b0;
            rx_data  <= {DATA_WIDTH{1'b0}};
            clk_cnt  <= 32'd0;
            bit_cnt  <= 32'd0;
            tx_shift <= {DATA_WIDTH{1'b0}};
            rx_shift <= {DATA_WIDTH{1'b0}};
        end else begin
            done <= 1'b0;

            if (!busy) begin
                sclk <= 1'b0;
                cs_n <= 1'b1;
                if (start) begin
                    busy     <= 1'b1;
                    cs_n     <= 1'b0;
                    sclk     <= 1'b0;
                    mosi     <= tx_data[DATA_WIDTH-1];
                    tx_shift <= {tx_data[DATA_WIDTH-2:0], 1'b0};
                    rx_shift <= {DATA_WIDTH{1'b0}};
                    clk_cnt  <= 32'd0;
                    bit_cnt  <= 32'd0;
                end
            end else begin
                if (clk_cnt == EFF_DIV - 1) begin
                    clk_cnt <= 32'd0;
                    if (sclk == 1'b0) begin
                        // Rising edge of sclk: sample MISO
                        sclk     <= 1'b1;
                        rx_shift <= {rx_shift[DATA_WIDTH-2:0], miso};
                    end else begin
                        // Falling edge of sclk: advance bit or complete frame
                        sclk <= 1'b0;
                        if (bit_cnt == DATA_WIDTH - 1) begin
                            busy    <= 1'b0;
                            cs_n    <= 1'b1;
                            done    <= 1'b1;
                            rx_data <= rx_shift;
                            bit_cnt <= 32'd0;
                        end else begin
                            bit_cnt  <= bit_cnt + 32'd1;
                            mosi     <= tx_shift[DATA_WIDTH-1];
                            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                        end
                    end
                end else begin
                    clk_cnt <= clk_cnt + 32'd1;
                end
            end
        end
    end

endmodule
