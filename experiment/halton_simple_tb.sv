`timescale 1ns/1ps

/*
Halton 32-bit Simple Testbench

This testbench verifies the functionality of the Halton sequence generator
for bases [2, 3] with scales [11, 7].
*/

module halton_simple_tb;

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

    // Test counters
    reg [31:0] test_count;
    reg [31:0] i;

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

        $display("=== Halton 32-bit Simple Testbench ===");
        $display("Testing bases [2,3] with scales [%0d,%0d]", TEST_SCALE_0, TEST_SCALE_1);

        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Halton Sequence ---");
        pop_enable = 1'b1;

        // Test first few values
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge valid);
            $display("k=%0d: [%0d, %0d]", i + 1, halton_out_0, halton_out_1);
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
        @(posedge valid);
        $display("After reseed to 5: [%0d, %0d]", halton_out_0, halton_out_1);

        pop_enable = 1'b0;
        #20;

        // Test 3: Reset test
        $display("\n--- Test 3: Reset Test ---");
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;

        pop_enable = 1'b1;
        @(posedge valid);
        $display("After reset: [%0d, %0d]", halton_out_0, halton_out_1);

        pop_enable = 1'b0;
        #20;

        $display("\n=== Halton Simple Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #50000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule