module cordic_trig(
    input wire clk,
    input wire rst,
    input wire [7:0] angle,     // Input angle in range 0-255 (0 to 2π)
    output reg [7:0] sine,      // Scaled sine output
    output reg [7:0] cosine     // Scaled cosine output
);

    // Constants for CORDIC angles (atan values)
    reg [7:0] atan_table [0:7];
    initial begin
        atan_table[0] = 8'd64;  // atan(1)    ≈ 45°
        atan_table[1] = 8'd38;  // atan(1/2)  ≈ 26.57°
        atan_table[2] = 8'd20;  // atan(1/4)  ≈ 14.04°
        atan_table[3] = 8'd10;  // atan(1/8)  ≈ 7.13°
        atan_table[4] = 8'd5;   // atan(1/16) ≈ 3.58°
        atan_table[5] = 8'd3;   // atan(1/32) ≈ 1.79°
        atan_table[6] = 8'd1;   // atan(1/64) ≈ 0.89°
        atan_table[7] = 8'd1;   // atan(1/128)≈ 0.45°
    end

    // Internal registers
    reg [8:0] x, x_next;
    reg [8:0] y, y_next;
    reg [7:0] z, z_next;
    reg [3:0] iteration;

    // CORDIC scaling factor compensation (K ≈ 0.607)
    parameter SCALE = 8'd78;    // 0.607 * 128

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= SCALE;         // Initialize with scaling factor
            y <= 9'd0;
            z <= angle;
            iteration <= 4'd0;
        end else if (iteration < 8) begin
            // Determine rotation direction
            if (z[7]) begin     // Negative angle
                x_next = x + (y >>> iteration);
                y_next = y - (x >>> iteration);
                z_next = z + atan_table[iteration];
            end else begin      // Positive angle
                x_next = x - (y >>> iteration);
                y_next = y + (x >>> iteration);
                z_next = z - atan_table[iteration];
            end

            x <= x_next;
            y <= y_next;
            z <= z_next;
            iteration <= iteration + 1;
        end

        // Output scaled results
        cosine <= x[8:1];      // Scale down and take upper bits
        sine <= y[8:1];        // Scale down and take upper bits
    end
endmodule
