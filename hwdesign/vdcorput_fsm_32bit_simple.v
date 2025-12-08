/*
VdCorput FSM-Based Sequential Implementation (32-bit) - Simple Verilog Version
Supports bases 2, 3, and 7

This module implements the Van der Corput sequence generator using a Finite State Machine (FSM) approach.
Simplified for iverilog compatibility.
*/

module vdcorput_fsm_32bit_simple (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base_sel,
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 3'b000;
    parameter INIT = 3'b001;
    parameter DIVIDE = 3'b010;
    parameter ACCUMULATE = 3'b011;
    parameter UPDATE = 3'b100;
    parameter CHECK = 3'b101;
    parameter FINISH = 3'b110;

    reg [2:0] current_state, next_state;

    // Internal registers
    reg [31:0] k_reg;          // Current k value
    reg [31:0] power_reg;      // Current power of base (1/base^i in fixed-point)
    reg [31:0] acc_reg;        // Accumulator for result
    reg [31:0] base_reg;       // Current base value
    reg [31:0] remainder_reg;  // Remainder from division
    reg [31:0] quotient_reg;   // Quotient from division

    // Fixed-point constants (16.16 format)
    parameter FP_ONE = 32'h00010000;  // 1.0 in fixed-point
    parameter FP_HALF = 32'h00008000; // 0.5 in fixed-point
    parameter FP_THIRD = 32'h00005555; // 1/3 ≈ 0.3333 in fixed-point
    parameter FP_SEVENTH = 32'h00002492; // 1/7 ≈ 0.142857 in fixed-point

    // Division modules for bases 3 and 7
    wire [7:0] div3_quotient;
    wire [8:0] div7_quotient;
    wire [1:0] div3_remainder;
    wire [2:0] div7_remainder;

    // Instantiate division modules
    div_mod_3 div3_inst (
        .n(k_reg[7:0]),  // Use lower 8 bits for division by 3
        .quotient(div3_quotient),
        .remainder(div3_remainder)
    );

    div_mod_7 div7_inst (
        .n(k_reg[8:0]),  // Use lower 9 bits for division by 7
        .quotient(div7_quotient),
        .remainder(div7_remainder)
    );

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
                if (start) next_state = INIT;
            end
            INIT: next_state = DIVIDE;
            DIVIDE: next_state = ACCUMULATE;
            ACCUMULATE: next_state = UPDATE;
            UPDATE: next_state = CHECK;
            CHECK: begin
                if (k_reg == 0) next_state = FINISH;
                else next_state = DIVIDE;
            end
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            power_reg <= FP_ONE;
            acc_reg <= 0;
            base_reg <= 2;
            remainder_reg <= 0;
            quotient_reg <= 0;
            result <= 0;
            done <= 0;
            ready <= 1;
        end else begin
            case (current_state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    if (start) begin
                        ready <= 0;
                        // Store input values
                        k_reg <= k_in;
                    end
                end
                INIT: begin
                    // Initialize registers based on base selection
                    case (base_sel)
                        2'b00: begin  // Base 2
                            base_reg <= 2;
                            power_reg <= FP_HALF;  // 1/2
                        end
                        2'b01: begin  // Base 3
                            base_reg <= 3;
                            power_reg <= FP_THIRD;  // 1/3
                        end
                        2'b10: begin  // Base 7
                            base_reg <= 7;
                            power_reg <= FP_SEVENTH;  // 1/7
                        end
                        default: begin  // Default to base 2
                            base_reg <= 2;
                            power_reg <= FP_HALF;
                        end
                    endcase
                    acc_reg <= 0;
                end
                DIVIDE: begin
                    // Perform division based on base
                    case (base_reg)
                        2: begin  // Base 2 - simple shift
                            quotient_reg <= k_reg >> 1;
                            remainder_reg <= k_reg[0];
                        end
                        3: begin  // Base 3 - use division module
                            quotient_reg <= {24'b0, div3_quotient};
                            remainder_reg <= {30'b0, div3_remainder};
                        end
                        7: begin  // Base 7 - use division module
                            quotient_reg <= {23'b0, div7_quotient};
                            remainder_reg <= {29'b0, div7_remainder};
                        end
                        default: begin  // Should not happen
                            quotient_reg <= 0;
                            remainder_reg <= 0;
                        end
                    endcase
                end
                ACCUMULATE: begin
                    // Accumulate remainder * power_of_base
                    if (remainder_reg != 0) begin
                        // Fixed-point multiplication: remainder * power_reg
                        // Since remainder is small (0-6), we can use simple multiplication
                        acc_reg <= acc_reg + (remainder_reg * power_reg);
                    end
                end
                UPDATE: begin
                    // Update k and power_of_base
                    k_reg <= quotient_reg;
                    // power_reg = power_reg / base_reg (fixed-point division)
                    case (base_reg)
                        2: power_reg <= power_reg >> 1;  // Divide by 2
                        3: power_reg <= (power_reg * FP_THIRD) >> 16;  // Multiply by 1/3
                        7: power_reg <= (power_reg * FP_SEVENTH) >> 16;  // Multiply by 1/7
                    endcase
                end
                CHECK: begin
                    // k_reg already updated in UPDATE state
                    // Nothing to do here, FSM handles transition
                end
                FINISH: begin
                    result <= acc_reg;
                    done <= 1;
                end
            endcase
        end
    end

endmodule