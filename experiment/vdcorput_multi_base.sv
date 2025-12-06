/*
Multi-Base Van der Corput Sequence Generator

This SystemVerilog module implements Van der Corput sequence generators for bases 2, 3, and 7
in a single module. It provides parallel outputs for all three bases, making it suitable
for applications requiring multiple low-discrepancy sequences simultaneously.

Features:
- Simultaneous generation for bases 2, 3, and 7
- 32-bit integer outputs
- Configurable scale parameter
- Synchronized outputs for all bases
- Efficient shared counter implementation
*/

module vdcorput_multi_base #(
    parameter SCALE = 16     // Scale factor (number of digits)
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] vdc_out_2,     // Base 2 Van der Corput output
    output reg  [31:0] vdc_out_3,     // Base 3 Van der Corput output
    output reg  [31:0] vdc_out_7,     // Base 7 Van der Corput output
    output reg         valid          // Output valid flag
);

    // Internal registers
    reg [31:0] count;
    
    // Pre-calculated scale factors for each base
    wire [31:0] factor_2, factor_3, factor_7;
    
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
    
    assign factor_2 = calc_pow(32'd2, SCALE[31:0]);
    assign factor_3 = calc_pow(32'd3, SCALE[31:0]);
    assign factor_7 = calc_pow(32'd7, SCALE[31:0]);
    
    // Main sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            vdc_out_2 <= 32'd0;
            vdc_out_3 <= 32'd0;
            vdc_out_7 <= 32'd0;
            valid <= 1'b0;
        end else begin
            // Handle reseed operation
            if (reseed_enable) begin
                count <= seed;
                vdc_out_2 <= 32'd0;
                vdc_out_3 <= 32'd0;
                vdc_out_7 <= 32'd0;
                valid <= 1'b0;
            end 
            // Handle pop operation
            else if (pop_enable) begin
                count <= count + 1'b1;
                vdc_out_2 <= calculate_vdc(count + 1'b1, 32'd2, factor_2);
                vdc_out_3 <= calculate_vdc(count + 1'b1, 32'd3, factor_3);
                vdc_out_7 <= calculate_vdc(count + 1'b1, 32'd7, factor_7);
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
    
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

endmodule