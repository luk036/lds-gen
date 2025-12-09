`timescale 1ns/1ps

/*
Sphere3 32-bit Simple Testbench

This testbench verifies the basic functionality of the Sphere3 sequence generator
for base triple [2,3,7].
*/

module sphere3_simple_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;
    parameter TEST_SCALE = 16;

    // Signals for DUT connections
    reg         clk;
    reg         rst_n;
    reg         pop_enable;
    reg  [31:0] seed;
    reg         reseed_enable;
    wire [31:0] sphere3_w;
    wire [31:0] sphere3_x;
    wire [31:0] sphere3_y;
    wire [31:0] sphere3_z;
    wire        valid;

    // Test counters
    reg [31:0] i;

    // Fixed-point conversion constants
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point

    // Instantiate DUT for bases [2,3,7]
    sphere3_32bit #(
        .BASE_0(2),
        .BASE_1(3),
        .BASE_2(7),
        .BASE_3(2),
        .SCALE(TEST_SCALE)
    ) dut_237 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .sphere3_w(sphere3_w),
        .sphere3_x(sphere3_x),
        .sphere3_y(sphere3_y),
        .sphere3_z(sphere3_z),
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

        $display("=== Sphere3 32-bit Simple Testbench ===");
        $display("Testing bases [2,3,7] with scale %0d", TEST_SCALE);

        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Sphere3 Sequence ---");
        pop_enable = 1'b1;

        // Test first few values
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge valid);
            $display("Point %0d: w=%0d, x=%0d, y=%0d, z=%0d",
                     i + 1, sphere3_w, sphere3_x, sphere3_y, sphere3_z);
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
        $display("After reseed to 5: w=%0d, x=%0d, y=%0d, z=%0d",
                 sphere3_w, sphere3_x, sphere3_y, sphere3_z);

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
        $display("After reset: w=%0d, x=%0d, y=%0d, z=%0d",
                 sphere3_w, sphere3_x, sphere3_y, sphere3_z);

        pop_enable = 1'b0;
        #20;

        $display("\n=== Sphere3 Simple Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #50000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule