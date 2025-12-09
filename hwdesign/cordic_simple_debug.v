/*
Simple debug for CORDIC
*/

`timescale 1ns/1ps

module cordic_simple_debug;

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

    integer cycle_count;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (cycle_count > 100) begin
            $display("ERROR: Too many cycles!");
            $finish;
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        angle = 0;
        cycle_count = 0;

        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("Cycle %0d: After reset, ready=%b", cycle_count, ready);

        // Test angle 0
        angle = 0;
        start = 1;
        @(posedge clk);
        start = 0;

        // Monitor for done signal
        while (!done && cycle_count < 50) begin
            @(posedge clk);
            $display("Cycle %0d: state=%b, iter=%0d, ready=%b, done=%b",
                     cycle_count, dut.state, dut.iteration, ready, done);
        end

        if (done) begin
            $display("CORDIC completed in %0d cycles", cycle_count);
            $display("cos=0x%08h, sin=0x%08h", cosine, sine);
        end else begin
            $display("ERROR: CORDIC didn't complete");
        end

        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule