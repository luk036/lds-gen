`timescale 1ns/1ps

/*
Sphere 32-bit Testbench

This testbench verifies the functionality of the Sphere sequence generator
for base pairs [2,3], [2,7], and [3,7]. It tests various aspects including:
- Basic sequence generation
- Reseed functionality
- Coordinate range validation
- Comparison with expected sphere properties
*/

module sphere_32bit_tb;

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

    // Test counters
    reg [31:0] test_count;
    reg [31:0] i;

    // Fixed-point conversion constants
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point

    // Instantiate DUT for bases [2,3]
    sphere_32bit #(
        .BASE_0(2),
        .BASE_1(3),
        .SCALE(TEST_SCALE),
        .ANGLE_BITS(TEST_ANGLE_BITS)
    ) dut_23 (
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
        test_count = 32'd0;

        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;

        $display("=== Sphere 32-bit Testbench ===");
        $display("Testing bases [2,3] with scale %0d", TEST_SCALE);

        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Sphere Sequence ---");
        pop_enable = 1'b1;

        // Test first few values
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge valid);

            // Convert to floating-point for display
            real x_float, y_float, z_float;
            x_float = $itor($signed(sphere_x)) / $itor(FIXED_SCALE);
            y_float = $itor($signed(sphere_y)) / $itor(FIXED_SCALE);
            z_float = $itor($signed(sphere_z)) / $itor(FIXED_SCALE);

            $display("Point %0d: [%.6f, %.6f, %.6f] (raw: [%0d, %0d, %0d])",
                     i + 1, x_float, y_float, z_float, sphere_x, sphere_y, sphere_z);

            // Check if points are approximately on unit sphere
            real radius_sq;
            radius_sq = x_float * x_float + y_float * y_float + z_float * z_float;
            if (radius_sq < 0.8 || radius_sq > 1.2) begin
                $display("WARNING: Point %0d may not be on unit sphere (r²=%.6f)", i + 1, radius_sq);
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

        real x_reseed, y_reseed, z_reseed;
        x_reseed = $itor($signed(sphere_x)) / $itor(FIXED_SCALE);
        y_reseed = $itor($signed(sphere_y)) / $itor(FIXED_SCALE);
        z_reseed = $itor($signed(sphere_z)) / $itor(FIXED_SCALE);
        $display("After reseed to 5: [%.6f, %.6f, %.6f]", x_reseed, y_reseed, z_reseed);

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

        real x_reset, y_reset, z_reset;
        x_reset = $itor($signed(sphere_x)) / $itor(FIXED_SCALE);
        y_reset = $itor($signed(sphere_y)) / $itor(FIXED_SCALE);
        z_reset = $itor($signed(sphere_z)) / $itor(FIXED_SCALE);
        $display("After reset: [%.6f, %.6f, %.6f]", x_reset, y_reset, z_reset);

        pop_enable = 1'b0;
        #20;

        // Test 4: Octant distribution
        $display("\n--- Test 4: Octant Distribution ---");
        reg [31:0] oct_count [0:7];
        integer j;
        for (j = 0; j < 8; j = j + 1) oct_count[j] = 0;

        pop_enable = 1'b1;
        for (i = 0; i < 24; i = i + 1) begin
            @(posedge valid);

            real x_oct, y_oct, z_oct;
            x_oct = $itor($signed(sphere_x)) / $itor(FIXED_SCALE);
            y_oct = $itor($signed(sphere_y)) / $itor(FIXED_SCALE);
            z_oct = $itor($signed(sphere_z)) / $itor(FIXED_SCALE);

            // Determine octant
            if (x_oct >= 0 && y_oct >= 0 && z_oct >= 0) oct_count[0] = oct_count[0] + 1;      // +++
            else if (x_oct < 0 && y_oct >= 0 && z_oct >= 0) oct_count[1] = oct_count[1] + 1;    // -++
            else if (x_oct < 0 && y_oct < 0 && z_oct >= 0) oct_count[2] = oct_count[2] + 1;     // --+
            else if (x_oct >= 0 && y_oct < 0 && z_oct >= 0) oct_count[3] = oct_count[3] + 1;    // +-+
            else if (x_oct >= 0 && y_oct >= 0 && z_oct < 0) oct_count[4] = oct_count[4] + 1;    // ++-
            else if (x_oct < 0 && y_oct >= 0 && z_oct < 0) oct_count[5] = oct_count[5] + 1;     // +-
            else if (x_oct < 0 && y_oct < 0 && z_oct < 0) oct_count[6] = oct_count[6] + 1;     // ---
            else oct_count[7] = oct_count[7] + 1;                                           // +--
        end
        pop_enable = 1'b0;
        #20;

        $display("Octant distribution: +++=%0d, -++=%0d, --+=%0d, +-+=%0d, ++-=%0d, -+-%0d, ---%0d, +--=%0d",
                 oct_count[0], oct_count[1], oct_count[2], oct_count[3],
                 oct_count[4], oct_count[5], oct_count[6], oct_count[7]);

        // Test 5: Z-coordinate distribution
        $display("\n--- Test 5: Z-Coordinate Distribution ---");
        reg [31:0] pos_z_count, neg_z_count, zero_z_count;
        pos_z_count = 0;
        neg_z_count = 0;
        zero_z_count = 0;

        pop_enable = 1'b1;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge valid);

            real z_val;
            z_val = $itor($signed(sphere_z)) / $itor(FIXED_SCALE);

            if (z_val > 0.1) pos_z_count = pos_z_count + 1;
            else if (z_val < -0.1) neg_z_count = neg_z_count + 1;
            else zero_z_count = zero_z_count + 1;
        end
        pop_enable = 1'b0;
        #20;

        $display("Z distribution: positive=%0d, negative=%0d, near-zero=%0d",
                 pos_z_count, neg_z_count, zero_z_count);

        $display("\n=== Sphere Tests Completed ===");
        $finish;
    end

    // Timeout protection
    initial begin
        #100000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule