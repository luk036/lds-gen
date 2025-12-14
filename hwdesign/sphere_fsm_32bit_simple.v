/*
Sphere FSM-Based Sequential Implementation (32-bit)
Generates points on unit sphere using VdCorput and Circle modules

The Sphere sequence generates points (x, y, z) on a unit sphere by:
1. Using VdCorput to generate cosφ in [-1, 1] (φ = arccos(cosφ))
2. Calculating sinφ = sqrt(1 - cosφ²)
3. Using Circle to generate (c, s) on unit circle
4. Computing x = sinφ * c, y = sinφ * s, z = cosφ

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer k (32-bit)
- base_sel0[1:0]: Base selection for VdCorput (00: base 2, 01: base 3, 10: base 7)
- base_sel1[1:0]: Base selection for Circle (00: base 2, 01: base 3, 10: base 7)

Outputs:
- result_x[31:0]: X-coordinate (16.16 fixed-point)
- result_y[31:0]: Y-coordinate (16.16 fixed-point)
- result_z[31:0]: Z-coordinate (16.16 fixed-point)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- START_VDC: Start VdCorput computation for cosφ
- WAIT_VDC: Wait for VdCorput to complete
- START_CIRCLE: Start Circle computation for (c, s)
- WAIT_CIRCLE: Wait for Circle to complete
- CALC_SINPHI: Calculate sinφ = sqrt(1 - cosφ²)
- CALC_OUTPUT: Calculate final outputs
- FINISH: Output results
*/

module sphere_fsm_32bit_simple (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base_sel0,  // For VdCorput
    input [1:0] base_sel1,  // For Circle
    output reg [31:0] result_x,
    output reg [31:0] result_y,
    output reg [31:0] result_z,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 4'b0000;
    parameter START_VDC = 4'b0001;
    parameter WAIT_VDC = 4'b0010;
    parameter START_CIRCLE = 4'b0011;
    parameter WAIT_CIRCLE = 4'b0100;
    parameter CALC_SINPHI = 4'b0101;
    parameter CALC_OUTPUT = 4'b0110;
    parameter FINISH = 4'b0111;

    reg [3:0] current_state, next_state;

    // Internal registers
    reg [31:0] k_reg;
    reg [31:0] cosphi_reg;     // cosφ in 16.16 fixed-point
    reg [31:0] sinphi_reg;     // sinφ in 16.16 fixed-point
    reg [31:0] circle_x_reg;   // c from Circle
    reg [31:0] circle_y_reg;   // s from Circle

    // Temporary calculation registers
    reg [63:0] cosphi_sq;
    reg [31:0] one_minus_cosphi_sq;

    // Fixed-point constants (16.16 format)
    parameter FP_ONE = 32'h00010000;      // 1.0
    parameter FP_TWO = 32'h00020000;      // 2.0
    parameter FP_NEG_ONE = 32'hFFFF0000;  // -1.0

    // Module instances
    wire [31:0] vdc_result;
    wire vdc_done, vdc_ready;
    reg vdc_start;

    wire [31:0] circle_result_x, circle_result_y;
    wire circle_done, circle_ready;
    reg circle_start;

    // VdCorput instance for cosφ
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

    // Circle instance for (c, s)
    circle_fsm_32bit_simple_fixed circle_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(circle_start),
        .k_in(k_reg),
        .base_sel(base_sel1),
        .result_x(circle_result_x),
        .result_y(circle_result_y),
        .done(circle_done),
        .ready(circle_ready)
    );

    // Square root approximation function
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
                if (start) next_state = START_VDC;
            end
            START_VDC: next_state = WAIT_VDC;
            WAIT_VDC: begin
                if (vdc_done) next_state = START_CIRCLE;
            end
            START_CIRCLE: next_state = WAIT_CIRCLE;
            WAIT_CIRCLE: begin
                if (circle_done) next_state = CALC_SINPHI;
            end
            CALC_SINPHI: next_state = CALC_OUTPUT;
            CALC_OUTPUT: next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            cosphi_reg <= 0;
            sinphi_reg <= 0;
            circle_x_reg <= 0;
            circle_y_reg <= 0;
            result_x <= 0;
            result_y <= 0;
            result_z <= 0;
            done <= 0;
            ready <= 1;
            vdc_start <= 0;
            circle_start <= 0;
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
                        // Map vdc_result from [0,1] to [-1,1] for cosφ
                        // cosφ = 2 * vdc_result - 1
                        // In fixed-point: (vdc_result * 2) - FP_ONE
                        cosphi_reg <= (vdc_result << 1) - FP_ONE;
                    end
                end
                START_CIRCLE: begin
                    circle_start <= 1;
                end
                WAIT_CIRCLE: begin
                    circle_start <= 0;
                    if (circle_done) begin
                        circle_x_reg <= circle_result_x;
                        circle_y_reg <= circle_result_y;
                    end
                end
                CALC_SINPHI: begin
                    // Calculate sinφ = sqrt(1 - cosφ²)
                    // First calculate cosφ²
                    cosphi_sq = cosphi_reg * cosphi_reg;  // 32.32 result

                    // 1 - cosφ² (in 16.16)
                    one_minus_cosphi_sq = FP_ONE - (cosphi_sq >> 16);

                    // sqrt(1 - cosφ²)
                    sinphi_reg <= sqrt_approx(one_minus_cosphi_sq);
                end
                CALC_OUTPUT: begin
                    // x = sinφ * c, y = sinφ * s, z = cosφ
                    // Fixed-point multiplication: (a * b) >> 16
                    result_x <= (sinphi_reg * circle_x_reg) >> 16;
                    result_y <= (sinphi_reg * circle_y_reg) >> 16;
                    result_z <= cosphi_reg;
                end
                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule