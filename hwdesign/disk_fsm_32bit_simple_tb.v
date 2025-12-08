/*
Testbench for Disk FSM-Based Sequential Implementation
*/

`timescale 1ns/1ps

module disk_fsm_32bit_simple_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel0;
    reg [1:0] base_sel1;
    wire [31:0] result_x;
    wire [31:0] result_y;
    wire done;
    wire ready;

    disk_fsm_32bit_simple dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel0(base_sel0),
        .base_sel1(base_sel1),
        .result_x(result_x),
        .result_y(result_y),
        .done(done),
        .ready(ready)
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    task run_test;
        input [31:0] test_k;
        input [1:0] test_base0;
        input [1:0] test_base1;
        input real expected_x;
        input real expected_y;
        input real tolerance;
        begin
            k_in = test_k;
            base_sel0 = test_base0;
            base_sel1 = test_base1;
            
            wait(ready == 1);
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            wait(done == 1);
            @(posedge clk);
            
            // Convert fixed-point to float
            real result_x_float = $signed(result_x) / 65536.0;
            real result_y_float = $signed(result_y) / 65536.0;
            
            // Check results
            if ((result_x_float >= expected_x - tolerance) && 
                (result_x_float <= expected_x + tolerance) &&
                (result_y_float >= expected_y - tolerance) && 
                (result_y_float <= expected_y + tolerance)) begin
                $display("PASS: k=%0d, bases=[%0d,%0d], result=(%0.6f, %0.6f), expected=(%0.6f, %0.6f)", 
                         test_k, test_base0+2, test_base1+2, 
                         result_x_float, result_y_float, expected_x, expected_y);
            end else begin
                $display("FAIL: k=%0d, bases=[%0d,%0d], result=(%0.6f, %0.6f), expected=(%0.6f, %0.6f)", 
                         test_k, test_base0+2, test_base1+2, 
                         result_x_float, result_y_float, expected_x, expected_y);
            end
            
            #(CLK_PERIOD * 5);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        k_in = 0;
        base_sel0 = 0;
        base_sel1 = 0;
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        $display("Testing Disk sequence generator");
        $display("================================");
        
        // Test cases from Python examples
        // Note: Python output has floating point inaccuracies
        // We'll use a tolerance of 0.01 for comparison
        
        // Test 1: base=[2,3], k=1
        // Python: (-0.5773502692, 0.0000000000)
        run_test(32'd1, 2'b00, 2'b01, -0.57735, 0.0, 0.01);
        
        // Test 2: base=[2,3], k=2  
        // Python: (0.0000000000, 0.8164965809)
        run_test(32'd2, 2'b00, 2'b01, 0.0, 0.81650, 0.01);
        
        // Test 3: base=[2,3], k=3
        // Python: (-0.0000000000, -0.3333333333)
        run_test(32'd3, 2'b00, 2'b01, 0.0, -0.33333, 0.01);
        
        // Test 4: base=[2,3], k=4
        // Python: (0.4714045208, 0.4714045208)
        run_test(32'd4, 2'b00, 2'b01, 0.47140, 0.47140, 0.01);
        
        // Test 5: base=[2,3], k=5
        // Python: (-0.6236095645, -0.6236095645)
        run_test(32'd5, 2'b00, 2'b01, -0.62361, -0.62361, 0.01);
        
        // Test 6: base=[2,7], k=1
        // Python: (-0.3779644730, 0.0000000000)
        $display("\nTesting base combination [2,7]:");
        run_test(32'd1, 2'b00, 2'b10, -0.37796, 0.0, 0.01);
        
        // Test 7: base=[3,7], k=1
        // Python: (-0.1889822365, 0.3273268354)
        $display("\nTesting base combination [3,7]:");
        run_test(32'd1, 2'b01, 2'b10, -0.18898, 0.32733, 0.01);
        
        $display("\nAll tests completed");
        $finish;
    end

endmodule