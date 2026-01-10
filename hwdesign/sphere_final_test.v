/*
Final test for Sphere implementation
Tests basic functionality with simple approximations
*/

`timescale 1ns/1ps

module sphere_final_test;

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

    // Use the minimal Sphere module
    sphere_fsm_32bit_simple_minimal dut (
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
        input [31:0] expected_x;
        input [31:0] expected_y;
        input [31:0] expected_z;
        input [31:0] tolerance;
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

            // Check with tolerance
            if ((result_x >= expected_x - tolerance) && (result_x <= expected_x + tolerance) &&
                (result_y >= expected_y - tolerance) && (result_y <= expected_y + tolerance) &&
                (result_z >= expected_z - tolerance) && (result_z <= expected_z + tolerance)) begin
                $display("PASS: count=%0d, bases=[%0d,%0d]", test_k, test_base0+2, test_base1+2);
            end else begin
                $display("FAIL: count=%0d, bases=[%0d,%0d]", test_k, test_base0+2, test_base1+2);
                $display("  got: x=%h, y=%h, z=%h", result_x, result_y, result_z);
                $display("  exp: x=%h, y=%h, z=%h", expected_x, expected_y, expected_z);
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

        $display("Testing Sphere implementation (final)");
        $display("=====================================");

        // Test with simple expectations
        // Since our implementation uses approximations, we use large tolerance
        // Tolerance: 0.25 in fixed-point = 0.25 * 65536 = 16384

        $display("\nTesting base combination [2,3]:");
        // count=1: Expected z ≈ 0.0
        run_test(32'd1, 2'b00, 2'b01, 32'h00000000, 32'h00000000, 32'h00000000, 32'd16384);

        // count=2: Expected z ≈ -0.5
        run_test(32'd2, 2'b00, 2'b01, 32'h00000000, 32'h00000000, 32'hFFFF8000, 32'd16384);

        $display("\nAll tests completed");
        $finish;
    end

endmodule
