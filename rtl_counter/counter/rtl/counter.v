`timescale 1ns/1ps

module counter #(
    parameter integer WIDTH = 4
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               load,
    input  wire [WIDTH-1:0]   data_in,
    output reg  [WIDTH-1:0]   count
);

    localparam [WIDTH-1:0] STEP_ONE = {{(WIDTH-1){1'b0}}, 1'b1};

    always @(posedge clk) begin
        if (rst) begin
            count <= {WIDTH{1'b0}};
        end else if (load) begin
            count <= data_in;
        end else begin
            count <= count + STEP_ONE;
        end
    end

endmodule
