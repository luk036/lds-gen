/*
Testbench for VdCorput FSM-Based Sequential Implementation (32-bit) - Simple Version
*/

`timescale 1ns/1ps

module vdcorput_fsm_32bit_simple_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz

    // Test vectors for base 2 (16.16 fixed-point)
    reg [31:0] test_vectors_base2_k [0:5];
    reg [31:0] test_vectors_base2_expected [0:5];

    // Test vectors for base 3 (16.16 fixed-point)
    reg [31:0] test_vectors_base3_k [0:5];
    reg [31:0] test_vectors_base3_expected [0:5];

    // Test vectors for base 7 (16.16 fixed-point)
    reg [31:0] test_vectors_base7_k [0:5];
    reg [31:0] test_vectors_base7_expected [0:5];

    // Signals
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel;
    wire [31:0] result;
    wire done;
    wire ready;

    // Test control
    integer test_index;
    integer error_count;
    integer total_tests;
    integer test_passed;
    integer test_failed;

    // Instantiate DUT
    vdcorput_fsm_32bit_simple dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel(base_sel),
        .result(result),
        .done(done),
        .ready(ready)
    );

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Initialize test vectors
    initial begin
        // Base 2 test vectors
        test_vectors_base2_k[0] = 32'd1;  test_vectors_base2_expected[0] = 32'h00008000;  // 0.5
        test_vectors_base2_k[1] = 32'd2;  test_vectors_base2_expected[1] = 32'h00004000;  // 0.25
        test_vectors_base2_k[2] = 32'd3;  test_vectors_base2_expected[2] = 32'h0000C000;  // 0.75
        test_vectors_base2_k[3] = 32'd4;  test_vectors_base2_expected[3] = 32'h00002000;  // 0.125
        test_vectors_base2_k[4] = 32'd5;  test_vectors_base2_expected[4] = 32'h0000A000;  // 0.625
        test_vectors_base2_k[5] = 32'd11; test_vectors_base2_expected[5] = 32'h0000D000;  // 0.8125

        // Base 3 test vectors
        test_vectors_base3_k[0] = 32'd1;  test_vectors_base3_expected[0] = 32'h00005555;  // 0.333333
        test_vectors_base3_k[1] = 32'd2;  test_vectors_base3_expected[1] = 32'h0000AAAA;  // 0.666667
        test_vectors_base3_k[2] = 32'd3;  test_vectors_base3_expected[2] = 32'h00001C71;  // 0.111111
        test_vectors_base3_k[3] = 32'd4;  test_vectors_base3_expected[3] = 32'h000071C7;  // 0.444444
        test_vectors_base3_k[4] = 32'd5;  test_vectors_base3_expected[4] = 32'h0000C71C;  // 0.777778
        test_vectors_base3_k[5] = 32'd11; test_vectors_base3_expected[5] = 32'h0000B425;  // 0.703704

        // Base 7 test vectors
        test_vectors_base7_k[0] = 32'd1;  test_vectors_base7_expected[0] = 32'h00002492;  // 0.142857
        test_vectors_base7_k[1] = 32'd2;  test_vectors_base7_expected[1] = 32'h00004924;  // 0.285714
        test_vectors_base7_k[2] = 32'd3;  test_vectors_base7_expected[2] = 32'h00006DB6;  // 0.428571
        test_vectors_base7_k[3] = 32'd4;  test_vectors_base7_expected[3] = 32'h00009249;  // 0.571429
        test_vectors_base7_k[4] = 32'd5;  test_vectors_base7_expected[4] = 32'h0000B6DB;  // 0.714286
        test_vectors_base7_k[5] = 32'd11; test_vectors_base7_expected[5] = 32'h00009782;  // 0.591837
    end

    // Test task for a single test vector
    task run_test;
        input [31:0] k_val;
        input [1:0] base_val;
        input [31:0] expected_val;
        begin
            // Wait for module to be ready
            wait(ready == 1'b1);
            @(posedge clk);

            // Apply test vector
            k_in = k_val;
            base_sel = base_val;
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait for computation to complete
            wait(done == 1'b1);
            @(posedge clk);

            // Check result with tolerance
            if (result >= expected_val - 32'h00000100 && result <= expected_val + 32'h00000100) begin
                $display("PASS: count=%0d, base_sel=%b, expected=0x%08h, got=0x%08h",
                         k_val, base_val, expected_val, result);
                test_passed = test_passed + 1;
            end else begin
                $display("FAIL: count=%0d, base_sel=%b, expected=0x%08h, got=0x%08h",
                         k_val, base_val, expected_val, result);
                test_failed = test_failed + 1;
                error_count = error_count + 1;
            end

            total_tests = total_tests + 1;
        end
    endtask

    // Main test sequence
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        start = 0;
        k_in = 0;
        base_sel = 0;
        test_index = 0;
        error_count = 0;
        total_tests = 0;
        test_passed = 0;
        test_failed = 0;

        // Apply reset
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("==========================================");
        $display("Starting VdCorput FSM Testbench (Simple)");
        $display("==========================================");

        // Test Base 2
        $display("\nTesting Base 2:");
        $display("----------------");
        for (test_index = 0; test_index < 6; test_index = test_index + 1) begin
            run_test(test_vectors_base2_k[test_index], 2'b00, test_vectors_base2_expected[test_index]);
        end

        // Test Base 3
        $display("\nTesting Base 3:");
        $display("----------------");
        for (test_index = 0; test_index < 6; test_index = test_index + 1) begin
            run_test(test_vectors_base3_k[test_index], 2'b01, test_vectors_base3_expected[test_index]);
        end

        // Test Base 7
        $display("\nTesting Base 7:");
        $display("----------------");
        for (test_index = 0; test_index < 6; test_index = test_index + 1) begin
            run_test(test_vectors_base7_k[test_index], 2'b10, test_vectors_base7_expected[test_index]);
        end

        // Summary
        $display("\n==========================================");
        $display("Test Summary:");
        $display("  Total tests: %0d", total_tests);
        $display("  Passed: %0d", test_passed);
        $display("  Failed: %0d", test_failed);
        $display("  Error count: %0d", error_count);

        if (error_count == 0) begin
            $display("\nAll tests PASSED!");
        end else begin
            $display("\nSome tests FAILED!");
        end

        $display("==========================================");

        // Finish simulation
        #(CLK_PERIOD * 10);
        $finish;
    end

    // Dump VCD file for waveform viewing
    initial begin
        $dumpfile("vdcorput_fsm_32bit_simple_tb.vcd");
        $dumpvars(0, vdcorput_fsm_32bit_simple_tb);
    end

endmodule
