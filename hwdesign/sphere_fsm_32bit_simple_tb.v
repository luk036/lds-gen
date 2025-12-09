/*
Testbench for Sphere FSM-Based Sequential Implementation
*/

`timescale 1ns/1ps

module sphere_fsm_32bit_simple_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel0;
    reg [1:0] base_sel1;
    wire [31:0] result_x;
    wire [31:0] result_y;
    wire [31:0] result_z;
    wire done;
    wire ready;

    sphere_fsm_32bit_simple dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel0(base_sel0),
        .base_sel1(base_sel1),
        .result_x(result_x),
        .result_y(result_y),
        .result_z(result_z),
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

            // Display results in hex and approximate float
            $display("k=%0d, bases=[%0d,%0d]", test_k, test_base0+2, test_base1+2);
            $display("  result_x=%h (≈%0.3f)", result_x, $signed(result_x) / 65536.0);
            $display("  result_y=%h (≈%0.3f)", result_y, $signed(result_y) / 65536.0);
            $display("  result_z=%h (≈%0.3f)", result_z, $signed(result_z) / 65536.0);

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

        $display("Testing Sphere sequence generator");
        $display("=================================");

        // Test cases based on Python examples
        // Python example: [-0.4999999999999998, 0.8660254037844387, 0.0] for k=1, base=[2,3]

        $display("\nTesting base combination [2,3]:");
        run_test(32'd1, 2'b00, 2'b01);  // k=1
        run_test(32'd2, 2'b00, 2'b01);  // k=2
        run_test(32'd3, 2'b00, 2'b01);  // k=3

        $display("\nTesting base combination [2,7]:");
        run_test(32'd1, 2'b00, 2'b10);  // k=1

        $display("\nTesting base combination [3,7]:");
        run_test(32'd1, 2'b01, 2'b10);  // k=1

        $display("\nAll tests completed");
        $finish;
    end

endmodule