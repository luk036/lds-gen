`timescale 1ns/1ps

module test_div_mod_3;
    reg [7:0] n;
    wire [7:0] quotient;
    wire [1:0] remainder;

    div_mod_3 dut (
        .n(n),
        .quotient(quotient),
        .remainder(remainder)
    );

    initial begin
        // Test case 1: Basic division by 3
        n = 8'd9;
        #10;
        if (quotient !== 8'd3 || remainder !== 2'd0) $error("Test 1 failed");

        // Test case 2: Number with remainder 1
        n = 8'd10;
        #10;
        if (quotient !== 8'd3 || remainder !== 2'd1) $error("Test 2 failed");

        // Test case 3: Number with remainder 2
        n = 8'd11;
        #10;
        if (quotient !== 8'd3 || remainder !== 2'd2) $error("Test 3 failed");

        // Test case 4: Maximum input
        n = 8'd255;
        #10;
        if (quotient !== 8'd85 || remainder !== 2'd0) $error("Test 4 failed");

        // Test case 5: Zero input
        n = 8'd0;
        #10;
        if (quotient !== 8'd0 || remainder !== 2'd0) $error("Test 5 failed");

        // Test case 6: Small number less than 3
        n = 8'd2;
        #10;
        if (quotient !== 8'd0 || remainder !== 2'd2) $error("Test 6 failed");

        // Test case 7: Large number with remainder
        n = 8'd250;
        #10;
        if (quotient !== 8'd83 || remainder !== 2'd1) $error("Test 7 failed");

        // Test case 8: Multiple of 3
        n = 8'd99;
        #10;
        if (quotient !== 8'd33 || remainder !== 2'd0) $error("Test 8 failed");

        $display("All tests completed");
        $finish;
    end

    initial begin
        $dumpfile("test_div_mod_3.vcd");
        $dumpvars(0, test_div_mod_3);
    end
endmodule
