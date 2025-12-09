/*
16-bit CORDIC Trigonometric Module
Computes sine and cosine of input angle

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start computation
- angle[15:0]: Input angle (0-65535 maps to 0-2π)

Outputs:
- cosine[31:0]: Cosine output (16.16 fixed-point, range -1 to 1)
- sine[31:0]: Sine output (16.16 fixed-point, range -1 to 1)
- done: Computation complete
- ready: Module ready for new input

CORDIC Algorithm:
- Vector rotation mode
- 16 iterations for 16-bit precision
- Pre-computed arctan table
- Gain compensation (K ≈ 0.607)
*/

module cordic_trig_16bit (
    input clk,
    input rst_n,
    input start,
    input [15:0] angle,
    output reg [31:0] cosine,
    output reg [31:0] sine,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 2'b00;
    parameter COMPUTE = 2'b01;
    parameter FINISH = 2'b10;

    reg [1:0] current_state, next_state;

    // CORDIC constants (arctan values in 16-bit fixed-point)
    // atan(2^-i) for i = 0 to 15
    reg [15:0] atan_table [0:15];

    // Internal registers
    reg [31:0] x_reg, y_reg;      // 16.16 fixed-point
    reg [15:0] z_reg;             // Angle remainder
    reg [3:0] iteration;
    reg compute_start;

    // CORDIC scaling factor K ≈ 0.607253
    // In 16.16 fixed-point: 0.607253 * 65536 = 39797
    parameter K_SCALE = 32'h00009B75;  // 39797 in hex

    // Initialize arctan table
    integer i;
    initial begin
        // atan(1) = π/4 ≈ 0.785398 rad
        // In 16-bit (0-65535 maps to 0-2π): 0.785398/(2π) * 65536 = 8192
        atan_table[0] = 16'h2000;   // 8192

        // atan(1/2) ≈ 0.463648 rad = 0.463648/(2π) * 65536 = 4836
        atan_table[1] = 16'h12E4;   // 4836

        // atan(1/4) ≈ 0.244979 rad = 0.244979/(2π) * 65536 = 2554
        atan_table[2] = 16'h09FA;   // 2554

        // atan(1/8) ≈ 0.124355 rad = 0.124355/(2π) * 65536 = 1296
        atan_table[3] = 16'h0510;   // 1296

        // atan(1/16) ≈ 0.062419 rad = 0.062419/(2π) * 65536 = 650
        atan_table[4] = 16'h028A;   // 650

        // atan(1/32) ≈ 0.031240 rad = 0.031240/(2π) * 65536 = 325
        atan_table[5] = 16'h0145;   // 325

        // atan(1/64) ≈ 0.015624 rad = 0.015624/(2π) * 65536 = 163
        atan_table[6] = 16'h00A3;   // 163

        // atan(1/128) ≈ 0.007812 rad = 0.007812/(2π) * 65536 = 81
        atan_table[7] = 16'h0051;   // 81

        // Remaining entries for 16 iterations
        atan_table[8] = 16'h0029;   // 41
        atan_table[9] = 16'h0014;   // 20
        atan_table[10] = 16'h000A;  // 10
        atan_table[11] = 16'h0005;  // 5
        atan_table[12] = 16'h0003;  // 3
        atan_table[13] = 16'h0001;  // 1
        atan_table[14] = 16'h0001;  // 1
        atan_table[15] = 16'h0000;  // 0
    end

    // FSM state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start) next_state = COMPUTE;
            end
            COMPUTE: begin
                if (iteration == 15) next_state = FINISH;
            end
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and CORDIC computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_reg <= K_SCALE;      // Initialize with scaling factor
            y_reg <= 0;
            z_reg <= 0;
            iteration <= 0;
            cosine <= 0;
            sine <= 0;
            done <= 0;
            ready <= 1;
            compute_start <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    if (start) begin
                        ready <= 0;
                        // Initialize CORDIC registers
                        x_reg <= K_SCALE;
                        y_reg <= 0;
                        z_reg <= angle;
                        iteration <= 0;
                        compute_start <= 1;
                    end
                end
                COMPUTE: begin
                    compute_start <= 0;

                    // CORDIC iteration
                    if (z_reg[15]) begin  // Negative angle (MSB indicates sign)
                        // Rotate clockwise
                        x_reg <= x_reg + (y_reg >>> iteration);
                        y_reg <= y_reg - (x_reg >>> iteration);
                        z_reg <= z_reg + atan_table[iteration];
                    end else begin        // Positive angle
                        // Rotate counter-clockwise
                        x_reg <= x_reg - (y_reg >>> iteration);
                        y_reg <= y_reg + (x_reg >>> iteration);
                        z_reg <= z_reg - atan_table[iteration];
                    end

                    iteration <= iteration + 1;
                end
                FINISH: begin
                    // Output results (already scaled by K)
                    cosine <= x_reg;
                    sine <= y_reg;
                    done <= 1;
                end
            endcase
        end
    end

endmodule