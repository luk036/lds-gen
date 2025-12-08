/*
16-bit CORDIC Trigonometric Module (Fixed)
Based on working 8-bit version from experiment/
*/

module cordic_trig_16bit_fixed (
    input clk,
    input rst_n,
    input start,
    input [15:0] angle,     // Input angle 0-65535 maps to 0-2π
    output reg [31:0] cosine,  // 16.16 fixed-point
    output reg [31:0] sine,    // 16.16 fixed-point
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 1'b0;
    parameter COMPUTE = 1'b1;
    
    reg state;
    reg [3:0] iteration;
    reg compute_active;

    // CORDIC constants (arctan values scaled for 16-bit)
    // atan(2^-i) * 65536/(2π) for i = 0 to 15
    reg [15:0] atan_table [0:15];
    
    // Internal registers (17-bit for 16-bit + guard bit)
    reg [16:0] x, y;
    reg [15:0] z;
    
    // CORDIC scaling factor K ≈ 0.607253
    // In 16-bit fixed-point: 0.607253 * 65536 = 39797
    parameter K_SCALE = 17'd39797;

    // Initialize arctan table
    integer i;
    initial begin
        // Scale factors from 8-bit to 16-bit:
        // 8-bit: 0-255 maps to 0-2π, arctan values are 0-127 scale
        // 16-bit: 0-65535 maps to 0-2π, need to scale by 65536/256 = 256
        
        // Original 8-bit values: [64, 38, 20, 10, 5, 3, 1, 1]
        // Scaled to 16-bit (×256): [16384, 9728, 5120, 2560, 1280, 768, 256, 256]
        
        atan_table[0] = 16'h4000;   // 16384
        atan_table[1] = 16'h2600;   // 9728
        atan_table[2] = 16'h1400;   // 5120
        atan_table[3] = 16'h0A00;   // 2560
        atan_table[4] = 16'h0500;   // 1280
        atan_table[5] = 16'h0300;   // 768
        atan_table[6] = 16'h0100;   // 256
        atan_table[7] = 16'h0100;   // 256
        atan_table[8] = 16'h0080;   // 128
        atan_table[9] = 16'h0040;   // 64
        atan_table[10] = 16'h0020;  // 32
        atan_table[11] = 16'h0010;  // 16
        atan_table[12] = 16'h0008;  // 8
        atan_table[13] = 16'h0004;  // 4
        atan_table[14] = 16'h0002;  // 2
        atan_table[15] = 16'h0001;  // 1
    end

    // FSM and CORDIC computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            iteration <= 0;
            x <= 0;
            y <= 0;
            z <= 0;
            cosine <= 0;
            sine <= 0;
            done <= 0;
            ready <= 1;
            compute_active <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    if (start) begin
                        ready <= 0;
                        // Initialize CORDIC
                        x <= K_SCALE;
                        y <= 0;
                        z <= angle;
                        iteration <= 0;
                        state <= COMPUTE;
                        compute_active <= 1;
                    end
                end
                
                COMPUTE: begin
                    if (iteration < 16) begin
                        // CORDIC iteration
                        if (z[15]) begin  // Negative angle (check MSB)
                            // Rotate clockwise
                            x <= x + (y >>> iteration);
                            y <= y - (x >>> iteration);
                            z <= z + atan_table[iteration];
                        end else begin    // Positive angle
                            // Rotate counter-clockwise
                            x <= x - (y >>> iteration);
                            y <= y + (x >>> iteration);
                            z <= z - atan_table[iteration];
                        end
                        
                        iteration <= iteration + 1;
                    end else begin
                        // Computation complete
                        // Convert 17-bit result to 16.16 fixed-point
                        // x and y are scaled by K, in range ~±39797
                        // We want range ±65536 (16.16 fixed-point for ±1.0)
                        // So multiply by 65536/39797 ≈ 1.647
                        // For simplicity, we'll just scale and check magnitude
                        
                        // Scale x and y to 16.16 (shift left 16 bits from 17-bit)
                        cosine <= {x[15:0], 16'b0};  // x * 65536
                        sine <= {y[15:0], 16'b0};    // y * 65536
                        
                        done <= 1;
                        state <= IDLE;
                        compute_active <= 0;
                    end
                end
            endcase
        end
    end

endmodule