`timescale 1ns/1ps

/*
Sphere3Hopf 32-bit Simple Testbench

This testbench verifies the basic functionality of the Sphere3Hopf sequence generator.
*/

module sphere3hopf_simple_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;
    parameter TEST_SCALE = 16;
    parameter TEST_ANGLE_BITS = 16;

    // Signals for DUT connections
    reg         clk;
    reg         rst_n;
    reg         pop_enable;
    reg  [31:0] seed;
    reg         reseed_enable;
    wire [31:0] hopf_x;
    wire [31:0] hopf_y;
    wire [31:0] hopf_z;
    wire [31:0] hopf_w;
    wire        valid;

    // Test counters
    reg [31:0] i;

    // Instantiate DUT for bases [2,3,7]
    sphere3hopf_32bit #(
        .BASE_0(2),
        .BASE_1(3),
        .BASE_2(7),
        .SCALE(TEST_SCALE),
        .ANGLE_BITS(TEST_ANGLE_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .hopf_x(hopf_x),
        .hopf_y(hopf_y),
        .hopf_z(hopf_z),
        .hopf_w(hopf_w),
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

        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;

        $display("=== Sphere3Hopf 32-bit Simple Testbench ===");
        $display("Testing bases [2,3,7] with scale %0d", TEST_SCALE);

        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Sphere3Hopf Sequence ---");
        pop_enable = 1'b1;

        // Test first few values
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge valid);
            $display("Point %0d: [%0d, %0d, %0d, %0d]", i + 1, hopf_x, hopf_y, hopf_z, hopf_w);
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
        $display("After reseed to 5: [%0d, %0d, %0d, %0d]", hopf_x, hopf_y, hopf_z, hopf_w);

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
        $display("After reset: [%0d, %0d, %0d, %0d]", hopf_x, hopf_y, hopf_z, hopf_w);

        pop_enable = 1'b0;
        #20;

        // Test 4: Different base combination
        $display("\n--- Test 4: Different Base Combination ---");
        // Note: This would require instantiating a different DUT with different base parameters
        // For simplicity, we're just showing the concept here
        $display("Testing different base combinations would require separate DUT instances");

        $display("\n=== Sphere3Hopf Simple Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #50000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule