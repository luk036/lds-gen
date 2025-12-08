`timescale 1ns/1ps

module halton_simple_test;

    reg clk;
    reg rst_n;
    reg pop_enable;
    reg [31:0] seed;
    reg reseed_enable;
    wire [31:0] halton_out_0;
    wire [31:0] halton_out_1;
    wire valid;
    
    halton_32bit_fixed dut (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .halton_out_0(halton_out_0),
        .halton_out_1(halton_out_1),
        .valid(valid)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        pop_enable = 0;
        reseed_enable = 0;
        seed = 0;
        
        #10;
        rst_n = 1;
        #10;
        
        $display("Starting test");
        
        pop_enable = 1;
        #10;
        pop_enable = 0;
        
        @(posedge valid);
        $display("k=1: [%0d, %0d]", halton_out_0, halton_out_1);
        
        #10;
        
        pop_enable = 1;
        #10;
        pop_enable = 0;
        
        @(posedge valid);
        $display("k=2: [%0d, %0d]", halton_out_0, halton_out_1);
        
        #10;
        
        pop_enable = 1;
        #10;
        pop_enable = 0;
        
        @(posedge valid);
        $display("k=3: [%0d, %0d]", halton_out_0, halton_out_1);
        
        $finish;
    end
    
    initial #1000 $display("Timeout");

endmodule