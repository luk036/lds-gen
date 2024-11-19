`timescale 1ns/1ps

module div_mod_7_tb;
    reg [8:0] n;
    wire [8:0] quotient;
    wire [2:0] remainder;

    div_mod_7 dut (
        .n(n),
        .quotient(quotient),
        .remainder(remainder)
    );

    initial begin
        // Test case 1: Basic division - 14/7 = 2 remainder 0
        n = 9'd14;
        #10;
        if (quotient !== 9'd2 || remainder !== 3'd0)
            $display("Test 1 failed: 14/7 expected q=2,r=0, got q=%d,r=%d", quotient, remainder);

        // Test case 2: Prime number - 23/7 = 3 remainder 2
        n = 9'd23;
        #10;
        if (quotient !== 9'd3 || remainder !== 3'd2)
            $display("Test 2 failed: 23/7 expected q=3,r=2, got q=%d,r=%d", quotient, remainder);

        // Test case 3: Zero input
        n = 9'd0;
        #10;
        if (quotient !== 9'd0 || remainder !== 3'd0)
            $display("Test 3 failed: 0/7 expected q=0,r=0, got q=%d,r=%d", quotient, remainder);

        // Test case 4: Maximum input - 511/7 = 73 remainder 0
        n = 9'd511;
        #10;
        if (quotient !== 9'd73 || remainder !== 3'd0)
            $display("Test 4 failed: 511/7 expected q=73,r=0, got q=%d,r=%d", quotient, remainder);

        // Test case 5: Just below multiple of 7 - 48/7 = 6 remainder 6
        n = 9'd48;
        #10;
        if (quotient !== 9'd6 || remainder !== 3'd6)
            $display("Test 5 failed: 48/7 expected q=6,r=6, got q=%d,r=%d", quotient, remainder);

        // Test case 6: Multiple of 7 - 49/7 = 7 remainder 0
        n = 9'd49;
        #10;
        if (quotient !== 9'd7 || remainder !== 3'd0)
            $display("Test 6 failed: 49/7 expected q=7,r=0, got q=%d,r=%d", quotient, remainder);

        // Test case 7: Single digit - 6/7 = 0 remainder 6
        n = 9'd6;
        #10;
        if (quotient !== 9'd0 || remainder !== 3'd6)
            $display("Test 7 failed: 6/7 expected q=0,r=6, got q=%d,r=%d", quotient, remainder);

        // Test case 8: Large number with remainder - 500/7 = 71 remainder 3
        n = 9'd500;
        #10;
        if (quotient !== 9'd71 || remainder !== 3'd3)
            $display("Test 8 failed: 500/7 expected q=71,r=3, got q=%d,r=%d", quotient, remainder);

        $display("All tests completed");
        $finish;
    end
endmodule
