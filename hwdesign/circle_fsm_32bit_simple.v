/*
Circle FSM-Based Sequential Implementation (32-bit)
Generates points on unit circle using VdCorput for angles and CORDIC for trig

The Circle sequence generates points (x, y) on a unit circle by:
1. Using VdCorput to generate angle θ in [0, 2π]
2. Computing x = cos(θ) and y = sin(θ) using CORDIC

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer count (32-bit)
- base_sel[1:0]: Base selection (00: base 2, 01: base 3, 10: base 7)

Outputs:
- result_x[31:0]: X-coordinate (cosine, 16.16 fixed-point)
- result_y[31:0]: Y-coordinate (sine, 16.16 fixed-point)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- START_VDC: Start VdCorput computation for angle
- WAIT_VDC: Wait for VdCorput to complete
- START_CORDIC: Start CORDIC computation
- WAIT_CORDIC: Wait for CORDIC to complete
- FINISH: Output results

CORDIC Implementation:
- 16-bit angle input (0-65535 maps to 0-2π)
- 16 iterations for 16-bit precision
- Outputs scaled by CORDIC gain (0.607) and compensated
*/

module circle_fsm_32bit_simple (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base_sel,
    output reg [31:0] result_x,
    output reg [31:0] result_y,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 3'b000;
    parameter START_VDC = 3'b001;
    parameter WAIT_VDC = 3'b010;
    parameter START_CORDIC = 3'b011;
    parameter WAIT_CORDIC = 3'b100;
    parameter FINISH = 3'b101;

    reg [2:0] current_state, next_state;

    // VdCorput instance signals
    wire vdc_ready, vdc_done;
    wire [31:0] vdc_result;
    reg vdc_start;
    reg [31:0] k_reg;
    reg [31:0] angle_reg;  // Angle in 16.16 fixed-point (0-2π)

    // CORDIC signals
    reg cordic_start;
    wire cordic_done;
    wire [31:0] cordic_cos, cordic_sin;
    reg [15:0] cordic_angle;  // 16-bit angle for CORDIC

    // Constants
    parameter FP_TWO_PI = 32'h0006487F;  // 2π ≈ 6.283185 in 16.16 fixed-point
    parameter FP_ONE = 32'h00010000;     // 1.0 in fixed-point
    parameter FP_ONE_DIV_2PI = 32'h000028be;  // 1/(2π) ≈ 0.1591549 in 16.16

    // Instantiate VdCorput for angle generation
    vdcorput_fsm_32bit_simple vdc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc_start),
        .k_in(k_reg),
        .base_sel(base_sel),
        .result(vdc_result),
        .done(vdc_done),
        .ready(vdc_ready)
    );

    // Instantiate CORDIC for trigonometric functions
    cordic_trig_16bit_simple cordic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(cordic_start),
        .angle(cordic_angle),
        .cosine(cordic_cos),
        .sine(cordic_sin),
        .done(cordic_done),
        .ready()
    );

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
                if (vdc_done) next_state = START_CORDIC;
            end
            START_CORDIC: next_state = WAIT_CORDIC;
            WAIT_CORDIC: begin
                if (cordic_done) next_state = FINISH;
            end
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            vdc_start <= 0;
            cordic_start <= 0;
            angle_reg <= 0;
            cordic_angle <= 0;
            result_x <= 0;
            result_y <= 0;
            done <= 0;
            ready <= 1;
        end else begin
            case (current_state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    vdc_start <= 0;
                    cordic_start <= 0;
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
                        // Convert VdCorput result (0-1) to angle (0-2π)
                        // angle = vdc_result * 2π
                        // Fixed-point multiplication: vdc_result * FP_TWO_PI
                        angle_reg <= (vdc_result * FP_TWO_PI) >> 16;
                    end
                end
                START_CORDIC: begin
                    // Convert angle in radians (16.16) to CORDIC angle (0-65535)
                    // angle_reg is angle in radians * 65536
                    // CORDIC expects 0-65535 for 0-2π
                    // So: cordic_angle = angle_reg * (1/(2π)) = angle_reg * FP_ONE_DIV_2PI >> 16
                    cordic_angle <= (angle_reg * FP_ONE_DIV_2PI) >> 16;
                    cordic_start <= 1;
                end
                WAIT_CORDIC: begin
                    cordic_start <= 0;
                    // Wait for CORDIC to complete
                end
                FINISH: begin
                    result_x <= cordic_cos;
                    result_y <= cordic_sin;
                    done <= 1;
                end
            endcase
        end
    end

endmodule