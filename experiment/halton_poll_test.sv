`timescale 1ns/1ps

module halton_poll_test;

    reg clk;
    reg rst_n;
    reg pop_enable;
    reg [31:0] seed;
    reg reseed_enable;
    wire [31:0] halton_out_0;
    wire [31:0] halton_out_1;
    wire valid;
    
    reg [31:0] test_count;
    
    halton_minimal dut (
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
        test_count = 0;
        
        #10;
        rst_n = 1;
        #10;
        
        $display("=== Halton Poll Test ===");
        
        while (test_count < 5) begin
            pop_enable = 1;
            #10;
            pop_enable = 0;
            
            // Poll for valid
            #20;
            if (valid) begin
                test_count = test_count + 1;
                $display("k=%0d: [%0d, %0d]", test_count, halton_out_0, halton_out_1);
            end else begin
                $display("No valid signal");
            end
            #20;
        end
        
        $finish;
    end
    
    initial #1000 $display("Timeout");

endmodule