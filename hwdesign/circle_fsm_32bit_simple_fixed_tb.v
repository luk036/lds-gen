/*
Testbench for Circle FSM-Based Sequential Implementation (32-bit) - Fixed version

This testbench verifies the functionality of the circle_fsm_32bit_simple_fixed module
for bases 2, 3, and 7. It compares hardware results with Python reference values.

Test cases:
1. Base 2: k = 1 to 5
2. Base 3: k = 1 to 5
3. Base 7: k = 1 to 5

Note: Due to CORDIC precision limitations and fixed-point arithmetic,
results may have small errors compared to floating-point Python results.
*/

`timescale 1ns/1ps

module circle_fsm_32bit_simple_fixed_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz

    // Test vectors
    reg [31:0] test_k [0:4];
    
    // Base 2 expected values (16.16 fixed-point, 2's complement)
    reg [31:0] test_expected_x_2 [0:4];
    reg [31:0] test_expected_y_2 [0:4];
    
    // Base 3 expected values
    reg [31:0] test_expected_x_3 [0:4];
    reg [31:0] test_expected_y_3 [0:4];
    
    // Base 7 expected values
    reg [31:0] test_expected_x_7 [0:4];
    reg [31:0] test_expected_y_7 [0:4];

    // Signals
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel;
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

    // Instantiate DUT (using fixed version)
    circle_fsm_32bit_simple_fixed dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel(base_sel),
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
        
        // Base 2 expected values (from Python reference)
        // k=1: angle=0.5*2π=π, cos(π)=-1, sin(π)=0
        test_expected_x_2[0] = 32'hFFFF0000;  // -1.0
        test_expected_y_2[0] = 32'h00000000;  // 0.0
        
        // k=2: angle=0.25*2π=π/2, cos(π/2)=0, sin(π/2)=1
        test_expected_x_2[1] = 32'h00000000;  // 0.0
        test_expected_y_2[1] = 32'h00010000;  // 1.0
        
        // k=3: angle=0.75*2π=3π/2, cos(3π/2)=0, sin(3π/2)=-1
        test_expected_x_2[2] = 32'h00000000;  // 0.0
        test_expected_y_2[2] = 32'hFFFF0000;  // -1.0
        
        // k=4: angle=0.125*2π=π/4, cos(π/4)=0.7071, sin(π/4)=0.7071
        test_expected_x_2[3] = 32'h0000B505;  // 0.7071
        test_expected_y_2[3] = 32'h0000B505;  // 0.7071
        
        // k=5: angle=0.625*2π=5π/4, cos(5π/4)=-0.7071, sin(5π/4)=-0.7071
        test_expected_x_2[4] = 32'hFFFF4AFB;  // -0.7071
        test_expected_y_2[4] = 32'hFFFF4AFB;  // -0.7071
        
        // Base 3 expected values
        // k=1: angle=0.333333*2π=2π/3, cos(2π/3)=-0.5, sin(2π/3)=0.8660
        test_expected_x_3[0] = 32'hFFFF8000;  // -0.5
        test_expected_y_3[0] = 32'h0000DDB4;  // 0.8660
        
        // k=2: angle=0.666667*2π=4π/3, cos(4π/3)=-0.5, sin(4π/3)=-0.8660
        test_expected_x_3[1] = 32'hFFFF8000;  // -0.5
        test_expected_y_3[1] = 32'hFFFF224C;  // -0.8660
        
        // k=3: angle=0.111111*2π=2π/9, cos(2π/9)=0.7660, sin(2π/9)=0.6428
        test_expected_x_3[2] = 32'h0000C3EF;  // 0.7660
        test_expected_y_3[2] = 32'h0000A48D;  // 0.6428
        
        // k=4: angle=0.444444*2π=8π/9, cos(8π/9)=-0.7660, sin(8π/9)=0.6428
        test_expected_x_3[3] = 32'hFFFF3C11;  // -0.7660
        test_expected_y_3[3] = 32'h0000A48D;  // 0.6428
        
        // k=5: angle=0.777778*2π=14π/9, cos(14π/9)=-0.7660, sin(14π/9)=-0.6428
        test_expected_x_3[4] = 32'hFFFF3C11;  // -0.7660
        test_expected_y_3[4] = 32'hFFFF5B73;  // -0.6428
        
        // Base 7 expected values
        // k=1: angle=0.142857*2π=2π/7, cos(2π/7)=0.6235, sin(2π/7)=0.7818
        test_expected_x_7[0] = 32'h00009F7B;  // 0.6235
        test_expected_y_7[0] = 32'h0000C82B;  // 0.7818
        
        // k=2: angle=0.285714*2π=4π/7, cos(4π/7)=-0.2225, sin(4π/7)=0.9749
        test_expected_x_7[1] = 32'hFFFFE38E;  // -0.2225
        test_expected_y_7[1] = 32'h0000F97A;  // 0.9749
        
        // k=3: angle=0.428571*2π=6π/7, cos(6π/7)=-0.9009, sin(6π/7)=0.4339
        test_expected_x_7[2] = 32'hFFFF7333;  // -0.9009
        test_expected_y_7[2] = 32'h00006F2E;  // 0.4339
        
        // k=4: angle=0.571429*2π=8π/7, cos(8π/7)=-0.9009, sin(8π/7)=-0.4339
        test_expected_x_7[3] = 32'hFFFF7333;  // -0.9009
        test_expected_y_7[3] = 32'hFFFF90D2;  // -0.4339
        
        // k=5: angle=0.714286*2π=10π/7, cos(10π/7)=-0.2225, sin(10π/7)=-0.9749
        test_expected_x_7[4] = 32'hFFFFE38E;  // -0.2225
        test_expected_y_7[4] = 32'hFFFF0686;  // -0.9749
    end

    // Test task for a single test vector
    task run_test;
        input [31:0] k_val;
        input [1:0] base_val;
        input [31:0] expected_x;
        input [31:0] expected_y;
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
            
            // Check results with tolerance (±0x00001000 = ±0.0625)
            if (result_x >= expected_x - 32'h00001000 && result_x <= expected_x + 32'h00001000 &&
                result_y >= expected_y - 32'h00001000 && result_y <= expected_y + 32'h00001000) begin
                $display("PASS: k=%0d, base_sel=%b, x=0x%08h, y=0x%08h", 
                         k_val, base_val, result_x, result_y);
                test_passed = test_passed + 1;
            end else begin
                $display("FAIL: k=%0d, base_sel=%b", k_val, base_val);
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
        $display("Starting Circle FSM Testbench (Fixed)");
        $display("==========================================");
        
        // Test Base 2
        $display("\nTesting Base 2:");
        $display("----------------");
        for (test_index = 0; test_index < 5; test_index = test_index + 1) begin
            run_test(test_k[test_index], 2'b00, 
                     test_expected_x_2[test_index], test_expected_y_2[test_index]);
        end
        
        // Test Base 3
        $display("\nTesting Base 3:");
        $display("----------------");
        for (test_index = 0; test_index < 5; test_index = test_index + 1) begin
            run_test(test_k[test_index], 2'b01, 
                     test_expected_x_3[test_index], test_expected_y_3[test_index]);
        end
        
        // Test Base 7
        $display("\nTesting Base 7:");
        $display("----------------");
        for (test_index = 0; test_index < 5; test_index = test_index + 1) begin
            run_test(test_k[test_index], 2'b10, 
                     test_expected_x_7[test_index], test_expected_y_7[test_index]);
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
        $dumpfile("circle_fsm_32bit_simple_fixed_tb.vcd");
        $dumpvars(0, circle_fsm_32bit_simple_fixed_tb);
    end

endmodule