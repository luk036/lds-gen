`timescale 1ns/1ps

module cordic_sqrt_tb;
    reg clk;
    reg rst;
    reg [7:0] value;
    wire [7:0] sqrt;

    // Instantiate the CORDIC sqrt module
    cordic_sqrt uut (
        .clk(clk),
        .rst(rst),
        .value(value),
        .sqrt(sqrt)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize waveform dump
        $dumpfile("cordic_sqrt.vcd");
        $dumpvars(0, cordic_sqrt_tb);

        // Test case 1: Reset behavior
        rst = 1;
        value = 8'd0;
        #10;
        rst = 0;
        #100;

        // Test case 2: Perfect squares
        value = 8'd16;  // sqrt(16) = 4
        #100;
        if (sqrt !== 8'd4) $display("Error: sqrt(16) = %d, expected 4", sqrt);

        value = 8'd64;  // sqrt(64) = 8
        #100;
        if (sqrt !== 8'd8) $display("Error: sqrt(64) = %d, expected 8", sqrt);

        // Test case 3: Edge cases
        value = 8'd0;   // sqrt(0) = 0
        #100;
        if (sqrt !== 8'd0) $display("Error: sqrt(0) = %d, expected 0", sqrt);

        value = 8'd255; // sqrt(255) ≈ 15
        #100;
        if (sqrt !== 8'd15) $display("Error: sqrt(255) = %d, expected 15", sqrt);

        // Test case 4: Non-perfect squares
        value = 8'd10;  // sqrt(10) ≈ 3
        #100;
        if (sqrt !== 8'd3) $display("Error: sqrt(10) = %d, expected 3", sqrt);

        value = 8'd50;  // sqrt(50) ≈ 7
        #100;
        if (sqrt !== 8'd7) $display("Error: sqrt(50) = %d, expected 7", sqrt);

        // Test case 5: Rapid value changes
        value = 8'd100;
        #20;
        value = 8'd81;
        #20;
        value = 8'd36;
        #100;

        $display("All tests completed");
        $finish;
    end

    // Optional: Monitor changes
    initial begin
        $monitor("Time=%0t rst=%b value=%d sqrt=%d", $time, rst, value, sqrt);
    end
endmodule
