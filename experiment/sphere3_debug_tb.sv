`timescale 1ns/1ps

/*
Sphere3 32-bit Debug Testbench

This testbench helps debug the Sphere3 sequence generator
by showing internal state transitions.
*/

module sphere3_debug_tb;

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

        $display("=== Sphere3 32-bit Debug Testbench ===");
        $display("Testing bases [2,3,7] with scale %0d", TEST_SCALE);

        // Enable pop and wait for valid output
        $display("\n--- Testing basic sequence generation ---");
        pop_enable = 1'b1;

        // Wait for first valid output with timeout
        fork
            begin
                @(posedge valid);
                $display("Got valid output at time %0t", $time);
                $display("Point: w=%0d, x=%0d, y=%0d, z=%0d",
                         sphere3_w, sphere3_x, sphere3_y, sphere3_z);
                pop_enable = 1'b0;
            end
            begin
                #10000;
                $display("ERROR: Timeout waiting for valid output!");
                pop_enable = 1'b0;
            end
        join_any
        disable fork;

        #20;

        // Try second point
        $display("\n--- Testing second point ---");
        pop_enable = 1'b1;

        fork
            begin
                @(posedge valid);
                $display("Got second valid output at time %0t", $time);
                $display("Point: w=%0d, x=%0d, y=%0d, z=%0d",
                         sphere3_w, sphere3_x, sphere3_y, sphere3_z);
                pop_enable = 1'b0;
            end
            begin
                #10000;
                $display("ERROR: Timeout waiting for second valid output!");
                pop_enable = 1'b0;
            end
        join_any
        disable fork;

        #20;

        $display("\n=== Sphere3 Debug Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #50000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
