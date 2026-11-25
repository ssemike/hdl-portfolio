`timescale 1ns/1ps

module tb_i2c_master;
    localparam integer CLK_DIV = 2;

    integer errors = 0;
    integer cycles;
    integer addr_idx;
    integer data_idx;
    integer scl_rise_count;

    reg        clk;
    reg        rst;
    reg        start;
    reg  [6:0] slave_addr;
    reg  [7:0] tx_data;
    reg        sda_in;
    wire       scl;
    wire       sda_out;
    wire       sda_oe;
    wire       busy;
    wire       done;
    wire       nack_err;

    wire       sda_bus = sda_oe ? sda_out : 1'b1;

    reg  [7:0] exp_addr_byte;
    reg  [7:0] exp_data_byte;
    reg  [7:0] cap_addr;
    reg  [7:0] cap_data;
    reg        prev_scl;

    i2c_master #(
        .CLK_DIV(CLK_DIV)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(slave_addr),
        .tx_data(tx_data),
        .sda_in(sda_in),
        .scl(scl),
        .sda_out(sda_out),
        .sda_oe(sda_oe),
        .busy(busy),
        .done(done),
        .nack_err(nack_err)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_i2c_master.vcd");
        $dumpvars(0, tb_i2c_master);

        slave_addr     = 7'h50;
        tx_data        = 8'hA5;
        exp_addr_byte  = {7'h50, 1'b0}; // 8'hA0
        exp_data_byte  = 8'hA5;
        cap_addr       = 8'h00;
        cap_data       = 8'h00;
        addr_idx       = 0;
        data_idx       = 0;
        scl_rise_count = 0;
        cycles         = 0;
        start          = 1'b0;
        sda_in         = 1'b1;
        prev_scl       = 1'b1;

        // 1. Reset check
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        if (scl !== 1'b1 || sda_bus !== 1'b1 || busy !== 1'b0 || done !== 1'b0) begin
            $display("FAIL [reset] at t=%0t", $time);
            errors = errors + 1;
        end

        // 2. Start single-byte write
        @(negedge clk);
        rst   = 1'b0;
        start = 1'b1;
        @(posedge clk);
        #1;
        @(negedge clk);
        start = 1'b0;

        // Step until transfer completes, simulating slave ACK on address and data ACK cycles
        while ((busy === 1'b1 || done !== 1'b1) && cycles < 500) begin
            // Provide slave ACK (0) when master releases SDA during addr ACK or data ACK
            if (scl === 1'b1 && sda_oe === 1'b0 &&
                ((addr_idx == 8 && data_idx == 0) || data_idx == 8)) begin
                sda_in = 1'b0;
            end else begin
                sda_in = sda_bus;
            end

            // Sample SDA on rising SCL by transaction bit position
            if (prev_scl === 1'b0 && scl === 1'b1) begin
                if (scl_rise_count < 8) begin
                    cap_addr[7 - addr_idx] = sda_bus;
                    addr_idx = addr_idx + 1;
                end else if (scl_rise_count >= 9 && scl_rise_count <= 16) begin
                    cap_data[7 - data_idx] = sda_bus;
                    data_idx = data_idx + 1;
                end

                scl_rise_count = scl_rise_count + 1;
            end

            prev_scl = scl;
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        if (done !== 1'b1) begin
            $display("FAIL [done_missing]: transfer did not complete in time");
            errors = errors + 1;
        end

        if (cap_addr !== exp_addr_byte) begin
            $display("FAIL [addr_byte]: got 8'h%02h, expected 8'h%02h",
                     cap_addr, exp_addr_byte);
            errors = errors + 1;
        end

        if (cap_data !== exp_data_byte) begin
            $display("FAIL [data_byte]: got 8'h%02h, expected 8'h%02h",
                     cap_data, exp_data_byte);
            errors = errors + 1;
        end

        if (nack_err !== 1'b0) begin
            $display("FAIL [nack_err]: expected 0, got %b", nack_err);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED (%0d error(s))", errors);
            $fatal(1);
        end

        $finish;
    end

endmodule
