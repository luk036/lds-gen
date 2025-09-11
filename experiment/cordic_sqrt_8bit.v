module cordic_sqrt(
    input wire clk,
    input wire rst,
    input wire [7:0] value,  // Input value to compute sqrt
    output reg [7:0] sqrt
);

    // Internal registers
    reg [15:0] x, x_next;
    reg [15:0] y, y_next;
    reg [7:0] z, z_next;
    reg [7:0] iteration;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 16'd0;
            y <= {8'b0, value};
            z <= 8'd128;  // Start with half of the max value
            iteration <= 8'd0;
        end else if (iteration < 8) begin
            x_next = x + (y >>> iteration);
            y_next = y - (x >>> iteration);
            z_next = z - (1 << (7 - iteration));
            iteration <= iteration + 1;
            x <= x_next;
            y <= y_next;
            z <= z_next;
        end
        sqrt <= x[15:8];
    end
endmodule
