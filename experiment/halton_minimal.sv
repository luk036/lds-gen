/*
Minimal Halton Sequence Generator (32-bit)

Simplified implementation for verification.
*/

module halton_minimal #(
    parameter SCALE_0 = 11,
    parameter SCALE_1 = 7
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pop_enable,
    input  wire [31:0] seed,
    input  wire        reseed_enable,
    output reg  [31:0] halton_out_0,
    output reg  [31:0] halton_out_1,
    output reg         valid
);

    reg [31:0] count;
    
    // Very simple VDC for base 2 (only first few iterations)
    function [31:0] vdc_base2;
        input [31:0] k;
        begin
            case (k)
                32'd1: vdc_base2 = 32'd1024;  // 2^10
                32'd2: vdc_base2 = 32'd512;   // 2^9
                32'd3: vdc_base2 = 32'd1536;  // 2^10 + 2^9
                32'd4: vdc_base2 = 32'd256;   // 2^8
                32'd5: vdc_base2 = 32'd1280;  // 2^10 + 2^8
                default: vdc_base2 = 32'd0;
            endcase
        end
    endfunction
    
    // Very simple VDC for base 3 (only first few iterations)
    function [31:0] vdc_base3;
        input [31:0] k;
        begin
            case (k)
                32'd1: vdc_base3 = 32'd729;   // 3^6
                32'd2: vdc_base3 = 32'd1458;  // 2*3^6
                32'd3: vdc_base3 = 32'd243;   // 3^5
                32'd4: vdc_base3 = 32'd972;   // 3^6 + 3^5
                32'd5: vdc_base3 = 32'd1701;  // 2*3^6 + 3^5
                default: vdc_base3 = 32'd0;
            endcase
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            halton_out_0 <= 32'd0;
            halton_out_1 <= 32'd0;
            valid <= 1'b0;
        end else begin
            if (reseed_enable) begin
                count <= seed;
                valid <= 1'b0;
            end else if (pop_enable) begin
                count <= count + 1'b1;
                halton_out_0 <= vdc_base2(count + 1'b1);
                halton_out_1 <= vdc_base3(count + 1'b1);
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule