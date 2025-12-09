/*
Disk FSM-Based Sequential Implementation (32-bit) - Fixed for Yosys
Generates points uniformly distributed in unit disk

The Disk sequence generates points (x, y) in a unit disk by:
1. Using first VdCorput to generate angle θ in [0, 2π]
2. Using second VdCorput to generate radius r = sqrt(v) where v in [0, 1]
3. Computing x = r * cos(θ) and y = r * sin(θ)

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer k (32-bit)
- base_sel0[1:0]: Base selection for first VdCorput (00: base 2, 01: base 3, 10: base 7)
- base_sel1[1:0]: Base selection for second VdCorput

Outputs:
- result_x[31:0]: X-coordinate (16.16 fixed-point)
- result_y[31:0]: Y-coordinate (16.16 fixed-point)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- START_VDC0: Start first VdCorput for angle
- WAIT_VDC0: Wait for first VdCorput to complete
- START_VDC1: Start second VdCorput for radius
- WAIT_VDC1: Wait for second VdCorput to complete
- START_CORDIC: Start CORDIC computation for cos/sin
- WAIT_CORDIC: Wait for CORDIC to complete
- CALC_RADIUS: Calculate sqrt(radius)
- CALC_OUTPUT: Calculate final x = r*cos, y = r*sin
- FINISH: Output results
*/

module disk_fsm_32bit_simple_fixed (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base_sel0,
    input [1:0] base_sel1,
    output reg [31:0] result_x,
    output reg [31:0] result_y,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 4'b0000;
    parameter START_VDC0 = 4'b0001;
    parameter WAIT_VDC0 = 4'b0010;
    parameter START_VDC1 = 4'b0011;
    parameter WAIT_VDC1 = 4'b0100;
    parameter START_CORDIC = 4'b0101;
    parameter WAIT_CORDIC = 4'b0110;
    parameter CALC_RADIUS = 4'b0111;
    parameter CALC_OUTPUT = 4'b1000;
    parameter FINISH = 4'b1001;

    reg [3:0] current_state, next_state;

    // VdCorput instance 0 signals (for angle)
    wire vdc0_ready, vdc0_done;
    wire [31:0] vdc0_result;
    reg vdc0_start;
    reg [31:0] k_reg;
    reg [31:0] angle_reg;  // Angle in 16.16 fixed-point (0-2π)

    // VdCorput instance 1 signals (for radius)
    wire vdc1_ready, vdc1_done;
    wire [31:0] vdc1_result;
    reg vdc1_start;
    reg [31:0] radius_sq_reg;  // radius^2 in 16.16 fixed-point (0-1)
    reg [31:0] radius_reg;     // sqrt(radius_sq) in 16.16 fixed-point (0-1)

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

    // Instantiate VdCorput for radius generation
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

    // Instantiate CORDIC for trigonometric functions (using fixed version)
    cordic_trig_16bit_simple_fixed cordic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(cordic_start),
        .angle(cordic_angle),
        .cosine(cordic_cos),
        .sine(cordic_sin),
        .done(cordic_done),
        .ready()
    );

    // Square root approximation
    wire [31:0] sqrt_result;
    sqrt_approx_16_16 sqrt_inst (
        .x(radius_sq_reg),
        .y(sqrt_result)
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
                if (start) next_state = START_VDC0;
            end
            START_VDC0: next_state = WAIT_VDC0;
            WAIT_VDC0: begin
                if (vdc0_done) next_state = START_VDC1;
            end
            START_VDC1: next_state = WAIT_VDC1;
            WAIT_VDC1: begin
                if (vdc1_done) next_state = START_CORDIC;
            end
            START_CORDIC: next_state = WAIT_CORDIC;
            WAIT_CORDIC: begin
                if (cordic_done) next_state = CALC_RADIUS;
            end
            CALC_RADIUS: next_state = CALC_OUTPUT;
            CALC_OUTPUT: next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            vdc0_start <= 0;
            vdc1_start <= 0;
            cordic_start <= 0;
            angle_reg <= 0;
            radius_sq_reg <= 0;
            radius_reg <= 0;
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
                    vdc0_start <= 0;
                    vdc1_start <= 0;
                    cordic_start <= 0;
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
                        // Convert VdCorput result (0-1) to angle (0-2π)
                        // angle = vdc0_result * 2π
                        angle_reg <= (vdc0_result * FP_TWO_PI) >> 16;
                        // Convert to 16-bit CORDIC angle (0-65535 for 0-2π)
                        cordic_angle <= angle_reg[31:16];
                    end
                end
                START_VDC1: begin
                    vdc1_start <= 1;
                end
                WAIT_VDC1: begin
                    vdc1_start <= 0;
                    if (vdc1_done) begin
                        // Store radius^2 (vdc1_result is in [0, 1])
                        radius_sq_reg <= vdc1_result;
                    end
                end
                START_CORDIC: begin
                    cordic_start <= 1;
                end
                WAIT_CORDIC: begin
                    cordic_start <= 0;
                    // Wait for cordic_done
                end
                CALC_RADIUS: begin
                    // Calculate sqrt(radius_sq) using sqrt module
                    radius_reg <= sqrt_result;
                end
                CALC_OUTPUT: begin
                    // Calculate x = r * cos(θ), y = r * sin(θ)
                    // In fixed-point: (radius_reg * cordic_cos) >> 16
                    result_x <= (radius_reg * cordic_cos) >> 16;
                    result_y <= (radius_reg * cordic_sin) >> 16;
                end
                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule