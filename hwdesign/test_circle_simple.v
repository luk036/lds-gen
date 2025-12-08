/*
Simple test for Circle module with updated angle calculation
*/

`timescale 1ns/1ps

module test_circle_simple;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel;
    wire [31:0] result_x;
    wire [31:0] result_y;
    wire done;
    wire ready;

    circle_fsm_32bit_simple dut (
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

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        k_in = 0;
        base_sel = 0;
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);
        
        $display("Testing Circle module with updated angle calculation");
        $display("=====================================================");
        
        // Test 1: base=2, k=1
        // Expected: vdc(1,2) = 0.5, angle = π, cos(π) = -1, sin(π) = 0
        $display("\nTest 1: base=2, k=1");
        k_in = 32'd1;
        base_sel = 2'b00;
        
        wait(ready == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(done == 1);
        @(posedge clk);
        
        $display("  Result x: 0x%08h (%0.6f)", result_x, $signed(result_x) / 65536.0);
        $display("  Result y: 0x%08h (%0.6f)", result_y, $signed(result_y) / 65536.0);
        $display("  Expected: x ≈ -1.0, y ≈ 0.0");
        
        #(CLK_PERIOD * 5);
        
        // Test 2: base=2, k=2
        // Expected: vdc(2,2) = 0.25, angle = π/2, cos(π/2) = 0, sin(π/2) = 1
        $display("\nTest 2: base=2, k=2");
        k_in = 32'd2;
        
        wait(ready == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(done == 1);
        @(posedge clk);
        
        $display("  Result x: 0x%08h (%0.6f)", result_x, $signed(result_x) / 65536.0);
        $display("  Result y: 0x%08h (%0.6f)", result_y, $signed(result_y) / 65536.0);
        $display("  Expected: x ≈ 0.0, y ≈ 1.0");
        
        #(CLK_PERIOD * 5);
        
        // Test 3: base=2, k=3
        // Expected: vdc(3,2) = 0.75, angle = 3π/2, cos(3π/2) = 0, sin(3π/2) = -1
        $display("\nTest 3: base=2, k=3");
        k_in = 32'd3;
        
        wait(ready == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(done == 1);
        @(posedge clk);
        
        $display("  Result x: 0x%08h (%0.6f)", result_x, $signed(result_x) / 65536.0);
        $display("  Result y: 0x%08h (%0.6f)", result_y, $signed(result_y) / 65536.0);
        $display("  Expected: x ≈ 0.0, y ≈ -1.0");
        
        #(CLK_PERIOD * 5);
        
        // Test 4: base=2, k=4
        // Expected: vdc(4,2) = 0.125, angle = π/4, cos(π/4) = 0.7071, sin(π/4) = 0.7071
        $display("\nTest 4: base=2, k=4");
        k_in = 32'd4;
        
        wait(ready == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(done == 1);
        @(posedge clk);
        
        $display("  Result x: 0x%08h (%0.6f)", result_x, $signed(result_x) / 65536.0);
        $display("  Result y: 0x%08h (%0.6f)", result_y, $signed(result_y) / 65536.0);
        $display("  Expected: x ≈ 0.7071, y ≈ 0.7071");
        
        $display("\nAll tests completed");
        $finish;
    end

endmodule