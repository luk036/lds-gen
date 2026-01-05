/*
Testbench for minimal Disk module
*/

`timescale 1ns/1ps

module disk_minimal_test2;

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

    disk_fsm_32bit_simple_minimal dut (
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

            $display("count=%0d, bases=[%0d,%0d], result_x=%h, result_y=%h",
                     test_k, test_base0+2, test_base1+2,
                     result_x, result_y);

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

        $display("Testing minimal Disk module");
        $display("===========================");

        // Test a few cases
        run_test(32'd1, 2'b00, 2'b01);  // base=[2,3], count=1
        run_test(32'd2, 2'b00, 2'b01);  // base=[2,3], count=2
        run_test(32'd3, 2'b00, 2'b01);  // base=[2,3], count=3

        $display("\nAll tests completed");
        $finish;
    end

endmodule