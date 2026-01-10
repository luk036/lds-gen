/*
16-bit Trigonometric Lookup Table (LUT)
Simplified alternative to CORDIC for testing

Uses pre-computed cosine and sine values for 256 angles
(0 to 255 maps to 0 to 2π)
*/

module trig_lut_16bit (
    input clk,
    input rst_n,
    input start,
    input [15:0] angle,     // 0-65535 maps to 0-2π
    output reg [31:0] cosine,  // 16.16 fixed-point
    output reg [31:0] sine,    // 16.16 fixed-point
    output reg done,
    output reg ready
);

    // Use upper 8 bits of 16-bit angle to index 256-entry LUT
    wire [7:0] angle_index = angle[15:8];

    // Pre-computed cosine LUT (256 entries, 16.16 fixed-point)
    reg [31:0] cos_lut [0:255];

    // Pre-computed sine LUT (256 entries, 16.16 fixed-point)
    reg [31:0] sin_lut [0:255];

    // Initialize LUTs with cosine and sine values
    integer i;
    real angle_rad, cos_val, sin_val;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            // Convert index to angle in radians (0 to 2π)
            angle_rad = 2.0 * 3.141592653589793 * i / 256.0;

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
