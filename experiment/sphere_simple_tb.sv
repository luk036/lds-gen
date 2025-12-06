`timescale 1ns/1ps

/*
Sphere Simple Testbench - Debug version
*/

module sphere_simple_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;
    parameter TEST_SCALE = 16;
    parameter TEST_ANGLE_BITS = 16;
    
    // Signals for DUT connections
    reg         clk;
    reg         rst_n;
    reg         pop_enable;
    reg  [31:0] seed;
    reg         reseed_enable;
    wire [31:0] sphere_x;
    wire [31:0] sphere_y;
    wire [31:0] sphere_z;
    wire        valid;
    
    // Instantiate DUT for bases [3,7]
    sphere_32bit #(
        .BASE_0(3),
        .BASE_1(7),
        .SCALE(TEST_SCALE),
        .ANGLE_BITS(TEST_ANGLE_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .sphere_x(sphere_x),
        .sphere_y(sphere_y),
        .sphere_z(sphere_z),
        .valid(valid)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 1'b0;
        pop_enable = 1'b0;
        reseed_enable = 1'b0;
        seed = 32'd0;
        
        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;
        
        $display("=== Sphere Simple Debug Testbench ===");
        
        // Test basic sequence generation
        pop_enable = 1'b1;
        
        // Wait for valid output with timeout
        fork
            begin
                @(posedge valid);
                $display("Valid output received at time %0t", $time);
                $display("Sphere output: x=%0d, y=%0d, z=%0d", sphere_x, sphere_y, sphere_z);
            end
            begin: timeout
                #1000;
                $display("Timeout - No valid output received");
            end
        join
        
        pop_enable = 1'b0;
        #20;
        
        $display("\n=== Debug Test Complete ===");
        $finish;
    end

endmodule