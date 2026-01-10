/*
Quick test for CORDIC
*/

`timescale 1ns/1ps

module cordic_quick_test;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] angle;
    wire [31:0] cosine;
    wire [31:0] sine;
    wire done;
    wire ready;

    cordic_trig_16bit_fixed dut (
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

        $display("Testing CORDIC ready signal");
        $display("ready = %b", ready);

        // Test angle 0
        angle = 0;
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for done with timeout
        fork
            begin
                wait(done == 1);
                $display("CORDIC done! cos=0x%08h, sin=0x%08h", cosine, sine);
            end
            begin
                #(CLK_PERIOD * 100);
                $display("ERROR: CORDIC timeout!");
                $finish;
            end
        join_any

        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
