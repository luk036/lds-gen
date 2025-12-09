/*
Testbench for Halton FSM-Based Sequential Implementation (32-bit)

This testbench verifies the functionality of the halton_fsm_32bit_simple module
for various base combinations. It compares hardware results with Python reference
values from the lds_gen library.

Test cases (from Python Halton class examples):
1. Base [2, 3]: k = 1 to 10
2. Base [2, 7]: k = 1 to 5
3. Base [3, 7]: k = 1 to 5

Expected results (from Python Halton class):
Base [2, 3]:
  k=1: [0.5, 0.3333333333333333]
  k=2: [0.25, 0.6666666666666666]
  k=3: [0.75, 0.1111111111111111]
  k=4: [0.125, 0.4444444444444444]
  k=5: [0.625, 0.7777777777777777]
  k=6: [0.375, 0.2222222222222222]
  k=7: [0.875, 0.5555555555555556]
  k=8: [0.0625, 0.8888888888888888]
  k=9: [0.5625, 0.037037037037037035]
  k=10: [0.3125, 0.37037037037037035]
*/

`timescale 1ns/1ps

module halton_fsm_32bit_simple_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz

    // Test vectors structure
    reg [31:0] test_k [0:9];
    reg [31:0] test_expected_x_23 [0:9];  // Base [2,3]
    reg [31:0] test_expected_y_23 [0:9];
    reg [31:0] test_expected_x_27 [0:4];  // Base [2,7]
    reg [31:0] test_expected_y_27 [0:4];
    reg [31:0] test_expected_x_37 [0:4];  // Base [3,7]
    reg [31:0] test_expected_y_37 [0:4];

    // Signals
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base0_sel;
    reg [1:0] base1_sel;
    wire [31:0] result_x;
    wire [31:0] result_y;
    wire done;
    wire ready;

    // Test control
    integer test_index;
    integer error_count;
    integer total_tests;
    integer test_passed;
    integer test_failed;

    // Instantiate DUT
    halton_fsm_32bit_simple dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base0_sel(base0_sel),
        .base1_sel(base1_sel),
        .result_x(result_x),
        .result_y(result_y),
        .done(done),
        .ready(ready)
    );

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Initialize test vectors
    initial begin
        // Test k values
        test_k[0] = 32'd1;
        test_k[1] = 32'd2;
        test_k[2] = 32'd3;
        test_k[3] = 32'd4;
        test_k[4] = 32'd5;
        test_k[5] = 32'd6;
        test_k[6] = 32'd7;
        test_k[7] = 32'd8;
        test_k[8] = 32'd9;
        test_k[9] = 32'd10;

        // Base [2,3] expected values (16.16 fixed-point)
        test_expected_x_23[0] = 32'h00008000;  // 0.5
        test_expected_y_23[0] = 32'h00005555;  // 0.333333
        test_expected_x_23[1] = 32'h00004000;  // 0.25
        test_expected_y_23[1] = 32'h0000AAAA;  // 0.666667
        test_expected_x_23[2] = 32'h0000C000;  // 0.75
        test_expected_y_23[2] = 32'h00001C71;  // 0.111111
        test_expected_x_23[3] = 32'h00002000;  // 0.125
        test_expected_y_23[3] = 32'h000071C7;  // 0.444444
        test_expected_x_23[4] = 32'h0000A000;  // 0.625
        test_expected_y_23[4] = 32'h0000C71C;  // 0.777778
        test_expected_x_23[5] = 32'h00006000;  // 0.375
        test_expected_y_23[5] = 32'h000038E3;  // 0.222222
        test_expected_x_23[6] = 32'h0000E000;  // 0.875
        test_expected_y_23[6] = 32'h00008E38;  // 0.555556
        test_expected_x_23[7] = 32'h00001000;  // 0.0625
        test_expected_y_23[7] = 32'h0000E38E;  // 0.888889
        test_expected_x_23[8] = 32'h00009000;  // 0.5625
        test_expected_y_23[8] = 32'h0000097B;  // 0.037037
        test_expected_x_23[9] = 32'h00005000;  // 0.3125
        test_expected_y_23[9] = 32'h00005ED0;  // 0.370370

        // Base [2,7] expected values
        test_expected_x_27[0] = 32'h00008000;  // 0.5
        test_expected_y_27[0] = 32'h00002492;  // 0.142857
        test_expected_x_27[1] = 32'h00004000;  // 0.25
        test_expected_y_27[1] = 32'h00004924;  // 0.285714
        test_expected_x_27[2] = 32'h0000C000;  // 0.75
        test_expected_y_27[2] = 32'h00006DB6;  // 0.428571
        test_expected_x_27[3] = 32'h00002000;  // 0.125
        test_expected_y_27[3] = 32'h00009249;  // 0.571429
        test_expected_x_27[4] = 32'h0000A000;  // 0.625
        test_expected_y_27[4] = 32'h0000B6DB;  // 0.714286

        // Base [3,7] expected values
        test_expected_x_37[0] = 32'h00005555;  // 0.333333
        test_expected_y_37[0] = 32'h00002492;  // 0.142857
        test_expected_x_37[1] = 32'h0000AAAA;  // 0.666667
        test_expected_y_37[1] = 32'h00004924;  // 0.285714
        test_expected_x_37[2] = 32'h00001C71;  // 0.111111
        test_expected_y_37[2] = 32'h00006DB6;  // 0.428571
        test_expected_x_37[3] = 32'h000071C7;  // 0.444444
        test_expected_y_37[3] = 32'h00009249;  // 0.571429
        test_expected_x_37[4] = 32'h0000C71C;  // 0.777778
        test_expected_y_37[4] = 32'h0000B6DB;  // 0.714286
    end

    // Test task for a single test vector
    task run_test;
        input [31:0] k_val;
        input [1:0] base0_val;
        input [1:0] base1_val;
        input [31:0] expected_x;
        input [31:0] expected_y;
        begin
            // Wait for module to be ready
            wait(ready == 1'b1);
            @(posedge clk);

            // Apply test vector
            k_in = k_val;
            base0_sel = base0_val;
            base1_sel = base1_val;
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait for computation to complete
            wait(done == 1'b1);
            @(posedge clk);

            // Check results with tolerance
            if (result_x >= expected_x - 32'h00000100 && result_x <= expected_x + 32'h00000100 &&
                result_y >= expected_y - 32'h00000100 && result_y <= expected_y + 32'h00000100) begin
                $display("PASS: k=%0d, bases=[%b,%b], x=0x%08h, y=0x%08h",
                         k_val, base0_val, base1_val, result_x, result_y);
                test_passed = test_passed + 1;
            end else begin
                $display("FAIL: k=%0d, bases=[%b,%b]", k_val, base0_val, base1_val);
                $display("  Expected: x=0x%08h, y=0x%08h", expected_x, expected_y);
                $display("  Got:      x=0x%08h, y=0x%08h", result_x, result_y);
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
        base0_sel = 0;
        base1_sel = 0;
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
        $display("Starting Halton FSM Testbench");
        $display("==========================================");

        // Test Base [2,3]
        $display("\nTesting Base [2,3]:");
        $display("-------------------");
        for (test_index = 0; test_index < 10; test_index = test_index + 1) begin
            run_test(test_k[test_index], 2'b00, 2'b01,
                     test_expected_x_23[test_index], test_expected_y_23[test_index]);
        end

        // Test Base [2,7]
        $display("\nTesting Base [2,7]:");
        $display("-------------------");
        for (test_index = 0; test_index < 5; test_index = test_index + 1) begin
            run_test(test_k[test_index], 2'b00, 2'b10,
                     test_expected_x_27[test_index], test_expected_y_27[test_index]);
        end

        // Test Base [3,7]
        $display("\nTesting Base [3,7]:");
        $display("-------------------");
        for (test_index = 0; test_index < 5; test_index = test_index + 1) begin
            run_test(test_k[test_index], 2'b01, 2'b10,
                     test_expected_x_37[test_index], test_expected_y_37[test_index]);
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
        $dumpfile("halton_fsm_32bit_simple_tb.vcd");
        $dumpvars(0, halton_fsm_32bit_simple_tb);
    end

endmodule
