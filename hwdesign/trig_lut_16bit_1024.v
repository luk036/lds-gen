/*
16-bit Trigonometric Lookup Table (LUT) - 1024 entries
Improved resolution alternative to CORDIC

Uses pre-computed cosine and sine values for 1024 angles
(0 to 1023 maps to 0 to 2π)
*/

module trig_lut_16bit_1024 (
    input clk,
    input rst_n,
    input start,
    input [15:0] angle,     // 0-65535 maps to 0-2π
    output reg [31:0] cosine,  // 16.16 fixed-point
    output reg [31:0] sine,    // 16.16 fixed-point
    output reg done,
    output reg ready
);

    // Use upper 10 bits of 16-bit angle to index 1024-entry LUT
    wire [9:0] angle_index = angle[15:6];

    // Pre-computed cosine LUT (1024 entries, 16.16 fixed-point)
    reg [31:0] cos_lut [0:1023];

    // Pre-computed sine LUT (1024 entries, 16.16 fixed-point)
    reg [31:0] sin_lut [0:1023];

    // Initialize LUTs with cosine and sine values
    integer i;
    real angle_rad, cos_val, sin_val;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            // Convert index to angle in radians (0 to 2π)
            angle_rad = 2.0 * 3.141592653589793 * i / 1024.0;

            // Compute cosine and sine
            cos_val = $cos(angle_rad);
            sin_val = $sin(angle_rad);

            // Convert to 16.16 fixed-point
            cos_lut[i] = $rtoi(cos_val * 65536.0);
            sin_lut[i] = $rtoi(sin_val * 65536.0);
        end
    end

    // Simple combinatorial lookup
    always @(*) begin
        if (!rst_n) begin
            cosine = 0;
            sine = 0;
            done = 0;
            ready = 0;
        end else begin
            cosine = cos_lut[angle_index];
            sine = sin_lut[angle_index];
            done = 1'b1;
            ready = 1'b1;
        end
    end

endmodule