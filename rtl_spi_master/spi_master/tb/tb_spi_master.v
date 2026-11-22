`timescale 1ns/1ps

module tb_spi_master;
    localparam integer DATA_WIDTH = 8;
    localparam integer CLK_DIV    = 1;

    integer errors = 0;
    integer bit_i;
    integer cycles;

    reg                   clk;
    reg                   rst;
    reg                   start;
    reg  [DATA_WIDTH-1:0] tx_data;
    reg                   miso;
    wire                  sclk;
    wire                  mosi;
    wire                  cs_n;
    wire                  busy;
    wire                  done;
    wire [DATA_WIDTH-1:0] rx_data;

    reg  [DATA_WIDTH-1:0] exp_tx;
    reg  [DATA_WIDTH-1:0] exp_rx;
    reg  [DATA_WIDTH-1:0] captured_mosi;

    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLK_DIV(CLK_DIV)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .tx_data(tx_data),
        .miso(miso),
        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n),
        .busy(busy),
        .done(done),
        .rx_data(rx_data)
    );

    // 10 ns clock period (posedge at t = 5, 15, 25, ...)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_spi_master.vcd");
        $dumpvars(0, tb_spi_master);

        exp_tx        = 8'h96;
        exp_rx        = 8'h3C;
        captured_mosi = 8'h00;
        bit_i         = 0;
        cycles        = 0;
        start         = 1'b0;
        tx_data       = 8'h00;
        miso          = 1'b0;

        // 1. Reset check
        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        if (cs_n !== 1'b1 || sclk !== 1'b0 || busy !== 1'b0 || done !== 1'b0) begin
            $display("FAIL [reset] at t=%0t: cs_n=%b sclk=%b busy=%b done=%b",
                     $time, cs_n, sclk, busy, done);
            errors = errors + 1;
        end

        // 2. Launch transfer
        @(negedge clk);
        rst     = 1'b0;
        start   = 1'b1;
        tx_data = exp_tx;
        miso    = exp_rx[DATA_WIDTH-1];

        @(posedge clk);
        #1;
        @(negedge clk);
        start = 1'b0;

        if (cs_n !== 1'b0 || busy !== 1'b1) begin
            $display("FAIL [active_start] at t=%0t: cs_n=%b busy=%b",
                     $time, cs_n, busy);
            errors = errors + 1;
        end

        // Capture MOSI on each rising edge of sclk and feed MISO bits
        while (busy === 1'b1 && cycles < 64) begin
            if (sclk === 1'b1 && bit_i < DATA_WIDTH) begin
                captured_mosi[DATA_WIDTH - 1 - bit_i] = mosi;
                bit_i = bit_i + 1;
                if (bit_i < DATA_WIDTH) begin
                    miso = exp_rx[DATA_WIDTH - 1 - bit_i];
                end
            end

            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end

        if (captured_mosi !== exp_tx) begin
            $display("FAIL [mosi_mismatch]: got 8'h%02h, expected 8'h%02h",
                     captured_mosi, exp_tx);
            errors = errors + 1;
        end

        if (rx_data !== exp_rx) begin
            $display("FAIL [rx_data_mismatch]: got 8'h%02h, expected 8'h%02h",
                     rx_data, exp_rx);
            errors = errors + 1;
        end

        if (cs_n !== 1'b1 || busy !== 1'b0) begin
            $display("FAIL [idle_after_done]: cs_n=%b busy=%b", cs_n, busy);
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