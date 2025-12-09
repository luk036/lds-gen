/*
Simple testbench for CORDIC module
*/

`timescale 1ns/1ps

module cordic_test_simple;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] angle;
    wire [31:0] cosine;
    wire [31:0] sine;
    wire done;
    wire ready;

    cordic_trig_16bit dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .angle(angle),
        .cosine(cosine),
        .sine(sine),
        .done(done),
        .ready(ready)
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        angle = 0;

        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("Testing CORDIC with angle 0 (should give cos=1, sin=0)");

        // Test angle 0
        angle = 0;
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done == 1);
        @(posedge clk);

        $display("cos(0) = 0x%08h, sin(0) = 0x%08h", cosine, sine);

        // Test angle 90° (π/2)
        #(CLK_PERIOD * 10);
        $display("\nTesting CORDIC with angle 90° (should give cos=0, sin=1)");

        // 90° in 16-bit: 65536/4 = 16384
        angle = 16384;
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done == 1);
        @(posedge clk);

        $display("cos(90°) = 0x%08h, sin(90°) = 0x%08h", cosine, sine);

        // Test angle 180° (π)
        #(CLK_PERIOD * 10);
        $display("\nTesting CORDIC with angle 180° (should give cos=-1, sin=0)");

        // 180° in 16-bit: 65536/2 = 32768
        angle = 32768;
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done == 1);
        @(posedge clk);

        $display("cos(180°) = 0x%08h, sin(180°) = 0x%08h", cosine, sine);

        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule