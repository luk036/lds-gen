/*
Halton Sequence Generator (32-bit) - Direct Implementation

This SystemVerilog module implements a Halton sequence generator for bases [2, 3]
with scales [11, 7]. This is a direct implementation that doesn't rely on separate
VdCorput modules, ensuring proper synchronization between dimensions.
*/

module halton_32bit_direct #(
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

    // Internal registers
    reg [31:0] count;
    reg [31:0] factor_0, factor_1;

    // Calculate scale factors
    function automatic [31:0] calc_pow;
        input [31:0] base_val;
        input [31:0] exp_val;
        reg [31:0] result;
        reg [31:0] i;
        begin
            result = 32'd1;
            for (i = 0; i < exp_val; i = i + 1) begin
                result = result * base_val;
            end
            calc_pow = result;
        end
    endfunction

    // Van der Corput calculation function
    function automatic [31:0] calculate_vdc;
        input [31:0] k;
        input [31:0] base;
        input [31:0] scale_factor;
        reg [31:0] k_temp;
        reg [31:0] vdc_val;
        reg [31:0] factor_temp;
        reg [31:0] remainder;
        begin
            k_temp = k;
            vdc_val = 32'd0;
            factor_temp = scale_factor;

            while (k_temp != 32'd0) begin
                factor_temp = factor_temp / base;
                remainder = k_temp % base;
                k_temp = k_temp / base;
                vdc_val = vdc_val + (remainder * factor_temp);
            end

            calculate_vdc = vdc_val;
        end
    endfunction

    // Main sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            halton_out_0 <= 32'd0;
            halton_out_1 <= 32'd0;
            valid <= 1'b0;
            factor_0 <= 32'd0;
            factor_1 <= 32'd0;
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
                // Calculate scale factors on first use
                if (factor_0 == 32'd0) begin
                    factor_0 <= calc_pow(32'd2, SCALE_0[31:0]);
                    factor_1 <= calc_pow(32'd3, SCALE_1[31:0]);
                end
                halton_out_0 <= calculate_vdc(count + 1'b1, 32'd2, factor_0);
                halton_out_1 <= calculate_vdc(count + 1'b1, 32'd3, factor_1);
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule