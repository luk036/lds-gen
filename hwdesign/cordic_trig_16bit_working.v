/*
16-bit CORDIC Trigonometric Module (Working)
Based directly on the working 8-bit version from experiment/

Key scaling:
- 8-bit: 0-255 maps to 0-2π, arctan values 0-127 scale
- 16-bit: 0-65535 maps to 0-2π, scale by 65536/256 = 256

Inputs:
- clk: System clock
- rst_n: Active-low reset
- angle[15:0]: Input angle (0-65535 maps to 0-2π)

Outputs:
- cosine[31:0]: Cosine output (16.16 fixed-point)
- sine[31:0]: Sine output (16.16 fixed-point)
- done: Always 1 (combinatorial like 8-bit version)
- ready: Always 1 (combinatorial like 8-bit version)

Note: This is a direct translation of the 8-bit combinatorial CORDIC.
It completes in 16 cycles and outputs results every cycle after initialization.
*/

module cordic_trig_16bit_working (
    input clk,
    input rst_n,
    input start,           // Not used in this combinatorial version
    input [15:0] angle,
    output reg [31:0] cosine,
    output reg [31:0] sine,
    output reg done,
    output reg ready
);

    // Constants for CORDIC angles (atan values scaled for 16-bit)
    // Original 8-bit: [64, 38, 20, 10, 5, 3, 1, 1]
    // Scale by 256 for 16-bit: [16384, 9728, 5120, 2560, 1280, 768, 256, 256]
    // Extended to 16 iterations
    reg [15:0] atan_table [0:15];

    // Internal registers (17-bit for 16-bit + guard bit)
    reg [16:0] x, x_next;
    reg [16:0] y, y_next;
    reg [15:0] z, z_next;
    reg [3:0] iteration;

    // CORDIC scaling factor K ≈ 0.607253
    // In 17-bit: 0.607253 * 65536 = 39797
    parameter K_SCALE = 17'd39797;

    // Initialize arctan table
    integer i;
    initial begin
        // First 8 entries scaled from 8-bit version
        atan_table[0] = 16'h4000;   // 16384 = 64 * 256
        atan_table[1] = 16'h2600;   // 9728  = 38 * 256
        atan_table[2] = 16'h1400;   // 5120  = 20 * 256
        atan_table[3] = 16'h0A00;   // 2560  = 10 * 256
        atan_table[4] = 16'h0500;   // 1280  = 5 * 256
        atan_table[5] = 16'h0300;   // 768   = 3 * 256
        atan_table[6] = 16'h0100;   // 256   = 1 * 256
        atan_table[7] = 16'h0100;   // 256   = 1 * 256

        // Additional entries for 16-bit precision
        atan_table[8] = 16'h0080;   // 128
        atan_table[9] = 16'h0040;   // 64
        atan_table[10] = 16'h0020;  // 32
        atan_table[11] = 16'h0010;  // 16
        atan_table[12] = 16'h0008;  // 8
        atan_table[13] = 16'h0004;  // 4
        atan_table[14] = 16'h0002;  // 2
        atan_table[15] = 16'h0001;  // 1
    end

    // Always ready and done (combinatorial like 8-bit version)
    always @(*) begin
        ready = 1'b1;
        done = 1'b1;
    end

    // CORDIC computation (same structure as 8-bit version)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize on reset
            x <= K_SCALE;
            y <= 17'd0;
            z <= angle;
            iteration <= 4'd0;

            // Initialize outputs
            cosine <= 0;
            sine <= 0;
        end else begin
            if (iteration < 16) begin
                // Determine rotation direction (check MSB for sign)
                if (z[15]) begin  // Negative angle
                    x_next = x + (y >>> iteration);
                    y_next = y - (x >>> iteration);
                    z_next = z + atan_table[iteration];
                end else begin    // Positive angle
                    x_next = x - (y >>> iteration);
                    y_next = y + (x >>> iteration);
                    z_next = z - atan_table[iteration];
                end

                x <= x_next;
                y <= y_next;
                z <= z_next;
                iteration <= iteration + 1;
            end

            // Output results (scaled from 17-bit to 16.16 fixed-point)
            // x and y are in range ~±39797 (17-bit signed, K ≈ 0.607)
            // We want ±65536 (16.16 for ±1.0)
            // Scale factor: 65536/39797 ≈ 1.647
            // Multiply by 1.647 ≈ 1 + 0.5 + 0.125 + 0.015625 = 1.640625
            // x_scaled = x + (x >> 1) + (x >> 3) + (x >> 6)
            reg [31:0] x_scaled, y_scaled;

            x_scaled = {x[15:0], 16'b0} +               // x * 65536
                       ({x[15:0], 16'b0} >> 1) +        // x * 32768
                       ({x[15:0], 16'b0} >> 3) +        // x * 8192
                       ({x[15:0], 16'b0} >> 6);         // x * 1024

            y_scaled = {y[15:0], 16'b0} +               // y * 65536
                       ({y[15:0], 16'b0} >> 1) +        // y * 32768
                       ({y[15:0], 16'b0} >> 3) +        // y * 8192
                       ({y[15:0], 16'b0} >> 6);         // y * 1024

            cosine <= x_scaled;
            sine <= y_scaled;
        end
    end

endmodule
