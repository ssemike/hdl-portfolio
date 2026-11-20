`timescale 1ns/1ps

module alu #(
    parameter integer WIDTH = 4
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [2:0]       op,
    output reg  [WIDTH-1:0] y,
    output reg              carry_out,
    output wire             zero
);
    localparam [2:0]
        OP_ADD = 3'd0,
        OP_SUB = 3'd1,
        OP_AND = 3'd2,
        OP_OR  = 3'd3,
        OP_XOR = 3'd4,
        OP_SLL = 3'd5,
        OP_SRL = 3'd6,
        OP_SLT = 3'd7;

    reg [WIDTH:0] wide_tmp;

    always @(*) begin
        y         = {WIDTH{1'b0}};
        carry_out = 1'b0;
        wide_tmp  = {(WIDTH+1){1'b0}};

        case (op)
            OP_ADD: begin
                wide_tmp  = {1'b0, a} + {1'b0, b};
                y         = wide_tmp[WIDTH-1:0];
                carry_out = wide_tmp[WIDTH];
            end
            OP_SUB: begin
                wide_tmp  = {1'b0, a} - {1'b0, b};
                y         = wide_tmp[WIDTH-1:0];
                carry_out = wide_tmp[WIDTH];
            end
            OP_AND: begin
                y = a & b;
            end
            OP_OR: begin
                y = a | b;
            end
            OP_XOR: begin
                y = a ^ b;
            end
            OP_SLL: begin
                y = a << b[1:0];
            end
            OP_SRL: begin
                y = a >> b[1:0];
            end
            OP_SLT: begin
                y = ($signed(a) < $signed(b)) ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}};
            end
            default: begin
                y         = {WIDTH{1'b0}};
                carry_out = 1'b0;
            end
        endcase
    end

    assign zero = (y == {WIDTH{1'b0}});
endmodule
