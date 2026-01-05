/*
Sphere3 FSM-Based Sequential Implementation (32-bit)
Generates points on 3-sphere using VdCorput and Sphere modules

The Sphere3 sequence generates points (x, y, z, w) on a 3-sphere by:
1. Using VdCorput to generate ti in [0, π/2]
2. Interpolating xi using precomputed tables F2 and X
3. Calculating cosxi = cos(xi), sinxi = sin(xi)
4. Using Sphere to generate (sx, sy, sz) on unit sphere
5. Computing x = sinxi * sx, y = sinxi * sy, z = sinxi * sz, w = cosxi

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer count (32-bit)
- base_sel0[1:0]: Base selection for VdCorput (00: base 2, 01: base 3, 10: base 7)
- base_sel1[1:0]: Base selection for Sphere VdCorput (00: base 2, 01: base 3, 10: base 7)
- base_sel2[1:0]: Base selection for Sphere Circle (00: base 2, 01: base 3, 10: base 7)

Outputs:
- result_x[31:0]: X-coordinate (16.16 fixed-point)
- result_y[31:0]: Y-coordinate (16.16 fixed-point)
- result_z[31:0]: Z-coordinate (16.16 fixed-point)
- result_w[31:0]: W-coordinate (16.16 fixed-point)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- START_VDC: Start VdCorput computation for ti
- WAIT_VDC: Wait for VdCorput to complete
- START_SPHERE: Start Sphere computation for (sx, sy, sz)
- WAIT_SPHERE: Wait for Sphere to complete
- CALC_TRIG: Calculate trigonometric functions
- WAIT_TRIG: Wait for trigonometric calculations
- CALC_OUTPUT: Calculate final outputs
- FINISH: Output results
*/

module sphere3_fsm_32bit_simple (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base_sel0,  // For VdCorput (ti)
    input [1:0] base_sel1,  // For Sphere VdCorput
    input [1:0] base_sel2,  // For Sphere Circle
    output reg [31:0] result_x,
    output reg [31:0] result_y,
    output reg [31:0] result_z,
    output reg [31:0] result_w,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 4'b0000;
    parameter START_VDC = 4'b0001;
    parameter WAIT_VDC = 4'b0010;
    parameter START_SPHERE = 4'b0011;
    parameter WAIT_SPHERE = 4'b0100;
    parameter CALC_TRIG = 4'b0101;
    parameter WAIT_TRIG = 4'b0110;
    parameter CALC_OUTPUT = 4'b0111;
    parameter FINISH = 4'b1000;

    reg [3:0] current_state, next_state;

    // Internal registers
    reg [31:0] k_reg;
    reg [31:0] ti_reg;      // ti in 16.16 fixed-point (0 to π/2)
    reg [31:0] xi_reg;      // xi in 16.16 fixed-point (interpolated)
    reg [31:0] cosxi_reg;   // cos(xi) in 16.16 fixed-point
    reg [31:0] sinxi_reg;   // sin(xi) in 16.16 fixed-point
    reg [31:0] sx_reg;      // Sphere x-coordinate
    reg [31:0] sy_reg;      // Sphere y-coordinate
    reg [31:0] sz_reg;      // Sphere z-coordinate

    // Fixed-point constants (16.16 format)
    parameter FP_ONE = 32'h00010000;      // 1.0
    parameter FP_HALF = 32'h00008000;     // 0.5
    parameter FP_PI = 32'h0003243F;       // π ≈ 3.1415926535
    parameter FP_HALF_PI = 32'h0001921F;  // π/2 ≈ 1.5707963268
    parameter FP_TWO = 32'h00020000;      // 2.0

    // Precomputed interpolation tables (simplified - using linear approximation)
    // In practice, these would be ROM tables
    // For now, we'll use a simple linear interpolation: xi ≈ ti * 2/π
    // xi = simple_interp(ti, F2, X) ≈ ti * 2/π for ti in [0, π/2]

    // Module instances
    wire [31:0] vdc_result;
    wire vdc_done;
    wire vdc_ready;
    reg vdc_start;

    wire [31:0] sphere_x, sphere_y, sphere_z;
    wire sphere_done;
    wire sphere_ready;
    reg sphere_start;

    wire [31:0] trig_cos, trig_sin;
    wire trig_done;
    reg trig_start;
    reg [31:0] trig_angle;

    // VdCorput instance for ti
    vdcorput_fsm_32bit_simple vdc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc_start),
        .k_in(k_reg),
        .base_sel(base_sel0),
        .result(vdc_result),
        .done(vdc_done),
        .ready(vdc_ready)
    );

    // Sphere instance for (sx, sy, sz)
    sphere_fsm_32bit_simple sphere_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sphere_start),
        .k_in(k_reg),
        .base_sel0(base_sel1),
        .base_sel1(base_sel2),
        .result_x(sphere_x),
        .result_y(sphere_y),
        .result_z(sphere_z),
        .done(sphere_done),
        .ready(sphere_ready)
    );

    // CORDIC trigonometric instance
    cordic_trig_16bit_simple_fixed trig_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(trig_start),
        .angle(trig_angle[31:16]),  // Use upper 16 bits for angle
        .cosine(trig_cos),
        .sine(trig_sin),
        .done(trig_done),
        .ready()
    );

    // Simple interpolation function: xi ≈ ti * 2/π
    // Since ti is in [0, π/2] and xi is in [0, π], the relationship is approximately linear
    function [31:0] interpolate_xi;
        input [31:0] ti;  // ti in [0, π/2]
        reg [63:0] temp;
        begin
            // xi = ti * (π / (π/2)) = ti * 2
            // But from Python code: ti = HALF_PI * vdc.pop(), xi = simple_interp(ti, F2, X)
            // For linear approximation: xi ≈ 2 * ti
            temp = ti * FP_TWO;  // ti * 2 in 32.32
            interpolate_xi = temp[47:16];  // Convert to 16.16
        end
    endfunction

    // FSM state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start) next_state = START_VDC;
            end
            START_VDC: next_state = WAIT_VDC;
            WAIT_VDC: begin
                if (vdc_done) next_state = START_SPHERE;
            end
            START_SPHERE: next_state = WAIT_SPHERE;
            WAIT_SPHERE: begin
                if (sphere_done) next_state = CALC_TRIG;
            end
            CALC_TRIG: next_state = WAIT_TRIG;
            WAIT_TRIG: begin
                if (trig_done) next_state = CALC_OUTPUT;
            end
            CALC_OUTPUT: next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            ti_reg <= 0;
            xi_reg <= 0;
            cosxi_reg <= 0;
            sinxi_reg <= 0;
            sx_reg <= 0;
            sy_reg <= 0;
            sz_reg <= 0;
            result_x <= 0;
            result_y <= 0;
            result_z <= 0;
            result_w <= 0;
            done <= 0;
            ready <= 1;
            vdc_start <= 0;
            sphere_start <= 0;
            trig_start <= 0;
            trig_angle <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    if (start) begin
                        ready <= 0;
                        k_reg <= k_in;
                    end
                end
                START_VDC: begin
                    vdc_start <= 1;
                end
                WAIT_VDC: begin
                    vdc_start <= 0;
                    if (vdc_done) begin
                        // Map vdc_result from [0,1] to [0, π/2] for ti
                        // ti = vdc_result * π/2
                        // In fixed-point: (vdc_result * FP_HALF_PI) >> 16
                        ti_reg <= (vdc_result * FP_HALF_PI) >> 16;
                    end
                end
                START_SPHERE: begin
                    sphere_start <= 1;
                end
                WAIT_SPHERE: begin
                    sphere_start <= 0;
                    if (sphere_done) begin
                        sx_reg <= sphere_x;
                        sy_reg <= sphere_y;
                        sz_reg <= sphere_z;

                        // Interpolate xi from ti using simplified linear approximation
                        xi_reg <= interpolate_xi(ti_reg);
                    end
                end
                CALC_TRIG: begin
                    // Start trigonometric calculation for cos(xi) and sin(xi)
                    // Convert xi from radians to 16-bit angle (0-65535 for 0-2π)
                    // xi is in [0, π] in 16.16 format
                    // Convert to 16-bit: (xi * 65536 / (2π)) = (xi * 65536) / (2 * FP_PI)
                    trig_angle <= (xi_reg * 32'd65536) / (FP_PI * 2);
                    trig_start <= 1;
                end
                WAIT_TRIG: begin
                    trig_start <= 0;
                    if (trig_done) begin
                        cosxi_reg <= trig_cos;
                        sinxi_reg <= trig_sin;
                    end
                end
                CALC_OUTPUT: begin
                    // Calculate final outputs:
                    // x = sinxi * sx, y = sinxi * sy, z = sinxi * sz, w = cosxi
                    // Fixed-point multiplication: (a * b) >> 16
                    result_x <= (sinxi_reg * sx_reg) >> 16;
                    result_y <= (sinxi_reg * sy_reg) >> 16;
                    result_z <= (sinxi_reg * sz_reg) >> 16;
                    result_w <= cosxi_reg;
                end
                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule