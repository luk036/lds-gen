/*
Simplified Testbench for Disk FSM-Based Sequential Implementation
Uses integer comparisons instead of real numbers for iverilog compatibility
*/

`timescale 1ns/1ps

module disk_fsm_32bit_simple_tb_simple;

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
        input [31:0] expected_x;  // 16.16 fixed-point
        input [31:0] expected_y;  // 16.16 fixed-point
        input [31:0] tolerance;   // 16.16 fixed-point tolerance
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
            
            // Check results with tolerance
            if ((result_x >= expected_x - tolerance) && 
                (result_x <= expected_x + tolerance) &&
                (result_y >= expected_y - tolerance) && 
                (result_y <= expected_y + tolerance)) begin
                $display("PASS: k=%0d, bases=[%0d,%0d]", 
                         test_k, test_base0+2, test_base1+2);
            end else begin
                $display("FAIL: k=%0d, bases=[%0d,%0d], result_x=%h, result_y=%h, expected_x=%h, expected_y=%h", 
                         test_k, test_base0+2, test_base1+2,
                         result_x, result_y, expected_x, expected_y);
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
        
        $display("Testing Disk sequence generator (simplified)");
        $display("=============================================");
        
        // Test cases in 16.16 fixed-point format
        // Tolerance: 0.01 in fixed-point = 0.01 * 65536 = 655
        
        // Test 1: base=[2,3], k=1
        // Python: (-0.5773502692, 0.0000000000)
        // -0.57735 * 65536 = -37836 (approx)
        run_test(32'd1, 2'b00, 2'b01, 32'hFFFF6A34, 32'h00000000, 32'd655);
        
        // Test 2: base=[2,3], k=2  
        // Python: (0.0000000000, 0.8164965809)
        // 0.81650 * 65536 = 53508 (approx)
        run_test(32'd2, 2'b00, 2'b01, 32'h00000000, 32'h0000D104, 32'd655);
        
        // Test 3: base=[2,3], k=3
        // Python: (-0.0000000000, -0.3333333333)
        // -0.33333 * 65536 = -21845 (approx)
        run_test(32'd3, 2'b00, 2'b01, 32'h00000000, 32'hFFFFAAAB, 32'd655);
        
        // Test 4: base=[2,3], k=4
        // Python: (0.4714045208, 0.4714045208)
        // 0.47140 * 65536 = 30899 (approx)
        run_test(32'd4, 2'b00, 2'b01, 32'h000078B3, 32'h000078B3, 32'd655);
        
        // Test 5: base=[2,3], k=5
        // Python: (-0.6236095645, -0.6236095645)
        // -0.62361 * 65536 = -40863 (approx)
        run_test(32'd5, 2'b00, 2'b01, 32'hFFFF60A1, 32'hFFFF60A1, 32'd655);
        
        $display("\nAll tests completed");
        $finish;
    end

endmodule