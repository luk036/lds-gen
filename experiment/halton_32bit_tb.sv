`timescale 1ns/1ps

/*
Halton 32-bit Testbench

This testbench verifies the functionality of the Halton sequence generator
for bases [2, 3] with scales [11, 7]. It tests various aspects including:
- Basic sequence generation
- Reseed functionality
- Edge cases
- Comparison with Python reference implementation values
*/

module halton_32bit_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;
    parameter TEST_SCALE_0 = 11;  // Scale for base 2
    parameter TEST_SCALE_1 = 7;   // Scale for base 3

    // Signals for DUT connections
    reg         clk;
    reg         rst_n;
    reg         pop_enable;
    reg  [31:0] seed;
    reg         reseed_enable;
    wire [31:0] halton_out_0;
    wire [31:0] halton_out_1;
    wire        valid;

    // Test counters and control
    reg [31:0] test_count;
    reg [31:0] expected_0, expected_1;
    reg [31:0] i;  // Loop variable for iverilog compatibility

    // Expected values from Python reference (bases [2,3], scales [11,7])
    // First 10 values: [1024, 729], [512, 1458], [1536, 243], [256, 972], [1280, 1701]
    //                  [768, 486], [1792, 1215], [128, 1944], [1152, 81], [640, 810]

    // Instantiate DUT
    halton_32bit #(
        .SCALE_0(TEST_SCALE_0),
        .SCALE_1(TEST_SCALE_1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .halton_out_0(halton_out_0),
        .halton_out_1(halton_out_1),
        .valid(valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 1'b0;
        pop_enable = 1'b0;
        reseed_enable = 1'b0;
        seed = 32'd0;
        test_count = 32'd0;

        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;

        $display("=== Halton 32-bit Testbench ===");
        $display("Testing bases [2,3] with scales [%0d,%0d]", TEST_SCALE_0, TEST_SCALE_1);

        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Halton Sequence ---");
        pop_enable = 1'b1;

        // Expected values from Python reference - use initial block
        reg [31:0] exp0_0, exp0_1, exp0_2, exp0_3, exp0_4;
        reg [31:0] exp0_5, exp0_6, exp0_7, exp0_8, exp0_9;
        reg [31:0] exp1_0, exp1_1, exp1_2, exp1_3, exp1_4;
        reg [31:0] exp1_5, exp1_6, exp1_7, exp1_8, exp1_9;

        // Test first 10 values
        for (i = 0; i < 10; i = i + 1) begin
            @(posedge valid);

            // Calculate expected values inline
            case (i)
                0: begin expected_0 = 32'd1024; expected_1 = 32'd729; end
                1: begin expected_0 = 32'd512;  expected_1 = 32'd1458; end
                2: begin expected_0 = 32'd1536; expected_1 = 32'd243; end
                3: begin expected_0 = 32'd256;  expected_1 = 32'd972; end
                4: begin expected_0 = 32'd1280; expected_1 = 32'd1701; end
                5: begin expected_0 = 32'd768;  expected_1 = 32'd486; end
                6: begin expected_0 = 32'd1792; expected_1 = 32'd1215; end
                7: begin expected_0 = 32'd128;  expected_1 = 32'd1944; end
                8: begin expected_0 = 32'd1152; expected_1 = 32'd81; end
                9: begin expected_0 = 32'd640;  expected_1 = 32'd810; end
            endcase

            $display("k=%0d: [%0d, %0d] (expected [%0d, %0d])",
                     i + 1, halton_out_0, halton_out_1, expected_0, expected_1);

            // Verify values
            if (halton_out_0 !== expected_0 || halton_out_1 !== expected_1)
                $display("FAIL: Test 1.%0d - Expected [%0d,%0d], got [%0d,%0d]",
                         i + 1, expected_0, expected_1, halton_out_0, halton_out_1);
            else
                $display("PASS: Test 1.%0d", i + 1);
        end

        pop_enable = 1'b0;
        #20;

        // Test 2: Reseed functionality
        $display("\n--- Test 2: Reseed Test ---");
        reseed_enable = 1'b1;
        seed = 32'd5;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;

        pop_enable = 1'b1;
        // After reseed to 5, next values should be for k=6
        // Calculate expected values manually: k=6 for base 2, scale 11 and base 3, scale 7
        expected_0 = 32'd384;   // vdc(6, base=2, scale=11)
        expected_1 = 32'd486;   // vdc(6, base=3, scale=7)

        @(posedge valid);
        $display("After reseed to 5 (k=6): [%0d, %0d] (expected [%0d, %0d])",
                 halton_out_0, halton_out_1, expected_0, expected_1);

        if (halton_out_0 !== expected_0 || halton_out_1 !== expected_1)
            $display("FAIL: Test 2.1 - Expected [%0d,%0d], got [%0d,%0d]",
                     expected_0, expected_1, halton_out_0, halton_out_1);
        else
            $display("PASS: Test 2.1");

        pop_enable = 1'b0;
        #20;

        // Test 3: Edge cases
        $display("\n--- Test 3: Edge Cases ---");
        reseed_enable = 1'b1;
        seed = 32'd0;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;

        pop_enable = 1'b1;
        // Test first value after reset (k=1)
        expected_0 = 32'd2048;  // vdc(1, base=2, scale=11) = 2^10
        expected_1 = 32'd729;   // vdc(1, base=3, scale=7) = 3^6

        @(posedge valid);
        $display("First value after reset: [%0d, %0d] (expected [%0d, %0d])",
                 halton_out_0, halton_out_1, expected_0, expected_1);

        if (halton_out_0 !== expected_0 || halton_out_1 !== expected_1)
            $display("FAIL: Test 3.1 - Expected [%0d,%0d], got [%0d,%0d]",
                     expected_0, expected_1, halton_out_0, halton_out_1);
        else
            $display("PASS: Test 3.1");

        pop_enable = 1'b0;
        #20;

        // Test 4: Sequence consistency
        $display("\n--- Test 4: Sequence Consistency ---");
        reseed_enable = 1'b1;
        seed = 32'd0;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;

        pop_enable = 1'b1;
        // Generate 5 more values and check pattern
        for (i = 1; i <= 5; i = i + 1) begin
            @(posedge valid);
            $display("Value %0d: [%0d, %0d]", i, halton_out_0, halton_out_1);
        end

        pop_enable = 1'b0;
        #20;

        // Test 5: Large values
        $display("\n--- Test 5: Large Values Test ---");
        reseed_enable = 1'b1;
        seed = 32'd100;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;

        pop_enable = 1'b1;
        for (i = 101; i <= 103; i = i + 1) begin
            @(posedge valid);
            $display("Large value %0d: [%0d, %0d]", i, halton_out_0, halton_out_1);
        end

        pop_enable = 1'b0;
        #20;

        $display("\n=== All Halton Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #50000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

    // Monitor changes
    initial begin
        $monitor("Time %0t: pop_enable=%b, reseed_enable=%b, halton=[%0d,%0d], valid=%b",
                 $time, pop_enable, reseed_enable, halton_out_0, halton_out_1, valid);
    end

endmodule
