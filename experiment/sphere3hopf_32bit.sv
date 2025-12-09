/*
Sphere3Hopf Sequence Generator (32-bit)

This SystemVerilog module implements a Sphere3Hopf sequence generator for base triples
[2,3,7], [2,7,3], [3,2,7], [3,7,2], [7,2,3], [7,3,2]. The Sphere3Hopf sequence generates
uniformly distributed points on the 3-sphere (S³) using Hopf fibration coordinates.

The algorithm works by:
1. Generating three Van der Corput sequence values: vdc0, vdc1, vdc2
2. Converting to angles: phi = vdc0 * 2π, psy = vdc1 * 2π
3. Computing Hopf coordinates: cos(eta) = sqrt(vdc2), sin(eta) = sqrt(1 - vdc2)
4. Converting to 4D coordinates:
   - x = cos(eta) * cos(psy)
   - y = cos(eta) * sin(psy)
   - z = sin(eta) * cos(phi + psy)
   - w = sin(eta) * sin(phi + psy)

This implementation generates 32-bit fixed-point outputs for all four coordinates.
The Sphere3Hopf sequence is useful for applications requiring uniform sampling on the
3-sphere, such as quaternion generation for 3D rotations, SO(3) sampling, and 4D geometry.

Features:
- Configurable base triples (any permutation of [2,3,7])
- 32-bit fixed-point arithmetic for trigonometric and square root operations
- Synchronous design with clock and reset
- Pop/reseed interface matching Python API
- Valid output flag for timing control
- Built-in cosine, sine, and square root approximations
- Angle addition for phi + psy calculation
*/

module sphere3hopf_32bit #(
    parameter BASE_0 = 2,          // Base for phi angle (2, 3, or 7)
    parameter BASE_1 = 3,          // Base for psy angle (2, 3, or 7)
    parameter BASE_2 = 7,          // Base for eta coordinate (2, 3, or 7)
    parameter SCALE = 16,          // Scale for Van der Corput precision
    parameter ANGLE_BITS = 16      // Bits for angle representation
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] hopf_x,        // Hopf x-coordinate output
    output reg  [31:0] hopf_y,        // Hopf y-coordinate output
    output reg  [31:0] hopf_z,        // Hopf z-coordinate output
    output reg  [31:0] hopf_w,        // Hopf w-coordinate output
    output reg         valid          // Output valid flag
);

    // Internal signals for Van der Corput generators
    wire [31:0] vdc_out_0, vdc_out_1, vdc_out_2;
    wire        vdc_valid_0, vdc_valid_1, vdc_valid_2;

    // Angle and coordinate calculation
    reg [ANGLE_BITS-1:0] phi_reg, psy_reg;
    reg [31:0] vdc_value_0_reg, vdc_value_1_reg, vdc_value_2_reg;
    reg [31:0] cos_eta, sin_eta;
    reg [31:0] cos_psy, sin_psy;
    reg [31:0] cos_phi_plus_psy, sin_phi_plus_psy;
    reg [4:0] calc_iter;
    reg        calc_active;

    // Constants for 2π scaling and fixed-point arithmetic
    localparam TWO_PI_SCALE = (1 << ANGLE_BITS);
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point

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

    vdcorput_32bit #(
        .BASE(BASE_2),
        .SCALE(SCALE)
    ) vdc_gen_2 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out(vdc_out_2),
        .valid(vdc_valid_2)
    );

    // State machine
    reg [3:0] state;
    localparam IDLE = 4'b0000;
    localparam WAIT_VDC = 4'b0001;
    localparam ANGLE_CALC = 4'b0010;
    localparam ETA_CALC = 4'b0011;
    localparam TRIG_CALC = 4'b0100;
    localparam OUTPUT = 4'b0101;

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            hopf_x <= 32'd0;
            hopf_y <= 32'd0;
            hopf_z <= 32'd0;
            hopf_w <= 32'd0;
            valid <= 1'b0;
            phi_reg <= {ANGLE_BITS{1'b0}};
            psy_reg <= {ANGLE_BITS{1'b0}};
            vdc_value_0_reg <= 32'd0;
            vdc_value_1_reg <= 32'd0;
            vdc_value_2_reg <= 32'd0;
            cos_eta <= 32'd0;
            sin_eta <= 32'd0;
            cos_psy <= 32'd0;
            sin_psy <= 32'd0;
            cos_phi_plus_psy <= 32'd0;
            sin_phi_plus_psy <= 32'd0;
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
                    if (vdc_valid_0 && vdc_valid_1 && vdc_valid_2) begin
                        vdc_value_0_reg <= vdc_out_0;
                        vdc_value_1_reg <= vdc_out_1;
                        vdc_value_2_reg <= vdc_out_2;
                        state <= ANGLE_CALC;
                    end
                end

                ANGLE_CALC: begin
                    // Convert VDC values to angles: angle = vdc * 2π
                    phi_reg <= (vdc_value_0_reg * TWO_PI_SCALE) >> SCALE;
                    psy_reg <= (vdc_value_1_reg * TWO_PI_SCALE) >> SCALE;
                    calc_iter <= 5'b0;
                    calc_active <= 1'b1;
                    state <= ETA_CALC;
                end

                ETA_CALC: begin
                    if (calc_iter < 1) begin
                        calc_iter <= calc_iter + 1'b1;
                    end else begin
                        calc_active <= 1'b0;
                        state <= TRIG_CALC;
                    end
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
                    // Apply Hopf coordinate transformation
                    hopf_x <= (cos_eta * cos_psy) >> 31;
                    hopf_y <= (cos_eta * sin_psy) >> 31;
                    hopf_z <= (sin_eta * cos_phi_plus_psy) >> 31;
                    hopf_w <= (sin_eta * sin_phi_plus_psy) >> 31;
                    valid <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Variables for coordinate calculations
    reg [ANGLE_BITS:0] phi_plus_psi;

    // Coordinate calculations
    always @(posedge clk) begin
        if (calc_active) begin
            case (state)
                ETA_CALC: begin
                    // Calculate cos(eta) = sqrt(vdc2), sin(eta) = sqrt(1 - vdc2)
                    cos_eta <= sqrt_approx(vdc_value_2_reg);
                    sin_eta <= sqrt_approx((32'd1 << SCALE) - vdc_value_2_reg);
                end

                TRIG_CALC: begin
                    // Calculate trigonometric values
                    cos_psy <= cos_approx(psy_reg);
                    sin_psy <= sin_approx(psy_reg);

                    // Calculate phi + psy (angle addition)
                    phi_plus_psi = phi_reg + psy_reg;
                    cos_phi_plus_psy <= cos_approx(phi_plus_psi[ANGLE_BITS-1:0]);
                    sin_phi_plus_psy <= sin_approx(phi_plus_psi[ANGLE_BITS-1:0]);
                end

                default: ;
            endcase
        end
    end

    // Trigonometric approximation functions
    function automatic [31:0] cos_approx;
        input [ANGLE_BITS-1:0] angle;
        reg [31:0] result;
        begin
            case (angle[ANGLE_BITS-1:ANGLE_BITS-4])  // Use top 4 bits for coarse approximation
                4'b0000: result = 32'd2147483648;  // 0°
                4'b0001: result = 32'd2048909069;  // 22.5°
                4'b0010: result = 32'd1518500250;  // 45°
                4'b0011: result = 32'd673720364;   // 67.5°
                4'b0100: result = 32'd0;           // 90°
                4'b0101: result = 32'd3621193184;  // 112.5°
                4'b0110: result = 32'd628646298;   // 135°
                4'b0111: result = 32'd976064279;   // 157.5°
                4'b1000: result = 32'd2147483648;  // 180°
                4'b1001: result = 32'd976064279;   // 202.5°
                4'b1010: result = 32'd628646298;   // 225°
                4'b1011: result = 32'd3621193184;  // 247.5°
                4'b1100: result = 32'd0;           // 270°
                4'b1101: result = 32'd673720364;   // 292.5°
                4'b1110: result = 32'd1518500250;  // 315°
                4'b1111: result = 32'd2048909069;  // 337.5°
                default: result = 32'd2147483648;
            endcase
            cos_approx = result;
        end
    endfunction

    function automatic [31:0] sin_approx;
        input [ANGLE_BITS-1:0] angle;
        reg [31:0] result;
        begin
            case (angle[ANGLE_BITS-1:ANGLE_BITS-4])  // Use top 4 bits for coarse approximation
                4'b0000: result = 32'd0;           // 0°
                4'b0001: result = 32'd673720364;   // 22.5°
                4'b0010: result = 32'd1518500250;  // 45°
                4'b0011: result = 32'd2048909069;  // 67.5°
                4'b0100: result = 32'd2147483648;  // 90°
                4'b0101: result = 32'd2048909069;  // 112.5°
                4'b0110: result = 32'd1518500250;  // 135°
                4'b0111: result = 32'd673720364;   // 157.5°
                4'b1000: result = 32'd0;           // 180°
                4'b1001: result = 32'd3621193184;  // 202.5°
                4'b1010: result = 32'd628646298;   // 225°
                4'b1011: result = 32'd976064279;   // 247.5°
                4'b1100: result = 32'd2147483648;  // 270°
                4'b1101: result = 32'd976064279;   // 292.5°
                4'b1110: result = 32'd628646298;   // 315°
                4'b1111: result = 32'd3621193184;  // 337.5°
                default: result = 32'd0;
            endcase
            sin_approx = result;
        end
    endfunction

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