/*
Sphere3Hopf FSM-Based Sequential Implementation (32-bit)
Generates points on 3-sphere using Hopf coordinates

The Sphere3Hopf sequence generates points (x, y, z, w) on a 3-sphere using Hopf fibration:
1. Use 3 VdCorput generators with bases [b0, b1, b2]
2. Generate angles: φ = 2π * vdc0, ψ = 2π * vdc1
3. Generate vdc = vdc2 (in [0,1])
4. Calculate cos_η = sqrt(vdc), sin_η = sqrt(1 - vdc)
5. Compute coordinates:
   x = cos_η * cos(ψ)
   y = cos_η * sin(ψ)
   z = sin_η * cos(φ + ψ)
   w = sin_η * sin(φ + ψ)

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer count (32-bit)
- base_sel0[1:0]: Base selection for VdCorput 0 (00: base 2, 01: base 3, 10: base 7)
- base_sel1[1:0]: Base selection for VdCorput 1 (00: base 2, 01: base 3, 10: base 7)
- base_sel2[1:0]: Base selection for VdCorput 2 (00: base 2, 01: base 3, 10: base 7)

Outputs:
- result_x[31:0]: X-coordinate (16.16 fixed-point)
- result_y[31:0]: Y-coordinate (16.16 fixed-point)
- result_z[31:0]: Z-coordinate (16.16 fixed-point)
- result_w[31:0]: W-coordinate (16.16 fixed-point)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- START_VDC0: Start VdCorput 0 computation for φ
- WAIT_VDC0: Wait for VdCorput 0 to complete
- START_VDC1: Start VdCorput 1 computation for ψ
- WAIT_VDC1: Wait for VdCorput 1 to complete
- START_VDC2: Start VdCorput 2 computation for vdc
- WAIT_VDC2: Wait for VdCorput 2 to complete
- CALC_TRIG: Calculate trigonometric functions
- WAIT_TRIG: Wait for trigonometric calculations
- CALC_SQRT: Calculate square roots
- CALC_OUTPUT: Calculate final outputs
- FINISH: Output results
*/

module sphere3hopf_fsm_32bit_simple (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base_sel0,  // For VdCorput 0 (φ)
    input [1:0] base_sel1,  // For VdCorput 1 (ψ)
    input [1:0] base_sel2,  // For VdCorput 2 (vdc)
    output reg [31:0] result_x,
    output reg [31:0] result_y,
    output reg [31:0] result_z,
    output reg [31:0] result_w,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 5'b00000;
    parameter START_VDC0 = 5'b00001;
    parameter WAIT_VDC0 = 5'b00010;
    parameter START_VDC1 = 5'b00011;
    parameter WAIT_VDC1 = 5'b00100;
    parameter START_VDC2 = 5'b00101;
    parameter WAIT_VDC2 = 5'b00110;
    parameter CALC_TRIG = 5'b00111;
    parameter WAIT_TRIG = 5'b01000;
    parameter CALC_SQRT = 5'b01001;
    parameter CALC_OUTPUT = 5'b01010;
    parameter FINISH = 5'b01011;

    reg [4:0] current_state, next_state;

    // Internal registers
    reg [31:0] k_reg;
    reg [31:0] phi_reg;      // φ angle in 16.16 fixed-point (0 to 2π)
    reg [31:0] psi_reg;      // ψ angle in 16.16 fixed-point (0 to 2π)
    reg [31:0] vdc_reg;      // vdc value in 16.16 fixed-point (0 to 1)
    reg [31:0] cos_eta_reg;  // cos(η) in 16.16 fixed-point
    reg [31:0] sin_eta_reg;  // sin(η) in 16.16 fixed-point
    reg [31:0] cos_psi_reg;  // cos(ψ) in 16.16 fixed-point
    reg [31:0] sin_psi_reg;  // sin(ψ) in 16.16 fixed-point
    reg [31:0] cos_phi_psi_reg;  // cos(φ+ψ) in 16.16 fixed-point
    reg [31:0] sin_phi_psi_reg;  // sin(φ+ψ) in 16.16 fixed-point

    // Temporary calculation registers
    reg [63:0] vdc_sq;
    reg [31:0] one_minus_vdc;

    // Fixed-point constants (16.16 format)
    parameter FP_ONE = 32'h00010000;      // 1.0
    parameter FP_TWO = 32'h00020000;      // 2.0
    parameter FP_PI = 32'h0003243F;       // π ≈ 3.1415926535
    parameter FP_TWO_PI = 32'h0006487E;   // 2π ≈ 6.283185307
    parameter FP_HALF_PI = 32'h0001921F;  // π/2 ≈ 1.5707963268

    // Module instances
    wire [31:0] vdc0_result, vdc1_result, vdc2_result;
    wire vdc0_done, vdc1_done, vdc2_done;
    wire vdc0_ready, vdc1_ready, vdc2_ready;
    reg vdc0_start, vdc1_start, vdc2_start;

    wire [31:0] trig_cos, trig_sin;
    wire trig_done;
    reg trig_start;
    reg [31:0] trig_angle;

    // VdCorput instances
    vdcorput_fsm_32bit_simple vdc0_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc0_start),
        .k_in(k_reg),
        .base_sel(base_sel0),
        .result(vdc0_result),
        .done(vdc0_done),
        .ready(vdc0_ready)
    );

    vdcorput_fsm_32bit_simple vdc1_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc1_start),
        .k_in(k_reg),
        .base_sel(base_sel1),
        .result(vdc1_result),
        .done(vdc1_done),
        .ready(vdc1_ready)
    );

    vdcorput_fsm_32bit_simple vdc2_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc2_start),
        .k_in(k_reg),
        .base_sel(base_sel2),
        .result(vdc2_result),
        .done(vdc2_done),
        .ready(vdc2_ready)
    );

    // CORDIC trigonometric instance (reuse from circle module)
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

    // Square root approximation function (same as in sphere module)
    function [31:0] sqrt_approx;
        input [31:0] x;  // 16.16 fixed-point input
        reg [31:0] y0, y1, y2;
        reg [63:0] x_div_y0, x_div_y1;
        begin
            // Newton-Raphson method for sqrt(x)
            // Initial guess: y0 = x + 0.5
            y0 = x + 32'h00008000;

            // First iteration: y1 = 0.5 * (y0 + x/y0)
            if (y0 != 0) begin
                x_div_y0 = (x << 16) / y0;  // x/y0 in 16.16
                y1 = (y0 + x_div_y0[31:0]) >> 1;  // 0.5 * (y0 + x/y0)
            end else begin
                y1 = 0;
            end

            // Second iteration: y2 = 0.5 * (y1 + x/y1)
            if (y1 != 0) begin
                x_div_y1 = (x << 16) / y1;  // x/y1 in 16.16
                y2 = (y1 + x_div_y1[31:0]) >> 1;  // 0.5 * (y1 + x/y1)
            end else begin
                y2 = 0;
            end

            sqrt_approx = y2;
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
                if (start) next_state = START_VDC0;
            end
            START_VDC0: next_state = WAIT_VDC0;
            WAIT_VDC0: begin
                if (vdc0_done) next_state = START_VDC1;
            end
            START_VDC1: next_state = WAIT_VDC1;
            WAIT_VDC1: begin
                if (vdc1_done) next_state = START_VDC2;
            end
            START_VDC2: next_state = WAIT_VDC2;
            WAIT_VDC2: begin
                if (vdc2_done) next_state = CALC_TRIG;
            end
            CALC_TRIG: next_state = WAIT_TRIG;
            WAIT_TRIG: begin
                if (trig_done) next_state = CALC_SQRT;
            end
            CALC_SQRT: next_state = CALC_OUTPUT;
            CALC_OUTPUT: next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            phi_reg <= 0;
            psi_reg <= 0;
            vdc_reg <= 0;
            cos_eta_reg <= 0;
            sin_eta_reg <= 0;
            cos_psi_reg <= 0;
            sin_psi_reg <= 0;
            cos_phi_psi_reg <= 0;
            sin_phi_psi_reg <= 0;
            result_x <= 0;
            result_y <= 0;
            result_z <= 0;
            result_w <= 0;
            done <= 0;
            ready <= 1;
            vdc0_start <= 0;
            vdc1_start <= 0;
            vdc2_start <= 0;
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
                START_VDC0: begin
                    vdc0_start <= 1;
                end
                WAIT_VDC0: begin
                    vdc0_start <= 0;
                    if (vdc0_done) begin
                        // Map vdc0_result from [0,1] to [0, 2π] for φ
                        // φ = vdc0_result * 2π
                        // In fixed-point: (vdc0_result * FP_TWO_PI) >> 16
                        phi_reg <= (vdc0_result * FP_TWO_PI) >> 16;
                    end
                end
                START_VDC1: begin
                    vdc1_start <= 1;
                end
                WAIT_VDC1: begin
                    vdc1_start <= 0;
                    if (vdc1_done) begin
                        // Map vdc1_result from [0,1] to [0, 2π] for ψ
                        // ψ = vdc1_result * 2π
                        psi_reg <= (vdc1_result * FP_TWO_PI) >> 16;
                    end
                end
                START_VDC2: begin
                    vdc2_start <= 1;
                end
                WAIT_VDC2: begin
                    vdc2_start <= 0;
                    if (vdc2_done) begin
                        // vdc2_result is already in [0,1]
                        vdc_reg <= vdc2_result;
                    end
                end
                CALC_TRIG: begin
                    // Start trigonometric calculations
                    // First calculate cos(ψ) and sin(ψ)
                    trig_angle <= psi_reg;
                    trig_start <= 1;
                end
                WAIT_TRIG: begin
                    trig_start <= 0;
                    if (trig_done) begin
                        cos_psi_reg <= trig_cos;
                        sin_psi_reg <= trig_sin;

                        // Now calculate cos(φ+ψ) and sin(φ+ψ)
                        trig_angle <= phi_reg + psi_reg;
                        trig_start <= 1;
                    end
                end
                CALC_SQRT: begin
                    trig_start <= 0;
                    if (trig_done) begin
                        cos_phi_psi_reg <= trig_cos;
                        sin_phi_psi_reg <= trig_sin;

                        // Calculate cos_η = sqrt(vdc) and sin_η = sqrt(1 - vdc)
                        // First calculate vdc²
                        vdc_sq = vdc_reg * vdc_reg;  // 32.32 result

                        // 1 - vdc (in 16.16)
                        one_minus_vdc = FP_ONE - (vdc_sq >> 16);

                        // sqrt(vdc) and sqrt(1 - vdc)
                        cos_eta_reg <= sqrt_approx(vdc_reg);
                        sin_eta_reg <= sqrt_approx(one_minus_vdc);
                    end
                end
                CALC_OUTPUT: begin
                    // Calculate final outputs:
                    // x = cos_η * cos(ψ)
                    // y = cos_η * sin(ψ)
                    // z = sin_η * cos(φ+ψ)
                    // w = sin_η * sin(φ+ψ)
                    // Fixed-point multiplication: (a * b) >> 16
                    result_x <= (cos_eta_reg * cos_psi_reg) >> 16;
                    result_y <= (cos_eta_reg * sin_psi_reg) >> 16;
                    result_z <= (sin_eta_reg * cos_phi_psi_reg) >> 16;
                    result_w <= (sin_eta_reg * sin_phi_psi_reg) >> 16;
                end
                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule