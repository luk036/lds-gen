/*
Halton FSM-Based Sequential Implementation (32-bit)
Uses two VdCorput instances for 2D sequence generation

The Halton sequence generates 2D points using two different bases.
This module instantiates two VdCorput FSM modules and coordinates
their operation to produce (x, y) coordinate pairs.

Inputs:
- clk: System clock
- rst_n: Active-low reset
- start: Start signal to begin computation
- k_in[31:0]: Input integer k (32-bit)
- base0_sel[1:0]: Base selection for first dimension (00: base 2, 01: base 3, 10: base 7)
- base1_sel[1:0]: Base selection for second dimension

Outputs:
- result_x[31:0]: X-coordinate (16.16 fixed-point)
- result_y[31:0]: Y-coordinate (16.16 fixed-point)
- done: Computation complete signal
- ready: Module ready to accept new input

FSM States:
- IDLE: Wait for start signal
- START_VDC0: Start first VdCorput computation
- WAIT_VDC0: Wait for first VdCorput to complete
- START_VDC1: Start second VdCorput computation
- WAIT_VDC1: Wait for second VdCorput to complete
- FINISH: Output results
*/

module halton_fsm_32bit_simple (
    input clk,
    input rst_n,
    input start,
    input [31:0] k_in,
    input [1:0] base0_sel,
    input [1:0] base1_sel,
    output reg [31:0] result_x,
    output reg [31:0] result_y,
    output reg done,
    output reg ready
);

    // FSM states
    parameter IDLE = 3'b000;
    parameter START_VDC0 = 3'b001;
    parameter WAIT_VDC0 = 3'b010;
    parameter START_VDC1 = 3'b011;
    parameter WAIT_VDC1 = 3'b100;
    parameter FINISH = 3'b101;

    reg [2:0] current_state, next_state;

    // VdCorput instance signals
    wire vdc0_ready, vdc0_done;
    wire vdc1_ready, vdc1_done;
    wire [31:0] vdc0_result, vdc1_result;
    
    reg vdc0_start, vdc1_start;
    reg [31:0] k_reg;

    // Instantiate first VdCorput (for x-coordinate)
    vdcorput_fsm_32bit_simple vdc0_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc0_start),
        .k_in(k_reg),
        .base_sel(base0_sel),
        .result(vdc0_result),
        .done(vdc0_done),
        .ready(vdc0_ready)
    );

    // Instantiate second VdCorput (for y-coordinate)
    vdcorput_fsm_32bit_simple vdc1_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc1_start),
        .k_in(k_reg),
        .base_sel(base1_sel),
        .result(vdc1_result),
        .done(vdc1_done),
        .ready(vdc1_ready)
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
                if (start) next_state = START_VDC0;
            end
            START_VDC0: next_state = WAIT_VDC0;
            WAIT_VDC0: begin
                if (vdc0_done) next_state = START_VDC1;
            end
            START_VDC1: next_state = WAIT_VDC1;
            WAIT_VDC1: begin
                if (vdc1_done) next_state = FINISH;
            end
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            k_reg <= 0;
            vdc0_start <= 0;
            vdc1_start <= 0;
            result_x <= 0;
            result_y <= 0;
            done <= 0;
            ready <= 1;
        end else begin
            case (current_state)
                IDLE: begin
                    ready <= 1;
                    done <= 0;
                    vdc0_start <= 0;
                    vdc1_start <= 0;
                    if (start) begin
                        ready <= 0;
                        k_reg <= k_in;
                    end
                end
                START_VDC0: begin
                    vdc0_start <= 1;
                end
                WAIT_VDC0: begin
                    vdc0_start <= 0;
                    // Wait for vdc0_done
                end
                START_VDC1: begin
                    vdc1_start <= 1;
                end
                WAIT_VDC1: begin
                    vdc1_start <= 0;
                    // Wait for vdc1_done
                end
                FINISH: begin
                    result_x <= vdc0_result;
                    result_y <= vdc1_result;
                    done <= 1;
                end
            endcase
        end
    end

endmodule