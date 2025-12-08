/*
VdCorput FSM-Based Sequential Implementation (32-bit)
Supports bases 2, 3, and 7

This module implements the Van der Corput sequence generator using a Finite State Machine (FSM) approach.
The algorithm converts an integer k to a floating point value by repeatedly dividing by base and
accumulating remainders divided by decreasing powers of the base.

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer k (32-bit)
- base_sel[1:0]: Base selection (00: base 2, 01: base 3, 10: base 7)

Outputs:
- result[31:0]: 32-bit fixed-point result (16.16 format)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- INIT: Initialize registers
- DIVIDE: Perform division by base
- ACCUMULATE: Accumulate remainder * power_of_base
- UPDATE: Update k and power_of_base
- CHECK: Check if k == 0
- FINISH: Output result

The module uses 32-bit fixed-point arithmetic with 16 integer bits and 16 fractional bits.
*/

module vdcorput_fsm_32bit (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [31:0] k_in,
    input wire [1:0] base_sel,
    output reg [31:0] result,
    output reg done,
    output reg ready
);

    // FSM states
    typedef enum logic [2:0] {
        IDLE,
        INIT,
        DIVIDE,
        ACCUMULATE,
        UPDATE,
        CHECK,
        FINISH
    } state_t;

    state_t current_state, next_state;

    // Internal registers
    reg [31:0] k_reg;          // Current k value
    reg [31:0] power_reg;      // Current power of base (1/base^i in fixed-point)
    reg [31:0] acc_reg;        // Accumulator for result
    reg [31:0] base_reg;       // Current base value
    reg [31:0] remainder_reg;  // Remainder from division
    reg [31:0] quotient_reg;   // Quotient from division

    // Fixed-point constants (16.16 format)
    localparam [31:0] FP_ONE = 32'h00010000;  // 1.0 in fixed-point
    localparam [31:0] FP_HALF = 32'h00008000; // 0.5 in fixed-point
    localparam [31:0] FP_THIRD = 32'h00005555; // 1/3 ≈ 0.3333 in fixed-point
    localparam [31:0] FP_SEVENTH = 32'h00002492; // 1/7 ≈ 0.142857 in fixed-point

    // Division modules for bases 3 and 7
    wire [31:0] div3_quotient, div7_quotient;
    wire [1:0] div3_remainder;
    wire [2:0] div7_remainder;

    // Instantiate division modules
    div_mod_3 div3_inst (
        .n(k_reg[7:0]),  // Use lower 8 bits for division by 3
        .quotient(div3_quotient[7:0]),
        .remainder(div3_remainder)
    );

    div_mod_7 div7_inst (
        .n(k_reg[8:0]),  // Use lower 9 bits for division by 7
        .quotient(div7_quotient[8:0]),
        .remainder(div7_remainder)
    );

    // FSM state transition
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM next state logic
    always_comb begin
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
    always_ff @(posedge clk or negedge rst_n) begin
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
                            quotient_reg <= {24'b0, div3_quotient[7:0]};
                            remainder_reg <= {30'b0, div3_remainder};
                        end
                        7: begin  // Base 7 - use division module
                            quotient_reg <= {23'b0, div7_quotient[8:0]};
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
                        3: power_reg <= (power_reg * 32'h00005555) >> 16;  // Multiply by 1/3
                        7: power_reg <= (power_reg * 32'h00002492) >> 16;  // Multiply by 1/7
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