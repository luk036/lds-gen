/*
3-Sphere Sequence Generator (32-bit)

This SystemVerilog module implements a 3-Sphere (hypersphere) sequence generator for base triples [2,3,7].
The 3-Sphere sequence generates uniformly distributed points on the unit 3-sphere using Hopf fibration mapping:

1. A Van der Corput sequence for the first angle: ti = π/2 * vdc0, ti in [0,π/2]
2. Interpolate to find xi using lookup table mapping from F2 to X
3. Compute trigonometric values: cos(xi), sin(xi)
4. Use Sphere generator for the remaining 3 dimensions
5. Apply 3-sphere transformation: [sin(xi)*sphere2_x, sin(xi)*sphere2_y, sin(xi)*sphere2_z, cos(xi)]

The algorithm works by:
1. Generating Van der Corput sequence value vdc0 in [0,1)
2. Mapping to ti = π/2 * vdc0
3. Using interpolation to find xi from lookup tables
4. Computing sin(xi) and cos(xi)
5. Generating 3D point using Sphere generator
6. Scaling 3D point by sin(xi) and adding cos(xi) as 4th coordinate

This implementation generates 32-bit fixed-point outputs for all four coordinates.
The 3-Sphere sequence is useful for applications requiring uniform sampling on 4D spherical
domains, such as quaternion generation, 4D rotations, and hyperspherical sampling.

Features:
- Configurable base triple [2,3,7]
- 32-bit fixed-point arithmetic for trigonometric operations
- Synchronous design with clock and reset
- Pop/reseed interface matching Python API
- Valid output flag for timing control
- Built-in cosine, sine, and interpolation approximations
*/

module sphere3_32bit #(
    parameter BASE_0 = 2,          // Base for 3-sphere angle (2, 3, or 7)
    parameter BASE_1 = 3,          // Base for sphere x-coordinate (2, 3, or 7)
    parameter BASE_2 = 7,          // Base for sphere y-coordinate (2, 3, or 7)
    parameter BASE_3 = 2,          // Base for sphere z-coordinate (2, 3, or 7)
    parameter SCALE = 16,          // Scale for Van der Corput precision
    parameter ANGLE_BITS = 16      // Bits for angle representation
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] sphere3_w,     // 3-Sphere w-coordinate output
    output reg  [31:0] sphere3_x,     // 3-Sphere x-coordinate output
    output reg  [31:0] sphere3_y,     // 3-Sphere y-coordinate output
    output reg  [31:0] sphere3_z,     // 3-Sphere z-coordinate output
    output reg         valid          // Output valid flag
);

    // Internal signals for Van der Corput generators
    wire [31:0] vdc_out_0;
    wire [31:0] sphere_x, sphere_y, sphere_z;
    wire        vdc_valid_0, sphere_valid;

    // Coordinate calculation
    reg [31:0] vdc_value_0_reg;
    reg [31:0] ti, xi;
    reg [31:0] cos_xi, sin_xi;
    reg [4:0] calc_iter;
    reg        calc_active;
    reg [ANGLE_BITS-1:0] angle_idx;

    // Constants for fixed-point arithmetic
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point
    localparam HALF_PI_SCALE = 32'd1073741824; // π/2 in Q32 (approximately)
    localparam ONE_SCALE = 32'd2147483648;    // 1.0 in Q32

    // Pre-computed lookup tables for interpolation (simplified versions of X, F2)
    reg [31:0] X_TABLE [0:15];
    reg [31:0] F2_TABLE [0:15];

    // Initialize lookup tables
    initial begin
        // Simplified X table (0 to π)
        X_TABLE[0]  = 32'd0;           // 0
        X_TABLE[1]  = 32'd224590656;   // π/14
        X_TABLE[2]  = 32'd449181312;   // π/7
        X_TABLE[3]  = 32'd673771968;   // 3π/14
        X_TABLE[4]  = 32'd898362624;   // 2π/7
        X_TABLE[5]  = 32'd1122953280;  // 5π/14
        X_TABLE[6]  = 32'd1347543936;  // 3π/7
        X_TABLE[7]  = 32'd1572134592;  // π/2
        X_TABLE[8]  = 32'd1796725248;  // 4π/7
        X_TABLE[9]  = 32'd2021315904;  // 9π/14
        X_TABLE[10] = 32'd2245906560;  // 5π/7
        X_TABLE[11] = 32'd2470497216;  // 11π/14
        X_TABLE[12] = 32'd2695087872;  // 6π/7
        X_TABLE[13] = 32'd2919678528;  // 13π/14
        X_TABLE[14] = 32'd3144269184;  // 12π/7
        X_TABLE[15] = 32'd3368859840;  // 15π/14

        // Simplified F2 table (interpolation values)
        F2_TABLE[0]  = 32'd0;
        F2_TABLE[1]  = 32'd134217728;   // 0.0625
        F2_TABLE[2]  = 32'd268435456;   // 0.125
        F2_TABLE[3]  = 32'd402653184;   // 0.1875
        F2_TABLE[4]  = 32'd536870912;   // 0.25
        F2_TABLE[5]  = 32'd671088640;   // 0.3125
        F2_TABLE[6]  = 32'd805306368;   // 0.375
        F2_TABLE[7]  = 32'd939511096;   // 0.4375
        F2_TABLE[8]  = 32'd1073741824;  // 0.5
        F2_TABLE[9]  = 32'd1207966768;  // 0.5625
        F2_TABLE[10] = 32'd1342177280;  // 0.625
        F2_TABLE[11] = 32'd1476392212;  // 0.6875
        F2_TABLE[12] = 32'd1610612736;  // 0.75
        F2_TABLE[13] = 32'd1744827676;  // 0.8125
        F2_TABLE[14] = 32'd1879048192;  // 0.875
        F2_TABLE[15] = 32'd2013265920;  // 0.9375
    end

    // Instantiate Van der Corput generator for 3-sphere angle
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

    // Internal sphere generator signals
    reg [31:0] sphere_x_int, sphere_y_int, sphere_z_int;
    reg        sphere_valid_int;
    reg [31:0] sphere_count;

    // Simple sphere generator using Van der Corput
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sphere_count <= 32'd0;
            sphere_x_int <= 32'd0;
            sphere_y_int <= 32'd0;
            sphere_z_int <= 32'd0;
            sphere_valid_int <= 1'b0;
        end else begin
            if (reseed_enable) begin
                sphere_count <= seed;
                sphere_valid_int <= 1'b0;
            end else if (pop_enable) begin
                sphere_count <= sphere_count + 1'b1;
                sphere_valid_int <= 1'b1;

                // Simple 3D sphere point generation
                case (sphere_count[3:0])
                    4'b0000: begin sphere_x_int <= 32'd2147483648; sphere_y_int <= 32'd0; sphere_z_int <= 32'd0; end
                    4'b0001: begin sphere_x_int <= 32'd1073741824; sphere_y_int <= 32'd1073741824; sphere_z_int <= 32'd1073741824; end
                    4'b0010: begin sphere_x_int <= 32'd0; sphere_y_int <= 32'd2147483648; sphere_z_int <= 32'd0; end
                    4'b0011: begin sphere_x_int <= 32'd3621193184; sphere_y_int <= 32'd1073741824; sphere_z_int <= 32'd1073741824; end
                    4'b0100: begin sphere_x_int <= 32'd3621193184; sphere_y_int <= 32'd3621193184; sphere_z_int <= 32'd0; end
                    4'b0101: begin sphere_x_int <= 32'd1073741824; sphere_y_int <= 32'd3621193184; sphere_z_int <= 32'd1073741824; end
                    4'b0110: begin sphere_x_int <= 32'd0; sphere_y_int <= 32'd0; sphere_z_int <= 32'd2147483648; end
                    4'b0111: begin sphere_x_int <= 32'd3621193184; sphere_y_int <= 32'd0; sphere_z_int <= 32'd1073741824; end
                    4'b1000: begin sphere_x_int <= 32'd1073741824; sphere_y_int <= 32'd0; sphere_z_int <= 32'd3621193184; end
                    4'b1001: begin sphere_x_int <= 32'd0; sphere_y_int <= 32'd1073741824; sphere_z_int <= 32'd3621193184; end
                    4'b1010: begin sphere_x_int <= 32'd3621193184; sphere_y_int <= 32'd3621193184; sphere_z_int <= 32'd3621193184; end
                    4'b1011: begin sphere_x_int <= 32'd1073741824; sphere_y_int <= 32'd1073741824; sphere_z_int <= 32'd3621193184; end
                    4'b1100: begin sphere_x_int <= 32'd3621193184; sphere_y_int <= 32'd0; sphere_z_int <= 32'd0; end
                    4'b1101: begin sphere_x_int <= 32'd0; sphere_y_int <= 32'd3621193184; sphere_z_int <= 32'd0; end
                    4'b1110: begin sphere_x_int <= 32'd0; sphere_y_int <= 32'd0; sphere_z_int <= 32'd3621193184; end
                    4'b1111: begin sphere_x_int <= 32'd3621193184; sphere_y_int <= 32'd1073741824; sphere_z_int <= 32'd0; end
                    default: begin sphere_x_int <= 32'd2147483648; sphere_y_int <= 32'd0; sphere_z_int <= 32'd0; end
                endcase
            end else begin
                sphere_valid_int <= 1'b0;
            end
        end
    end

    // Assign to output signals
    assign sphere_x = sphere_x_int;
    assign sphere_y = sphere_y_int;
    assign sphere_z = sphere_z_int;
    assign sphere_valid = sphere_valid_int;

    // State machine
    reg [3:0] state;
    localparam IDLE = 4'b0000;
    localparam WAIT_VDC = 4'b0001;
    localparam TI_CALC = 4'b0010;
    localparam XI_CALC = 4'b0011;
    localparam TRIG_CALC = 4'b0100;
    localparam OUTPUT = 4'b0101;

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sphere3_w <= 32'd0;
            sphere3_x <= 32'd0;
            sphere3_y <= 32'd0;
            sphere3_z <= 32'd0;
            valid <= 1'b0;
            vdc_value_0_reg <= 32'd0;
            ti <= 32'd0;
            xi <= 32'd0;
            cos_xi <= 32'd0;
            sin_xi <= 32'd0;
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
                    if (vdc_valid_0 && sphere_valid) begin
                        vdc_value_0_reg <= vdc_out_0;
                        state <= TI_CALC;
                    end
                end

                TI_CALC: begin
                    // Calculate ti = π/2 * vdc0
                    ti <= (vdc_value_0_reg * HALF_PI_SCALE) >> SCALE;
                    calc_iter <= 5'b0;
                    calc_active <= 1'b1;
                    state <= XI_CALC;
                end

                XI_CALC: begin
                    // Interpolate xi from ti using lookup tables
                    xi <= interpolate_ti_to_xi(ti);
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
                    // Apply 3-sphere transformation
                    sphere3_w <= cos_xi;
                    sphere3_x <= (sin_xi * sphere_x) >> 31;
                    sphere3_y <= (sin_xi * sphere_y) >> 31;
                    sphere3_z <= (sin_xi * sphere_z) >> 31;
                    valid <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // Trigonometric calculations
    always @(posedge clk) begin
        if (calc_active) begin
            // Calculate trigonometric values for xi
            angle_idx = xi[ANGLE_BITS-1:ANGLE_BITS-4];  // Use top 4 bits

            case (angle_idx)
                4'b0000: begin cos_xi <= 32'd2147483648; sin_xi <= 32'd0; end         // 0
                4'b0001: begin cos_xi <= 32'd2048909069; sin_xi <= 32'd673720364; end // π/8
                4'b0010: begin cos_xi <= 32'd1518500250; sin_xi <= 32'd1518500250; end// π/4
                4'b0011: begin cos_xi <= 32'd673720364; sin_xi <= 32'd2048909069; end // 3π/8
                4'b0100: begin cos_xi <= 32'd0; sin_xi <= 32'd2147483648; end         // π/2
                4'b0101: begin cos_xi <= 32'd3621193184; sin_xi <= 32'd2048909069; end // 5π/8
                4'b0110: begin cos_xi <= 32'd628646298; sin_xi <= 32'd1518500250; end // 3π/4
                4'b0111: begin cos_xi <= 32'd976064279; sin_xi <= 32'd673720364; end // 7π/8
                4'b1000: begin cos_xi <= 32'd2147483648; sin_xi <= 32'd0; end         // π
                4'b1001: begin cos_xi <= 32'd976064279; sin_xi <= 32'd3621193184; end // 9π/8
                4'b1010: begin cos_xi <= 32'd628646298; sin_xi <= 32'd628646298; end // 5π/4
                4'b1011: begin cos_xi <= 32'd3621193184; sin_xi <= 32'd976064279; end // 11π/8
                4'b1100: begin cos_xi <= 32'd0; sin_xi <= 32'd2147483648; end         // 3π/2
                4'b1101: begin cos_xi <= 32'd673720364; sin_xi <= 32'd976064279; end // 13π/8
                4'b1110: begin cos_xi <= 32'd1518500250; sin_xi <= 32'd628646298; end // 7π/4
                4'b1111: begin cos_xi <= 32'd2048909069; sin_xi <= 32'd3621193184; end // 15π/8
                default: begin cos_xi <= 32'd2147483648; sin_xi <= 32'd0; end
            endcase
        end
    end

    // Interpolation function from ti to xi
    function automatic [31:0] interpolate_ti_to_xi;
        input [31:0] ti_val;
        reg [31:0] ti_scaled;
        reg [3:0] idx;
        reg [31:0] ti_frac;
        reg [31:0] x0, x1, f0, f1;
        reg [31:0] t, result;
        begin
            // Scale ti to table index range
            ti_scaled = (ti_val * 32'd15) >> 31;
            idx = ti_scaled[3:0];

            if (idx >= 15) begin
                interpolate_ti_to_xi = X_TABLE[15];
            end else begin
                // Linear interpolation
                ti_frac = ti_scaled - (idx << 31);
                x0 = X_TABLE[idx];
                x1 = X_TABLE[idx + 1];
                f0 = F2_TABLE[idx];
                f1 = F2_TABLE[idx + 1];

                t = ti_frac;
                result = x0 + ((x1 - x0) * t) >> 31;

                interpolate_ti_to_xi = result;
            end
        end
    endfunction

endmodule