/*
Sphere Sequence Generator (32-bit)

This SystemVerilog module implements a Sphere sequence generator for base pairs [2,3], [2,7], and [3,7].
The Sphere sequence generates uniformly distributed points on the unit sphere using cylindrical mapping:

1. A Van der Corput sequence for polar angle: cos(phi) = 2*vdc0 - 1, phi in [0,π]
2. A Van der Corput sequence for azimuthal angle: theta = 2π*vdc1, theta in [0,2π)
3. Converting to Cartesian coordinates:
   - x = sin(phi) * cos(theta)
   - y = sin(phi) * sin(theta)
   - z = cos(phi)

The algorithm works by:
1. Generating Van der Corput sequence value vdc0 in [0,1)
2. Converting to cos(phi): cos(phi) = 2*vdc0 - 1 (maps to [-1,1])
3. Computing sin(phi) = sqrt(1 - cos(phi)²)
4. Using second VdCorput for azimuthal angle theta
5. Computing 3D coordinates

This implementation generates 32-bit fixed-point outputs for all three coordinates.
The Sphere sequence is useful for applications requiring uniform sampling on spherical
domains, such as antenna pattern testing, spherical antenna arrays, and 3D sampling.

Features:
- Configurable base pairs ([2,3], [2,7], [3,7])
- 32-bit fixed-point arithmetic for trigonometric and square root operations
- Synchronous design with clock and reset
- Pop/reseed interface matching Python API
- Valid output flag for timing control
- Built-in cosine, sine, and square root approximations
*/

module sphere_32bit #(
    parameter BASE_0 = 2,          // Base for polar angle (2, 3, or 7)
    parameter BASE_1 = 3,          // Base for azimuthal angle (2, 3, or 7)
    parameter SCALE = 16,          // Scale for Van der Corput precision
    parameter ANGLE_BITS = 16      // Bits for angle representation
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] sphere_x,      // Sphere x-coordinate output
    output reg  [31:0] sphere_y,      // Sphere y-coordinate output
    output reg  [31:0] sphere_z,      // Sphere z-coordinate output
    output reg         valid          // Output valid flag
);

    // Internal signals for Van der Corput generators
    wire [31:0] vdc_out_0, vdc_out_1;
    wire        vdc_valid_0, vdc_valid_1;

    // Coordinate calculation
    reg [31:0] vdc_value_0_reg, vdc_value_1_reg;
    reg [31:0] cos_phi, sin_phi;
    reg [31:0] cos_theta, sin_theta;
    reg [4:0] calc_iter;
    reg        calc_active;
    reg [ANGLE_BITS-1:0] theta_angle;

    // Constants for fixed-point arithmetic
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point
    localparam TWO_PI_SCALE = 32'd4294967296;  // 2π in Q32 (approximately)

    // Instantiate Van der Corput generators
    vdcorput_32bit #(
        .BASE(BASE_0),
        .SCALE(SCALE)
    ) vdc_gen_0 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out(vdc_out_0),
        .valid(vdc_valid_0)
    );

    vdcorput_32bit #(
        .BASE(BASE_1),
        .SCALE(SCALE)
    ) vdc_gen_1 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out(vdc_out_1),
        .valid(vdc_valid_1)
    );

    // State machine
    reg [3:0] state;
    localparam IDLE = 4'b0000;
    localparam WAIT_VDC = 4'b0001;
    localparam PHI_CALC = 4'b0010;
    localparam TRIG_CALC = 4'b0011;
    localparam OUTPUT = 4'b0100;

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sphere_x <= 32'd0;
            sphere_y <= 32'd0;
            sphere_z <= 32'd0;
            valid <= 1'b0;
            vdc_value_0_reg <= 32'd0;
            vdc_value_1_reg <= 32'd0;
            cos_phi <= 32'd0;
            sin_phi <= 32'd0;
            cos_theta <= 32'd0;
            sin_theta <= 32'd0;
            calc_iter <= 5'b0;
            calc_active <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    calc_active <= 1'b0;

                    if (pop_enable) begin
                        state <= WAIT_VDC;
                    end
                end

                WAIT_VDC: begin
                    if (vdc_valid_0 && vdc_valid_1) begin
                        vdc_value_0_reg <= vdc_out_0;
                        vdc_value_1_reg <= vdc_out_1;
                        state <= PHI_CALC;
                    end
                end

                PHI_CALC: begin
                    // Convert VDC value to cos(phi): cos(phi) = 2*vdc - 1
                    // Map [0,1) to [-1,1]
                    cos_phi <= (vdc_value_0_reg << 1) - (32'd1 << SCALE);
                    calc_iter <= 5'b0;
                    calc_active <= 1'b1;
                    state <= TRIG_CALC;
                end

                TRIG_CALC: begin
                    if (calc_iter < 1) begin
                        calc_iter <= calc_iter + 1'b1;
                    end else begin
                        calc_active <= 1'b0;
                        state <= OUTPUT;
                    end
                end

                OUTPUT: begin
                    // Apply spherical coordinate transformation
                    sphere_x <= (sin_phi * cos_theta) >> 31;
                    sphere_y <= (sin_phi * sin_theta) >> 31;
                    sphere_z <= cos_phi;
                    valid <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Variables for square root calculation
    reg [63:0] cos_sq, one_minus_cos_sq;
    reg [31:0] sqrt_result;

    // Square root and trigonometric calculations
    always @(posedge clk) begin
        if (calc_active) begin
            // Calculate sin(phi) = sqrt(1 - cos(phi)²)
            // Using fixed-point arithmetic

            // cos(phi)²
            cos_sq = ($signed(cos_phi) * $signed(cos_phi)) >> 31;

            // 1 - cos(phi)²
            one_minus_cos_sq = (64'd1 << 31) - cos_sq;

            // Square root approximation
            sqrt_result = sqrt_approx(one_minus_cos_sq[31:0]);
            sin_phi <= sqrt_result;

            // Calculate trigonometric values for theta
            theta_angle = (vdc_value_1_reg * TWO_PI_SCALE) >> SCALE;

            case (theta_angle[ANGLE_BITS-1:ANGLE_BITS-4])  // Use top 4 bits
                4'b0000: begin cos_theta <= 32'd2147483648; sin_theta <= 32'd0; end      // 0°
                4'b0001: begin cos_theta <= 32'd2048909069; sin_theta <= 32'd673720364; end  // 22.5°
                4'b0010: begin cos_theta <= 32'd1518500250; sin_theta <= 32'd1518500250; end // 45°
                4'b0011: begin cos_theta <= 32'd673720364; sin_theta <= 32'd2048909069; end  // 67.5°
                4'b0100: begin cos_theta <= 32'd0; sin_theta <= 32'd2147483648; end         // 90°
                4'b0101: begin cos_theta <= 32'd3621193184; sin_theta <= 32'd2048909069; end // 112.5°
                4'b0110: begin cos_theta <= 32'd628646298; sin_theta <= 32'd1518500250; end // 135°
                4'b0111: begin cos_theta <= 32'd976064279; sin_theta <= 32'd673720364; end // 157.5°
                4'b1000: begin cos_theta <= 32'd2147483648; sin_theta <= 32'd0; end        // 180°
                4'b1001: begin cos_theta <= 32'd976064279; sin_theta <= 32'd3621193184; end // 202.5°
                4'b1010: begin cos_theta <= 32'd628646298; sin_theta <= 32'd628646298; end // 225°
                4'b1011: begin cos_theta <= 32'd3621193184; sin_theta <= 32'd976064279; end // 247.5°
                4'b1100: begin cos_theta <= 32'd0; sin_theta <= 32'd2147483648; end        // 270°
                4'b1101: begin cos_theta <= 32'd673720364; sin_theta <= 32'd976064279; end // 292.5°
                4'b1110: begin cos_theta <= 32'd1518500250; sin_theta <= 32'd628646298; end // 315°
                4'b1111: begin cos_theta <= 32'd2048909069; sin_theta <= 32'd3621193184; end // 337.5°
                default: begin cos_theta <= 32'd2147483648; sin_theta <= 32'd0; end
            endcase
        end
    end

    // Square root approximation function
    function automatic [31:0] sqrt_approx;
        input [31:0] x;
        reg [31:0] result;
        reg [31:0] temp;
        reg [5:0] i;
        begin
            result = 32'd0;
            temp = 32'd0;

            // Simple Newton-Raphson approximation
            if (x != 0) begin
                // Initial guess
                result = (x >> 1) + (1 << (SCALE/2));

                // Few iterations of Newton-Raphson
                for (i = 0; i < 4; i = i + 1) begin
                    temp = result + (x << SCALE) / result;
                    result = temp >> 1;
                end
            end

            sqrt_approx = result;
        end
    endfunction

endmodule