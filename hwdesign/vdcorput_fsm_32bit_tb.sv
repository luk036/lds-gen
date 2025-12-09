/*
Testbench for VdCorput FSM-Based Sequential Implementation (32-bit)

This testbench verifies the functionality of the vdcorput_fsm_32bit module
for bases 2, 3, and 7. It compares hardware results with Python reference
values from the lds_gen library.

Test cases:
1. Base 2: k = 1, 2, 3, 4, 5, 11
2. Base 3: k = 1, 2, 3, 4, 5, 11
3. Base 7: k = 1, 2, 3, 4, 5, 11

Expected results (from Python vdc function):
Base 2:
  vdc(1, 2) = 0.5
  vdc(2, 2) = 0.25
  vdc(3, 2) = 0.75
  vdc(4, 2) = 0.125
  vdc(5, 2) = 0.625
  vdc(11, 2) = 0.8125

Base 3:
  vdc(1, 3) = 0.3333333333333333
  vdc(2, 3) = 0.6666666666666666
  vdc(3, 3) = 0.1111111111111111
  vdc(4, 3) = 0.4444444444444444
  vdc(5, 3) = 0.7777777777777777
  vdc(11, 3) = 0.4074074074074074

Base 7:
  vdc(1, 7) = 0.14285714285714285
  vdc(2, 7) = 0.2857142857142857
  vdc(3, 7) = 0.42857142857142855
  vdc(4, 7) = 0.5714285714285714
  vdc(5, 7) = 0.7142857142857143
  vdc(11, 7) = 0.22448979591836735
*/

`timescale 1ns/1ps

module vdcorput_fsm_32bit_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz

    // Test vectors
    typedef struct {
        logic [31:0] k;
        logic [1:0] base_sel;
        logic [31:0] expected;  // Fixed-point expected value (16.16 format)
    } test_vector_t;

    // Test vectors for base 2 (16.16 fixed-point)
    localparam test_vector_t TEST_VECTORS_BASE2 [6] = '{
        '{k: 32'd1,  base_sel: 2'b00, expected: 32'h00008000},  // 0.5
        '{k: 32'd2,  base_sel: 2'b00, expected: 32'h00004000},  // 0.25
        '{k: 32'd3,  base_sel: 2'b00, expected: 32'h0000C000},  // 0.75
        '{k: 32'd4,  base_sel: 2'b00, expected: 32'h00002000},  // 0.125
        '{k: 32'd5,  base_sel: 2'b00, expected: 32'h0000A000},  // 0.625
        '{k: 32'd11, base_sel: 2'b00, expected: 32'h0000D000}   // 0.8125
    };

    // Test vectors for base 3 (16.16 fixed-point)
    localparam test_vector_t TEST_VECTORS_BASE3 [6] = '{
        '{k: 32'd1,  base_sel: 2'b01, expected: 32'h00005555},  // 0.333333
        '{k: 32'd2,  base_sel: 2'b01, expected: 32'h0000AAAA},  // 0.666667
        '{k: 32'd3,  base_sel: 2'b01, expected: 32'h00001C71},  // 0.111111
        '{k: 32'd4,  base_sel: 2'b01, expected: 32'h000071C7},  // 0.444444
        '{k: 32'd5,  base_sel: 2'b01, expected: 32'h0000C71C},  // 0.777778
        '{k: 32'd11, base_sel: 2'b01, expected: 32'h00006868}   // 0.407407
    };

    // Test vectors for base 7 (16.16 fixed-point)
    localparam test_vector_t TEST_VECTORS_BASE7 [6] = '{
        '{k: 32'd1,  base_sel: 2'b10, expected: 32'h00002492},  // 0.142857
        '{k: 32'd2,  base_sel: 2'b10, expected: 32'h00004924},  // 0.285714
        '{k: 32'd3,  base_sel: 2'b10, expected: 32'h00006DB6},  // 0.428571
        '{k: 32'd4,  base_sel: 2'b10, expected: 32'h00009249},  // 0.571429
        '{k: 32'd5,  base_sel: 2'b10, expected: 32'h0000B6DB},  // 0.714286
        '{k: 32'd11, base_sel: 2'b10, expected: 32'h00003979}   // 0.224490
    };

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
    vdcorput_fsm_32bit dut (
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

    // Test task for a single test vector
    task run_test;
        input test_vector_t tv;
        begin
            // Wait for module to be ready
            wait(ready == 1'b1);
            @(posedge clk);

            // Apply test vector
            k_in = tv.k;
            base_sel = tv.base_sel;
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait for computation to complete
            wait(done == 1'b1);
            @(posedge clk);

            // Check result with tolerance
            if (result >= tv.expected - 32'h00000100 && result <= tv.expected + 32'h00000100) begin
                $display("PASS: k=%0d, base_sel=%b, expected=0x%08h, got=0x%08h",
                         tv.k, tv.base_sel, tv.expected, result);
                test_passed = test_passed + 1;
            end else begin
                $display("FAIL: k=%0d, base_sel=%b, expected=0x%08h, got=0x%08h",
                         tv.k, tv.base_sel, tv.expected, result);
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
        $display("Starting VdCorput FSM Testbench");
        $display("==========================================");

        // Test Base 2
        $display("\nTesting Base 2:");
        $display("----------------");
        for (test_index = 0; test_index < 6; test_index = test_index + 1) begin
            run_test(TEST_VECTORS_BASE2[test_index]);
        end

        // Test Base 3
        $display("\nTesting Base 3:");
        $display("----------------");
        for (test_index = 0; test_index < 6; test_index = test_index + 1) begin
            run_test(TEST_VECTORS_BASE3[test_index]);
        end

        // Test Base 7
        $display("\nTesting Base 7:");
        $display("----------------");
        for (test_index = 0; test_index < 6; test_index = test_index + 1) begin
            run_test(TEST_VECTORS_BASE7[test_index]);
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

    // Monitor for debugging
    initial begin
        $monitor("Time=%0t: state=%s, k_reg=0x%08h, acc_reg=0x%08h, done=%b, ready=%b",
                 $time, dut.current_state.name(), dut.k_reg, dut.acc_reg, done, ready);
    end

    // Dump VCD file for waveform viewing
    initial begin
        $dumpfile("vdcorput_fsm_32bit_tb.vcd");
        $dumpvars(0, vdcorput_fsm_32bit_tb);
    end

endmodule
