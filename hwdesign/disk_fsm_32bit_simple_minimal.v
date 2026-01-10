/*
Disk FSM-Based Sequential Implementation (32-bit) - Minimal Version
Simplified for testing without complex CORDIC
*/

module disk_fsm_32bit_simple_minimal (
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
    parameter CALC_ANGLE = 4'b0101;
    parameter CALC_RADIUS = 4'b0110;
    parameter CALC_OUTPUT = 4'b0111;
    parameter FINISH = 4'b1000;

    reg [3:0] current_state, next_state;

    // Internal registers
    reg [31:0] k_reg;
    reg [31:0] vdc0_result_reg;
    reg [31:0] vdc1_result_reg;
    reg [31:0] angle_reg;      // angle in 16.16 fixed-point (0-1 maps to 0-2π)
    reg [31:0] radius_reg;     // radius in 16.16 fixed-point
    reg [31:0] cos_reg, sin_reg;

    // Fixed-point constants (16.16 format)
    parameter FP_ONE = 32'h00010000;      // 1.0
    parameter FP_HALF = 32'h00008000;     // 0.5
    parameter FP_PI = 32'h0003243F;       // π ≈ 3.14159
    parameter FP_2PI = 32'h0006487E;      // 2π ≈ 6.28318
    parameter FP_ONE_DIV_2PI = 32'h000028BE; // 1/(2π) ≈ 0.159155

    // VdCorput instances
    wire [31:0] vdc0_result, vdc1_result;
    wire vdc0_done, vdc1_done;
    wire vdc0_ready, vdc1_ready;
    reg vdc0_start, vdc1_start;

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

    // Square root approximation (simplified)
    function [31:0] sqrt_approx;
        input [31:0] x;
        begin
            // Simple approximation: sqrt(x) ≈ x for x in [0,1]
            // This is just for testing - actual implementation would use better approximation
            sqrt_approx = x;
        end
    endfunction

    // Simple cosine approximation (4-quadrant)
    function [31:0] cos_approx;
        input [31:0] angle;  // 0-65535 maps to 0-2π
        reg [1:0] quadrant;
        reg [15:0] reduced_angle;
        reg [31:0] result;
        begin
            // Determine quadrant (0-65535 → 0-3)
            quadrant = angle[15:14];

            // Reduce angle to 0-16383 (0-π/2)
            case (quadrant)
                2'b00: reduced_angle = angle[13:0];           // 0-90°
                2'b01: reduced_angle = 16'h4000 - angle[13:0]; // 90-180°
                2'b10: reduced_angle = angle[13:0] - 16'h4000; // 180-270°
                2'b11: reduced_angle = 16'h8000 - angle[13:0]; // 270-360°
            endcase

            // Simple linear approximation for cos in [0, π/2]
            // cos(θ) ≈ 1 - 2θ/π for θ in [0, π/2]
            // In fixed-point: result = FP_ONE - (2 * reduced_angle * FP_ONE / 16384)
            result = FP_ONE - ((reduced_angle * 2) >> 14);

            // Apply sign based on quadrant
            case (quadrant)
                2'b00: cos_approx = result;      // +cos
                2'b01: cos_approx = -result;     // -cos
                2'b10: cos_approx = -result;     // -cos
                2'b11: cos_approx = result;      // +cos
            endcase
        end
    endfunction

    // Simple sine approximation (4-quadrant)
    function [31:0] sin_approx;
        input [31:0] angle;  // 0-65535 maps to 0-2π
        reg [1:0] quadrant;
        reg [15:0] reduced_angle;
        reg [31:0] result;
        begin
            // Determine quadrant (0-65535 → 0-3)
            quadrant = angle[15:14];

            // Reduce angle to 0-16383 (0-π/2)
            case (quadrant)
                2'b00: reduced_angle = angle[13:0];           // 0-90°
                2'b01: reduced_angle = 16'h4000 - angle[13:0]; // 90-180°
                2'b10: reduced_angle = angle[13:0] - 16'h4000; // 180-270°
                2'b11: reduced_angle = 16'h8000 - angle[13:0]; // 270-360°
            endcase

            // Simple linear approximation for sin in [0, π/2]
            // sin(θ) ≈ 2θ/π for θ in [0, π/2]
            // In fixed-point: result = (2 * reduced_angle * FP_ONE / 16384)
            result = (reduced_angle * 2) >> 14;

            // Apply sign based on quadrant
            case (quadrant)
                2'b00: sin_approx = result;      // +sin
                2'b01: sin_approx = result;      // +sin
                2'b10: sin_approx = -result;     // -sin
                2'b11: sin_approx = -result;     // -sin
            endcase
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
                if (vdc1_done) next_state = CALC_ANGLE;
            end
            CALC_ANGLE: next_state = CALC_RADIUS;
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
            vdc0_result_reg <= 0;
            vdc1_result_reg <= 0;
            angle_reg <= 0;
            radius_reg <= 0;
            cos_reg <= 0;
            sin_reg <= 0;
            result_x <= 0;
            result_y <= 0;
            done <= 0;
            ready <= 1;
            vdc0_start <= 0;
            vdc1_start <= 0;
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
                        vdc0_result_reg <= vdc0_result;
                    end
                end
                START_VDC1: begin
                    vdc1_start <= 1;
                end
                WAIT_VDC1: begin
                    vdc1_start <= 0;
                    if (vdc1_done) begin
                        vdc1_result_reg <= vdc1_result;
                    end
                end
                CALC_ANGLE: begin
                    // Convert VdCorput output (0-1) to angle (0-2π)
                    // angle = vdc0_result * 2π
                    // In fixed-point: multiply by FP_2PI
                    angle_reg <= (vdc0_result_reg * FP_2PI) >> 16;

                    // Also pre-calculate cos and sin
                    cos_reg <= cos_approx(angle_reg[15:0]);
                    sin_reg <= sin_approx(angle_reg[15:0]);
                end
                CALC_RADIUS: begin
                    // radius = sqrt(vdc1_result)
                    radius_reg <= sqrt_approx(vdc1_result_reg);
                end
                CALC_OUTPUT: begin
                    // x = radius * cos(θ), y = radius * sin(θ)
                    result_x <= (radius_reg * cos_reg) >> 16;
                    result_y <= (radius_reg * sin_reg) >> 16;
                end
                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
