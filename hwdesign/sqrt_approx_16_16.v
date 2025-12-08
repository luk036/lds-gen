/*
Fixed-point square root approximation (16.16 format)
Input: x in [0, 1) in 16.16 fixed-point
Output: sqrt(x) in [0, 1) in 16.16 fixed-point

Uses Newton-Raphson method with 2 iterations
y_{n+1} = 0.5 * (y_n + x / y_n)
*/

module sqrt_approx_16_16 (
    input [31:0] x,      // Input in 16.16 format, 0 <= x < 1.0
    output reg [31:0] y  // sqrt(x) in 16.16 format
);

    // Internal signals for Newton-Raphson iterations
    reg [31:0] y0, y1, y2;
    reg [47:0] x_div_y0, x_div_y1;  // 48-bit for division result
    
    always @(*) begin
        // Initial guess: y0 = x + 0.5 (works well for x in [0, 1))
        // This gives y0 in [0.5, 1.5) which is close to sqrt(x)
        y0 = x + 32'h00008000;  // x + 0.5
        
        // First Newton-Raphson iteration
        // x_div_y0 = x / y0 = (x << 16) / y0
        if (y0 != 0) begin
            x_div_y0 = (x << 16) / y0;
            y1 = (y0 + x_div_y0[31:0]) >> 1;  // 0.5 * (y0 + x/y0)
        end else begin
            y1 = 0;
        end
        
        // Second Newton-Raphson iteration
        if (y1 != 0) begin
            x_div_y1 = (x << 16) / y1;
            y2 = (y1 + x_div_y1[31:0]) >> 1;  // 0.5 * (y1 + x/y1)
        end else begin
            y2 = 0;
        end
        
        // Output result
        y = y2;
    end

endmodule