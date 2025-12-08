`timescale 1ns/1ps

module basic_test;

    reg clk;
    reg rst_n;
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $display("Test started");
        rst_n = 0;
        #10;
        rst_n = 1;
        #10;
        $display("Reset released");
        #100;
        $display("Test finished");
        $finish;
    end

endmodule