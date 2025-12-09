/*
Halton Sequence Generator (32-bit) - Fixed Version

This SystemVerilog module implements a Halton sequence generator for bases [2, 3]
with scales [11, 7]. The Halton sequence is a 2-dimensional low-discrepancy sequence
that provides well-distributed points in the unit square [0,1] x [0,1].

The algorithm works by combining two Van der Corput sequences with different bases:
- Base 2 with scale 11 for the first dimension
- Base 3 with scale 7 for the second dimension

This implementation generates 32-bit integer outputs scaled by base^scale for each dimension.
The Halton sequence is widely used in quasi-Monte Carlo methods for numerical integration,
optimization, and sampling.

Features:
- 2-dimensional Halton sequence (bases 2 and 3)
- 32-bit integer arithmetic
- Configurable scales (11 for base 2, 7 for base 3)
- Synchronous design with clock and reset
- Pop/reseed interface matching Python API
- Valid output flag for timing control
*/

module halton_32bit_fixed #(
    parameter SCALE_0 = 11,    // Scale for base 2
    parameter SCALE_1 = 7      // Scale for base 3
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] halton_out_0,  // Halton output dimension 0 (base 2)
    output reg  [31:0] halton_out_1,  // Halton output dimension 1 (base 3)
    output reg         valid          // Output valid flag
);

    // Internal counter (shared by both dimensions)
    reg [31:0] count;

    // Pre-computed factor values
    localparam FACTOR_0 = 32'd2048;  // 2^11
    localparam FACTOR_1 = 32'd2187;  // 3^7

    // Van der Corput calculation for base 2
    function [31:0] calculate_vdc_base2;
        input [31:0] k;
        reg [31:0] k_temp;
        reg [31:0] vdc_val;
        reg [31:0] factor_temp;
        reg [31:0] remainder;
        begin
            k_temp = k;
            vdc_val = 32'd0;
            factor_temp = FACTOR_0;

            // Unroll for synthesis (limited iterations for scale 11)
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 2;
                remainder = k_temp % 2;
                k_temp = k_temp / 2;
                vdc_val = vdc_val + (remainder * factor_temp);
            end

            calculate_vdc_base2 = vdc_val;
        end
    endfunction

    // Van der Corput calculation for base 3
    function [31:0] calculate_vdc_base3;
        input [31:0] k;
        reg [31:0] k_temp;
        reg [31:0] vdc_val;
        reg [31:0] factor_temp;
        reg [31:0] remainder;
        begin
            k_temp = k;
            vdc_val = 32'd0;
            factor_temp = FACTOR_1;

            // Unroll for synthesis (limited iterations for scale 7)
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end
            if (k_temp != 0) begin
                factor_temp = factor_temp / 3;
                remainder = k_temp % 3;
                k_temp = k_temp / 3;
                vdc_val = vdc_val + (remainder * factor_temp);
            end

            calculate_vdc_base3 = vdc_val;
        end
    endfunction

    // Main sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            halton_out_0 <= 32'd0;
            halton_out_1 <= 32'd0;
            valid <= 1'b0;
        end else begin
            // Handle reseed operation
            if (reseed_enable) begin
                count <= seed;
                halton_out_0 <= 32'd0;
                halton_out_1 <= 32'd0;
                valid <= 1'b0;
            end
            // Handle pop operation
            else if (pop_enable) begin
                count <= count + 1'b1;
                halton_out_0 <= calculate_vdc_base2(count + 1'b1);
                halton_out_1 <= calculate_vdc_base3(count + 1'b1);
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule