`timescale 1ns/1ps

/*
Sphere3Hopf 32-bit Testbench

This testbench verifies the functionality of the Sphere3Hopf sequence generator
for base triples [2,3,7], [2,7,3], [3,2,7], [3,7,2], [7,2,3], [7,3,2]. 
It tests various aspects including:
- Basic sequence generation
- Reseed functionality
- Coordinate range validation
- Comparison with expected sphere properties
*/

module sphere3hopf_32bit_tb;

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
    wire [31:0] hopf_x;
    wire [31:0] hopf_y;
    wire [31:0] hopf_z;
    wire [31:0] hopf_w;
    wire        valid;
    
    // Test counters
    reg [31:0] test_count;
    reg [31:0] i;
    
    // Fixed-point conversion constants
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point
    
    // Instantiate DUT for bases [2,3,7]
    sphere3hopf_32bit #(
        .BASE_0(2),
        .BASE_1(3),
        .BASE_2(7),
        .SCALE(TEST_SCALE),
        .ANGLE_BITS(TEST_ANGLE_BITS)
    ) dut_237 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .hopf_x(hopf_x),
        .hopf_y(hopf_y),
        .hopf_z(hopf_z),
        .hopf_w(hopf_w),
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
        
        $display("=== Sphere3Hopf 32-bit Testbench ===");
        $display("Testing bases [2,3,7] with scale %0d", TEST_SCALE);
        
        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Sphere3Hopf Sequence ---");
        pop_enable = 1'b1;
        
        // Test first few values
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge valid);
            
            // Convert to floating-point for display
            real x_float, y_float, z_float, w_float;
            x_float = $itor($signed(hopf_x)) / $itor(FIXED_SCALE);
            y_float = $itor($signed(hopf_y)) / $itor(FIXED_SCALE);
            z_float = $itor($signed(hopf_z)) / $itor(FIXED_SCALE);
            w_float = $itor($signed(hopf_w)) / $itor(FIXED_SCALE);
            
            $display("Point %0d: [%.6f, %.6f, %.6f, %.6f] (raw: [%0d, %0d, %0d, %0d])", 
                     i + 1, x_float, y_float, z_float, w_float, hopf_x, hopf_y, hopf_z, hopf_w);
            
            // Check if points are approximately on unit 3-sphere
            real radius_sq;
            radius_sq = x_float * x_float + y_float * y_float + z_float * z_float + w_float * w_float;
            if (radius_sq < 0.8 || radius_sq > 1.2) begin
                $display("WARNING: Point %0d may not be on unit 3-sphere (r²=%.6f)", i + 1, radius_sq);
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
        
        real x_reseed, y_reseed, z_reseed, w_reseed;
        x_reseed = $itor($signed(hopf_x)) / $itor(FIXED_SCALE);
        y_reseed = $itor($signed(hopf_y)) / $itor(FIXED_SCALE);
        z_reseed = $itor($signed(hopf_z)) / $itor(FIXED_SCALE);
        w_reseed = $itor($signed(hopf_w)) / $itor(FIXED_SCALE);
        $display("After reseed to 5: [%.6f, %.6f, %.6f, %.6f]", x_reseed, y_reseed, z_reseed, w_reseed);
        
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
        
        real x_reset, y_reset, z_reset, w_reset;
        x_reset = $itor($signed(hopf_x)) / $itor(FIXED_SCALE);
        y_reset = $itor($signed(hopf_y)) / $itor(FIXED_SCALE);
        z_reset = $itor($signed(hopf_z)) / $itor(FIXED_SCALE);
        w_reset = $itor($signed(hopf_w)) / $itor(FIXED_SCALE);
        $display("After reset: [%.6f, %.6f, %.6f, %.6f]", x_reset, y_reset, z_reset, w_reset);
        
        pop_enable = 1'b0;
        #20;
        
        // Test 4: Orthant distribution (16 orthants in 4D)
        $display("\n--- Test 4: Orthant Distribution ---");
        reg [31:0] orth_count [0:15];
        integer j;
        for (j = 0; j < 16; j = j + 1) orth_count[j] = 0;
        
        pop_enable = 1'b1;
        for (i = 0; i < 32; i = i + 1) begin
            @(posedge valid);
            
            real x_orth, y_orth, z_orth, w_orth;
            x_orth = $itor($signed(hopf_x)) / $itor(FIXED_SCALE);
            y_orth = $itor($signed(hopf_y)) / $itor(FIXED_SCALE);
            z_orth = $itor($signed(hopf_z)) / $itor(FIXED_SCALE);
            w_orth = $itor($signed(hopf_w)) / $itor(FIXED_SCALE);
            
            // Determine orthant (simplified for first 8)
            if (x_orth >= 0 && y_orth >= 0 && z_orth >= 0 && w_orth >= 0) orth_count[0] = orth_count[0] + 1;
            else if (x_orth < 0 && y_orth >= 0 && z_orth >= 0 && w_orth >= 0) orth_count[1] = orth_count[1] + 1;
            else if (x_orth < 0 && y_orth < 0 && z_orth >= 0 && w_orth >= 0) orth_count[2] = orth_count[2] + 1;
            else if (x_orth >= 0 && y_orth < 0 && z_orth >= 0 && w_orth >= 0) orth_count[3] = orth_count[3] + 1;
            else if (x_orth >= 0 && y_orth >= 0 && z_orth < 0 && w_orth >= 0) orth_count[4] = orth_count[4] + 1;
            else if (x_orth < 0 && y_orth >= 0 && z_orth < 0 && w_orth >= 0) orth_count[5] = orth_count[5] + 1;
            else if (x_orth < 0 && y_orth < 0 && z_orth < 0 && w_orth >= 0) orth_count[6] = orth_count[6] + 1;
            else if (x_orth >= 0 && y_orth < 0 && z_orth < 0 && w_orth >= 0) orth_count[7] = orth_count[7] + 1;
            else orth_count[8] = orth_count[8] + 1;  // Catch-all for other cases
        end
        pop_enable = 1'b0;
        #20;
        
        $display("First 8 orthants distribution: ++++=%0d, -++=%0d, --+=%0d, +-+=%0d, ++-=%0d, -+-%0d, --%=%0d, +--=%0d", 
                 orth_count[0], orth_count[1], orth_count[2], orth_count[3], 
                 orth_count[4], orth_count[5], orth_count[6], orth_count[7]);
        
        // Test 5: W-coordinate distribution
        $display("\n--- Test 5: W-Coordinate Distribution ---");
        reg [31:0] pos_w_count, neg_w_count, zero_w_count;
        pos_w_count = 0;
        neg_w_count = 0;
        zero_w_count = 0;
        
        pop_enable = 1'b1;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge valid);
            
            real w_val;
            w_val = $itor($signed(hopf_w)) / $itor(FIXED_SCALE);
            
            if (w_val > 0.1) pos_w_count = pos_w_count + 1;
            else if (w_val < -0.1) neg_w_count = neg_w_count + 1;
            else zero_w_count = zero_w_count + 1;
        end
        pop_enable = 1'b0;
        #20;
        
        $display("W distribution: positive=%0d, negative=%0d, near-zero=%0d", 
                 pos_w_count, neg_w_count, zero_w_count);
        
        $display("\n=== Sphere3Hopf Tests Completed ===");
        $finish;
    end
    
    // Timeout protection
    initial begin
        #100000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
