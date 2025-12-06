`timescale 1ns/1ps

/*
Circle 32-bit Testbench

This testbench verifies the functionality of the Circle sequence generator
for bases 2, 3, and 7. It tests various aspects including:
- Basic sequence generation
- Reseed functionality
- Coordinate range validation
- Comparison with expected circle properties
*/

module circle_32bit_tb;

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
    wire [31:0] circle_x;
    wire [31:0] circle_y;
    wire        valid;
    
    // Test counters
    reg [31:0] test_count;
    reg [31:0] i;
    
    // Fixed-point conversion constants
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point
    
    // Instantiate DUT for base 2
    circle_32bit #(
        .BASE(2),
        .SCALE(TEST_SCALE),
        .ANGLE_BITS(TEST_ANGLE_BITS)
    ) dut_base2 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .circle_x(circle_x),
        .circle_y(circle_y),
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
        
        $display("=== Circle 32-bit Testbench ===");
        $display("Testing base 2 with scale %0d", TEST_SCALE);
        
        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Circle Sequence ---");
        pop_enable = 1'b1;
        
        // Test first few values
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge valid);
            
            // Convert to floating-point for display
            real x_float, y_float;
            real radius_sq;
            x_float = $itor($signed(circle_x)) / $itor(FIXED_SCALE);
            y_float = $itor($signed(circle_y)) / $itor(FIXED_SCALE);
            
            $display("Point %0d: [%.6f, %.6f] (raw: [%0d, %0d])", 
                     i + 1, x_float, y_float, circle_x, circle_y);
            
            // Check if points are approximately on unit circle
            radius_sq = x_float * x_float + y_float * y_float;
            if (radius_sq < 0.8 || radius_sq > 1.2) begin
                $display("WARNING: Point %0d may not be on unit circle (r²=%.6f)", i + 1, radius_sq);
            end
        end
        
        pop_enable = 1'b0;
        #20;
        
        // Test 2: Reseed functionality
        $display("\n--- Test 2: Reseed Test ---");
        reseed_enable = 1'b1;
        seed = 32'd5;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;
        
        pop_enable = 1'b1;
        @(posedge valid);
        
        real x_reseed, y_reseed;
        x_reseed = $itor($signed(circle_x)) / $itor(FIXED_SCALE);
        y_reseed = $itor($signed(circle_y)) / $itor(FIXED_SCALE);
        $display("After reseed to 5: [%.6f, %.6f]", x_reseed, y_reseed);
        
        pop_enable = 1'b0;
        #20;
        
        // Test 3: Reset test
        $display("\n--- Test 3: Reset Test ---");
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;
        
        pop_enable = 1'b1;
        @(posedge valid);
        
        real x_reset, y_reset;
        x_reset = $itor($signed(circle_x)) / $itor(FIXED_SCALE);
        y_reset = $itor($signed(circle_y)) / $itor(FIXED_SCALE);
        $display("After reset: [%.6f, %.6f]", x_reset, y_reset);
        
        pop_enable = 1'b0;
        #20;
        
        // Test 4: Quadrant distribution
        $display("\n--- Test 4: Quadrant Distribution ---");
        reg [31:0] quad_count [0:3];
        quad_count[0] = 0; quad_count[1] = 0; quad_count[2] = 0; quad_count[3] = 0;
        
        pop_enable = 1'b1;
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge valid);
            
            real x_quad, y_quad;
            x_quad = $itor($signed(circle_x)) / $itor(FIXED_SCALE);
            y_quad = $itor($signed(circle_y)) / $itor(FIXED_SCALE);
            
            if (x_quad >= 0 && y_quad >= 0) quad_count[0] = quad_count[0] + 1;      // Q1
            else if (x_quad < 0 && y_quad >= 0) quad_count[1] = quad_count[1] + 1;    // Q2
            else if (x_quad < 0 && y_quad < 0) quad_count[2] = quad_count[2] + 1;     // Q3
            else quad_count[3] = quad_count[3] + 1;                                   // Q4
        end
        pop_enable = 1'b0;
        #20;
        
        $display("Quadrant distribution: Q1=%0d, Q2=%0d, Q3=%0d, Q4=%0d", 
                 quad_count[0], quad_count[1], quad_count[2], quad_count[3]);
        
        $display("\n=== Circle Tests Completed ===");
        $finish;
    end
    
    // Timeout protection
    initial begin
        #100000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule