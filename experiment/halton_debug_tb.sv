`timescale 1ns/1ps

/*
Halton 32-bit Debug Testbench

This testbench helps debug the halton_32bit_fixed module.
*/

module halton_debug_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;

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
    reg [31:0] i;
    reg [31:0] timeout_count;

    // Instantiate DUT
    halton_32bit_fixed dut (
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
        timeout_count = 0;

        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;

        $display("=== Halton 32-bit Debug Testbench ===");

        // Test 1: Try single pop
        $display("\n--- Test 1: Single pop ---");
        pop_enable = 1'b1;
        #10;
        pop_enable = 1'b0;

        // Wait for valid with timeout
        fork
            begin
                @(posedge valid);
                $display("Got valid: [%0d, %0d]", halton_out_0, halton_out_1);
            end
            begin
                #1000;
                $display("Timeout waiting for valid!");
            end
        join_any
        disable fork;

        #20;

        // Test 2: Try second pop
        $display("\n--- Test 2: Second pop ---");
        pop_enable = 1'b1;
        #10;
        pop_enable = 1'b0;

        // Wait for valid with timeout
        fork
            begin
                @(posedge valid);
                $display("Got valid: [%0d, %0d]", halton_out_0, halton_out_1);
            end
            begin
                #1000;
                $display("Timeout waiting for valid!");
            end
        join_any
        disable fork;

        #20;

        $display("\n=== Debug Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #10000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule