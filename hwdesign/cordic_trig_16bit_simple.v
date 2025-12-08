/*
Simple 16-bit CORDIC Trigonometric Module
Direct translation of working 8-bit version with proper scaling

Inputs:
- clk: System clock
- rst_n: Active-low reset
- angle[15:0]: Input angle (0-65535 maps to 0-2π)

Outputs:
- cosine[31:0]: Cosine output (16.16 fixed-point)
- sine[31:0]: Sine output (16.16 fixed-point)
- done: Computation complete
- ready: Module ready for new input

Algorithm:
- 16 iterations for 16-bit precision
- Rotation mode CORDIC
- Fixed-point arithmetic with proper scaling
*/

module cordic_trig_16bit_simple (
    input clk,
    input rst_n,
    input start,
    input [15:0] angle,
    output reg [31:0] cosine,
    output reg [31:0] sine,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 2'b00;
    parameter COMPUTE = 2'b01;
    parameter FINISH = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] iteration;
    
    // Arctan table for 16-bit CORDIC (atan(2^-i) in 16-bit units)
    // Values in 16-bit fixed-point where 65536 = 2π
    // atan(2^-i) * 65536 / (2π)
    reg [15:0] atan_table [0:15];
    
    // CORDIC variables (17-bit with guard bit)
    reg [16:0] x, y;
    reg [15:0] z;
    reg [15:0] angle_reg;  // Store original angle for quadrant correction
    
    // CORDIC gain K ≈ 0.607253
    // In 17-bit: 0.607253 * 65536 = 39797
    parameter K = 17'd39797;
    
    // Initialize arctan table
    integer i;
    initial begin
        // Precomputed atan(2^-i) * 65536 / (2π)
        atan_table[0] = 16'h2000;   // atan(1) = 45° = π/4 = 8192
        atan_table[1] = 16'h12E4;   // atan(1/2) ≈ 26.565° = 4836
        atan_table[2] = 16'h09FB;   // atan(1/4) ≈ 14.036° = 2555
        atan_table[3] = 16'h0511;   // atan(1/8) ≈ 7.125° = 1297
        atan_table[4] = 16'h028B;   // atan(1/16) ≈ 3.576° = 651
        atan_table[5] = 16'h0146;   // atan(1/32) ≈ 1.790° = 326
        atan_table[6] = 16'h00A3;   // atan(1/64) ≈ 0.895° = 163
        atan_table[7] = 16'h0051;   // atan(1/128) ≈ 0.448° = 81
        atan_table[8] = 16'h0029;   // atan(1/256) ≈ 0.224° = 41
        atan_table[9] = 16'h0014;   // atan(1/512) ≈ 0.112° = 20
        atan_table[10] = 16'h000A;  // atan(1/1024) ≈ 0.056° = 10
        atan_table[11] = 16'h0005;  // atan(1/2048) ≈ 0.028° = 5
        atan_table[12] = 16'h0003;  // atan(1/4096) ≈ 0.014° = 3
        atan_table[13] = 16'h0001;  // atan(1/8192) ≈ 0.007° = 1
        atan_table[14] = 16'h0001;  // atan(1/16384) ≈ 0.004° = 1
        atan_table[15] = 16'h0000;  // atan(1/32768) ≈ 0.002° = 0
    end

    // FSM state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // FSM next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = COMPUTE;
            end
            COMPUTE: begin
                if (iteration == 15) next_state = FINISH;
            end
            FINISH: begin
                next_state = IDLE;
            end
        endcase
    end

    // FSM output logic and CORDIC computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            x <= 0;
            y <= 0;
            z <= 0;
            iteration <= 0;
            cosine <= 0;
            sine <= 0;
            done <= 0;
            ready <= 1;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    if (start) begin
                        ready <= 0;
                        // Save original angle for quadrant correction
                        angle_reg <= angle;
                        
                        // Initialize CORDIC with angle reduction
                        // CORDIC converges for angles in [-π/2, π/2]
                        // Our angle is 0-65535 for 0-2π
                        // We need to map to [-π/2, π/2] = [0, 16384] for positive
                        reg [15:0] reduced_angle;
                        
                        if (angle < 16384) begin
                            // 0-90°: use directly
                            reduced_angle = angle;
                            x <= K;
                            y <= 0;
                        end else if (angle < 32768) begin
                            // 90-180°: angle - π/2, swap cos/sin
                            reduced_angle = angle - 16'd16384;
                            x <= 0;
                            y <= K;
                        end else if (angle < 49152) begin
                            // 180-270°: angle - π, negate both
                            reduced_angle = angle - 16'd32768;
                            x <= -K;
                            y <= 0;
                        end else begin
                            // 270-360°: angle - 3π/2, swap and negate
                            reduced_angle = angle - 16'd49152;
                            x <= 0;
                            y <= -K;
                        end
                        
                        z <= reduced_angle;
                        iteration <= 0;
                    end
                end
                COMPUTE: begin
                    // CORDIC iteration
                    if (z[15]) begin  // Negative angle (MSB indicates sign)
                        // Rotate positive
                        x <= x + (y >>> iteration);
                        y <= y - (x >>> iteration);
                        z <= z + atan_table[iteration];
                    end else begin    // Positive angle
                        // Rotate negative
                        x <= x - (y >>> iteration);
                        y <= y + (x >>> iteration);
                        z <= z - atan_table[iteration];
                    end
                    iteration <= iteration + 1;
                end
                FINISH: begin
                    // Output results with quadrant correction
                    // x and y are in range ~±39797 (K ≈ 0.607)
                    // Scale to ±65536 for ±1.0 in 16.16
                    // Scale factor: 65536/39797 ≈ 1.647
                    // Simple scaling: multiply by 1.647 ≈ 1 + 0.5 + 0.125 + 0.015625
                    reg [31:0] x_scaled, y_scaled;
                    reg [31:0] cos_result, sin_result;
                    
                    x_scaled = {x[15:0], 16'b0} +               // x * 65536
                               ({x[15:0], 16'b0} >> 1) +        // x * 32768
                               ({x[15:0], 16'b0} >> 3) +        // x * 8192
                               ({x[15:0], 16'b0} >> 6);         // x * 1024
                               
                    y_scaled = {y[15:0], 16'b0} +               // y * 65536
                               ({y[15:0], 16'b0} >> 1) +        // y * 32768
                               ({y[15:0], 16'b0} >> 3) +        // y * 8192
                               ({y[15:0], 16'b0} >> 6);         // y * 1024
                    
                    // Quadrant correction based on original angle
                    if (angle_reg < 16384) begin
                        // 0-90°: cos = x, sin = y
                        cos_result = x_scaled;
                        sin_result = y_scaled;
                    end else if (angle_reg < 32768) begin
                        // 90-180°: cos = -y, sin = x
                        cos_result = -y_scaled;
                        sin_result = x_scaled;
                    end else if (angle_reg < 49152) begin
                        // 180-270°: cos = -x, sin = -y
                        cos_result = -x_scaled;
                        sin_result = -y_scaled;
                    end else begin
                        // 270-360°: cos = y, sin = -x
                        cos_result = y_scaled;
                        sin_result = -x_scaled;
                    end
                    
                    cosine <= cos_result;
                    sine <= sin_result;
                    done <= 1;
                end
            endcase
        end
    end

endmodule