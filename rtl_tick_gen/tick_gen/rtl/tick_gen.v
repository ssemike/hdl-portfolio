`timescale 1ns/1ps

module tick_gen #(
    parameter integer DIV = 10
) (
    input  wire clk,
    input  wire rst,
    input  wire en,
    output reg  tick
);

    localparam integer EFF_DIV = (DIV < 1) ? 1 : DIV;
    localparam integer WIDTH   = (EFF_DIV > 1) ? $clog2(EFF_DIV) : 1;
    localparam [WIDTH-1:0] LAST_COUNT = EFF_DIV[WIDTH-1:0] - 1'b1;

    reg [WIDTH-1:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= {WIDTH{1'b0}};
            tick  <= 1'b0;
        end else if (en) begin
            if (count == LAST_COUNT) begin
                count <= {WIDTH{1'b0}};
                tick  <= 1'b1;
            end else begin
                count <= count + 1'b1;
                tick  <= 1'b0;
            end
        end else begin
            tick  <= 1'b0;
        end
    end

endmodule
