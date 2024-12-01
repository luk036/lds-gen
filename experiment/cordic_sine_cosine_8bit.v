module cordic_sine_cosine(
    input wire clk,
    input wire rst,
    input wire [7:0] angle,  // Input angle in degrees (0 to 255)
    output reg [7:0] sine,
    output reg [7:0] cosine
);

    // Parameters
    parameter ITERATIONS = 8;
    parameter K = 8'b01001011; // Scaling factor for 8-bit approximation

    // Internal registers
    reg signed [15:0] x, y, z;
    reg signed [15:0] x_next, y_next, z_next;
    reg [7:0] angle_table [0:7];

    integer i;

    initial begin
        angle_table[0] = 8'd45;
        angle_table[1] = 8'd26;
        angle_table[2] = 8'd14;
        angle_table[3] = 8'd7;
        angle_table[4] = 8'd4;
        angle_table[5] = 8'd2;
        angle_table[6] = 8'd1;
        angle_table[7] = 8'd0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= K;
            y <= 0;
            z <= angle;
        end else begin
            x_next = x;
            y_next = y;
            z_next = z;
            for (i = 0; i < ITERATIONS; i = i + 1) begin
                if (z_next[15] == 0) begin
                    x_next = x_next - (y_next >>> i);
                    y_next = y_next + (x_next >>> i);
                    z_next = z_next - angle_table[i];
                end else begin
                    x_next = x_next + (y_next >>> i);
                    y_next = y_next - (x_next >>> i);
                    z_next = z_next + angle_table[i];
                end
            end
            sine <= y_next[15:8];
            cosine <= x_next[15:8];
        end
    end
endmodule
