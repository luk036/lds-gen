/*
Minimal test for Disk module - test only VdCorput parts
*/

`timescale 1ns/1ps

module disk_minimal_test;

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

    // Test just the VdCorput modules first
    wire [31:0] vdc0_result, vdc1_result;
    wire vdc0_done, vdc1_done;
    wire vdc0_ready, vdc1_ready;
    
    vdcorput_fsm_32bit_simple vdc0 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel(base_sel0),
        .result(vdc0_result),
        .done(vdc0_done),
        .ready(vdc0_ready)
    );
    
    vdcorput_fsm_32bit_simple vdc1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .k_in(k_in),
        .base_sel(base_sel1),
        .result(vdc1_result),
        .done(vdc1_done),
        .ready(vdc1_ready)
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    task run_vdc_test;
        input [31:0] test_k;
        input [1:0] test_base;
        input [31:0] expected;  // 16.16 fixed-point
        input [31:0] tolerance; // 16.16 fixed-point tolerance
        begin
            k_in = test_k;
            
            wait(vdc0_ready == 1);
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            
            wait(vdc0_done == 1);
            @(posedge clk);
            
            if ((vdc0_result >= expected - tolerance) && 
                (vdc0_result <= expected + tolerance)) begin
                $display("PASS: k=%0d, base=%0d, result=%h, expected=%h", 
                         test_k, test_base+2, vdc0_result, expected);
            end else begin
                $display("FAIL: k=%0d, base=%0d, result=%h, expected=%h", 
                         test_k, test_base+2, vdc0_result, expected);
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
        
        $display("Testing VdCorput modules (basic functionality)");
        $display("==============================================");
        
        // Test VdCorput with base 2
        base_sel0 = 2'b00;  // Base 2
        
        // k=1: 0.5 in fixed-point = 0.5 * 65536 = 32768
        run_vdc_test(32'd1, 2'b00, 32'h00008000, 32'd100);
        
        // k=2: 0.25 in fixed-point = 0.25 * 65536 = 16384
        run_vdc_test(32'd2, 2'b00, 32'h00004000, 32'd100);
        
        // Test VdCorput with base 3
        base_sel0 = 2'b01;  // Base 3
        
        // k=1: 1/3 ≈ 0.33333 in fixed-point = 0.33333 * 65536 = 21845
        run_vdc_test(32'd1, 2'b01, 32'h00005555, 32'd100);
        
        // k=2: 2/3 ≈ 0.66667 in fixed-point = 0.66667 * 65536 = 43690
        run_vdc_test(32'd2, 2'b01, 32'h0000AAAA, 32'd100);
        
        $display("\nAll basic tests completed");
        $finish;
    end

endmodule