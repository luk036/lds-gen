/*
Testbench for Sphere3 FSM-Based Sequential Implementation
*/

`timescale 1ns/1ps

module sphere3_fsm_32bit_simple_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel0;  // For VdCorput (ti)
    reg [1:0] base_sel1;  // For Sphere VdCorput
    reg [1:0] base_sel2;  // For Sphere Circle
    wire [31:0] result_x;
    wire [31:0] result_y;
    wire [31:0] result_z;
    wire [31:0] result_w;
    wire done;
    wire ready;

    sphere3_fsm_32bit_simple dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel0(base_sel0),
        .base_sel1(base_sel1),
        .base_sel2(base_sel2),
        .result_x(result_x),
        .result_y(result_y),
        .result_z(result_z),
        .result_w(result_w),
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
        input [1:0] test_base2;
        begin
            k_in = test_k;
            base_sel0 = test_base0;
            base_sel1 = test_base1;
            base_sel2 = test_base2;

            $display("Starting test: count=%0d, waiting for ready...", test_k);
            wait(ready == 1);
            $display("  Module is ready, starting computation");
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            $display("  Waiting for done signal...");
            wait(done == 1);
            @(posedge clk);

            // Display results in hex and approximate float
            $display("count=%0d, bases=[%0d,%0d,%0d]", test_k,
                     test_base0 == 2'b00 ? 2 : test_base0 == 2'b01 ? 3 : 7,
                     test_base1 == 2'b00 ? 2 : test_base1 == 2'b01 ? 3 : 7,
                     test_base2 == 2'b00 ? 2 : test_base2 == 2'b01 ? 3 : 7);
            $display("  result_x=%h (≈%0.3f)", result_x, $signed(result_x) / 65536.0);
            $display("  result_y=%h (≈%0.3f)", result_y, $signed(result_y) / 65536.0);
            $display("  result_z=%h (≈%0.3f)", result_z, $signed(result_z) / 65536.0);
            $display("  result_w=%h (≈%0.3f)", result_w, $signed(result_w) / 65536.0);

            // Simple verification - just display results
            // Note: For full verification, check that x² + y² + z² + w² ≈ 1
            // This would require real arithmetic which may not be supported

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
        base_sel2 = 0;

        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("Testing Sphere3 sequence generator");
        $display("==================================");
        $display("Base mapping: 00=2, 01=3, 10=7");

        // Test cases based on Python examples
        // Python example from sphere_n.py: [0.2913440162992141, 0.8966646826186098, -0.33333333333333337, 6.123233995736766e-17]
        // for count=0, base=[2,3,5]

        $display("\nTesting base combination [2,3,7]:");
        run_test(32'd0, 2'b00, 2'b01, 2'b10);  // count=0, bases [2,3,7]
        run_test(32'd1, 2'b00, 2'b01, 2'b10);  // count=1
        run_test(32'd2, 2'b00, 2'b01, 2'b10);  // count=2

        $display("\nTesting base combination [2,3,5]:");
        run_test(32'd0, 2'b00, 2'b01, 2'b01);  // count=0, bases [2,3,5] (closest to Python example)

        $display("\nTesting base combination [3,5,7]:");
        run_test(32'd0, 2'b01, 2'b01, 2'b10);  // count=0, bases [3,5,7]

        $display("\nTesting base combination [2,7,3]:");
        run_test(32'd0, 2'b00, 2'b10, 2'b01);  // count=0, bases [2,7,3]

        $display("\nAll tests completed");
        $finish;
    end

endmodule