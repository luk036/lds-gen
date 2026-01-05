/*
Testbench for Disk FSM-Based Sequential Implementation (Fixed version)
*/

`timescale 1ns/1ps

module disk_fsm_32bit_simple_fixed_tb;

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

    disk_fsm_32bit_simple_fixed dut (
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

    // Clock generation
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    // Main test sequence
    initial begin
        // Initialize
        clk = 0;
        rst_n = 0;
        start = 0;
        k_in = 0;
        base_sel0 = 0;
        base_sel1 = 0;

        // Apply reset
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("==========================================");
        $display("Starting Disk FSM Testbench (Fixed)");
        $display("==========================================");

        // Test 1: Base [2,3], count=1
        $display("\nTest 1: Base [2,3], count=1");
        wait(ready == 1'b1);
        @(posedge clk);
        k_in = 32'd1;
        base_sel0 = 2'b00;  // base 2
        base_sel1 = 2'b01;  // base 3
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(posedge clk);
        $display("Result: x=0x%08h, y=0x%08h", result_x, result_y);

        // Test 2: Base [2,3], count=2
        $display("\nTest 2: Base [2,3], count=2");
        wait(ready == 1'b1);
        @(posedge clk);
        k_in = 32'd2;
        base_sel0 = 2'b00;
        base_sel1 = 2'b01;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(posedge clk);
        $display("Result: x=0x%08h, y=0x%08h", result_x, result_y);

        // Test 3: Base [3,7], count=1
        $display("\nTest 3: Base [3,7], count=1");
        wait(ready == 1'b1);
        @(posedge clk);
        k_in = 32'd1;
        base_sel0 = 2'b01;  // base 3
        base_sel1 = 2'b10;  // base 7
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(posedge clk);
        $display("Result: x=0x%08h, y=0x%08h", result_x, result_y);

        $display("\n==========================================");
        $display("Testbench completed");
        $display("==========================================");

        // Finish simulation
        #(CLK_PERIOD * 10);
        $finish;
    end

    // Dump VCD file for waveform viewing
    initial begin
        $dumpfile("disk_fsm_32bit_simple_fixed_tb.vcd");
        $dumpvars(0, disk_fsm_32bit_simple_fixed_tb);
    end

endmodule
