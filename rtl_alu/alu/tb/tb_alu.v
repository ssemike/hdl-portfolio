`timescale 1ns/1ps

module tb_alu;
    integer errors = 0;

    // ---------------------------------------------------------
    // 1. Exhaustive testbench at N = 4
    // ---------------------------------------------------------
    reg  [3:0] a4, b4;
    reg  [2:0] op4;
    wire [3:0] y4;
    wire       carry4, zero4;

    alu #(.WIDTH(4)) dut4 (
        .a(a4),
        .b(b4),
        .op(op4),
        .y(y4),
        .carry_out(carry4),
        .zero(zero4)
    );

    reg [4:0] exp_wide4;
    reg [3:0] exp_y4;
    reg       exp_c4, exp_z4;

    task automatic check4(input [3:0] ia, input [3:0] ib, input [2:0] iop);
        begin
            a4  = ia;
            b4  = ib;
            op4 = iop;
            #1;

            exp_wide4 = 5'd0;
            exp_y4    = 4'd0;
            exp_c4    = 1'b0;

            case (iop)
                3'd0: begin
                    exp_wide4 = {1'b0, ia} + {1'b0, ib};
                    exp_y4    = exp_wide4[3:0];
                    exp_c4    = exp_wide4[4];
                end
                3'd1: begin
                    exp_wide4 = {1'b0, ia} - {1'b0, ib};
                    exp_y4    = exp_wide4[3:0];
                    exp_c4    = exp_wide4[4];
                end
                3'd2: exp_y4 = ia & ib;
                3'd3: exp_y4 = ia | ib;
                3'd4: exp_y4 = ia ^ ib;
                3'd5: exp_y4 = ia << ib[1:0];
                3'd6: exp_y4 = ia >> ib[1:0];
                3'd7: exp_y4 = ($signed(ia) < $signed(ib)) ? 4'd1 : 4'd0;
                default: exp_y4 = 4'd0;
            endcase
            exp_z4 = (exp_y4 == 4'd0);

            if ((y4 !== exp_y4) || (carry4 !== exp_c4) || (zero4 !== exp_z4)) begin
                errors = errors + 1;
                $display("FAIL N=4 op=%0d a=%0h b=%0h: got y=%0h c=%0b z=%0b, exp y=%0h c=%0b z=%0b at %0t",
                         iop, ia, ib, y4, carry4, zero4, exp_y4, exp_c4, exp_z4, $time);
            end
        end
    endtask

    // ---------------------------------------------------------
    // 2. 1,000 fixed-seed random vectors at N = 8
    // ---------------------------------------------------------
    reg  [7:0] a8, b8;
    reg  [2:0] op8;
    wire [7:0] y8;
    wire       carry8, zero8;

    alu #(.WIDTH(8)) dut8 (
        .a(a8),
        .b(b8),
        .op(op8),
        .y(y8),
        .carry_out(carry8),
        .zero(zero8)
    );

    reg [8:0] exp_wide8;
    reg [7:0] exp_y8;
    reg       exp_c8, exp_z8;
    integer   seed = 20261119;
    integer   i;

    task automatic check8(input [7:0] ia, input [7:0] ib, input [2:0] iop);
        begin
            a8  = ia;
            b8  = ib;
            op8 = iop;
            #1;

            exp_wide8 = 9'd0;
            exp_y8    = 8'd0;
            exp_c8    = 1'b0;

            case (iop)
                3'd0: begin
                    exp_wide8 = {1'b0, ia} + {1'b0, ib};
                    exp_y8    = exp_wide8[7:0];
                    exp_c8    = exp_wide8[8];
                end
                3'd1: begin
                    exp_wide8 = {1'b0, ia} - {1'b0, ib};
                    exp_y8    = exp_wide8[7:0];
                    exp_c8    = exp_wide8[8];
                end
                3'd2: exp_y8 = ia & ib;
                3'd3: exp_y8 = ia | ib;
                3'd4: exp_y8 = ia ^ ib;
                3'd5: exp_y8 = ia << ib[1:0];
                3'd6: exp_y8 = ia >> ib[1:0];
                3'd7: exp_y8 = ($signed(ia) < $signed(ib)) ? 8'd1 : 8'd0;
                default: exp_y8 = 8'd0;
            endcase
            exp_z8 = (exp_y8 == 8'd0);

            if ((y8 !== exp_y8) || (carry8 !== exp_c8) || (zero8 !== exp_z8)) begin
                errors = errors + 1;
                $display("FAIL N=8 op=%0d a=%0h b=%0h: got y=%0h c=%0b z=%0b, exp y=%0h c=%0b z=%0b at %0t",
                         iop, ia, ib, y8, carry8, zero8, exp_y8, exp_c8, exp_z8, $time);
            end
        end
    endtask

    integer idx_op, idx_a, idx_b;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_alu);

        a4 = 0; b4 = 0; op4 = 0;
        a8 = 0; b8 = 0; op8 = 0;
        #5;

        // Exhaustive N=4 (8 ops * 16 * 16 = 2048 vectors)
        for (idx_op = 0; idx_op < 8; idx_op = idx_op + 1) begin
            for (idx_a = 0; idx_a < 16; idx_a = idx_a + 1) begin
                for (idx_b = 0; idx_b < 16; idx_b = idx_b + 1) begin
                    check4(idx_a[3:0], idx_b[3:0], idx_op[2:0]);
                end
            end
        end

        // 1,000 fixed-seed random vectors at N=8
        for (i = 0; i < 1000; i = i + 1) begin
            check8($random(seed), $random(seed), $random(seed));
        end

        if (errors == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $finish;
    end
endmodule