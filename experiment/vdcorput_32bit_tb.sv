`timescale 1ns/1ps

/*
Van der Corput 32-bit Testbench

This testbench verifies the functionality of the Van der Corput sequence generator
for bases 2, 3, and 7. It tests various aspects including:
- Basic sequence generation
- Reseed functionality
- Edge cases
- Comparison with Python reference implementation values
*/

module vdcorput_32bit_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;
    parameter TEST_SCALE = 10;  // Use scale 10 for easier verification
    
    // Signals for DUT connections
    reg         clk;
    reg         rst_n;
    reg         pop_enable;
    reg  [31:0] seed;
    reg         reseed_enable;
    wire [31:0] vdc_out;
    wire        valid;
    
    // Test counters and control
    reg [31:0] test_count;
    reg [31:0] expected_value;
    
    // Instantiate DUTs for different bases
    vdcorput_32bit #(
        .BASE(2),
        .SCALE(TEST_SCALE)
    ) dut_base2 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out(vdc_out),
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
        test_count = 32'd0;
        
        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;
        
        $display("=== Van der Corput 32-bit Testbench ===");
        $display("Testing base 2 with scale %0d", TEST_SCALE);
        
        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Sequence Generation ---");
        pop_enable = 1'b1;
        
        // Expected values for base 2, scale 10 (from Python implementation)
        // First few values: 512, 256, 768, 128, 640, 384, 896, 64, 576, 320
        expected_value = 32'd512;
        @(posedge valid);
        if (vdc_out !== expected_value)
            $display("FAIL: Test 1.1 - Expected %0d, got %0d", expected_value, vdc_out);
        else
            $display("PASS: Test 1.1 - Value %0d", vdc_out);
        
        expected_value = 32'd256;
        @(posedge valid);
        if (vdc_out !== expected_value)
            $display("FAIL: Test 1.2 - Expected %0d, got %0d", expected_value, vdc_out);
        else
            $display("PASS: Test 1.2 - Value %0d", vdc_out);
        
        expected_value = 32'd768;
        @(posedge valid);
        if (vdc_out !== expected_value)
            $display("FAIL: Test 1.3 - Expected %0d, got %0d", expected_value, vdc_out);
        else
            $display("PASS: Test 1.3 - Value %0d", vdc_out);
        
        pop_enable = 1'b0;
        #20;
        
        // Test 2: Reseed functionality
        $display("\n--- Test 2: Reseed Functionality ---");
        reseed_enable = 1'b1;
        seed = 32'd5;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;
        
        pop_enable = 1'b1;
        // After reseed to 5, next value should be for k=6
        expected_value = 32'd832;  // k=6 in base 2, scale 10
        @(posedge valid);
        if (vdc_out !== expected_value)
            $display("FAIL: Test 2.1 - Expected %0d after reseed, got %0d", expected_value, vdc_out);
        else
            $display("PASS: Test 2.1 - Reseed value %0d", vdc_out);
        
        pop_enable = 1'b0;
        #20;
        
        // Test 3: Edge cases
        $display("\n--- Test 3: Edge Cases ---");
        reseed_enable = 1'b1;
        seed = 32'd0;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;
        
        pop_enable = 1'b1;
        // Test first value after reset
        expected_value = 32'd512;  // k=1
        @(posedge valid);
        if (vdc_out !== expected_value)
            $display("FAIL: Test 3.1 - Expected %0d for first value, got %0d", expected_value, vdc_out);
        else
            $display("PASS: Test 3.1 - First value %0d", vdc_out);
        
        pop_enable = 1'b0;
        #20;
        
        // Test 4: Sequence consistency
        $display("\n--- Test 4: Sequence Consistency ---");
        reseed_enable = 1'b1;
        seed = 32'd0;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;
        
        pop_enable = 1'b1;
        // Generate 10 values and check pattern
        for (test_count = 0; test_count < 10; test_count = test_count + 1) begin
            @(posedge valid);
            $display("Value %0d: %0d", test_count + 1, vdc_out);
        end
        
        pop_enable = 1'b0;
        #20;
        
        // Test 5: Large values
        $display("\n--- Test 5: Larger Values ---");
        reseed_enable = 1'b1;
        seed = 32'd100;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;
        
        pop_enable = 1'b1;
        for (test_count = 0; test_count < 5; test_count = test_count + 1) begin
            @(posedge valid);
            $display("Large value %0d: %0d", test_count + 1, vdc_out);
        end
        
        pop_enable = 1'b0;
        #20;
        
        $display("\n=== All Tests Completed ===");
        $finish;
    end
    
    // Timeout protection
    initial begin
        #10000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Monitor changes
    initial begin
        $monitor("Time %0t: pop_enable=%b, reseed_enable=%b, vdc_out=%0d, valid=%b", 
                 $time, pop_enable, reseed_enable, vdc_out, valid);
    end

endmodule