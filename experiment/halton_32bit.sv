/*
Halton Sequence Generator (32-bit)

This SystemVerilog module implements a Halton sequence generator for bases [2, 3]
with scales [11, 7]. The Halton sequence is a 2-dimensional low-discrepancy sequence
that provides well-distributed points in the unit square [0,1] x [0,1].

The algorithm works by combining two Van der Corput sequences with different bases:
- Base 2 with scale 11 for the first dimension
- Base 3 with scale 7 for the second dimension

This implementation generates 32-bit integer outputs scaled by base^scale for each dimension.
The Halton sequence is widely used in quasi-Monte Carlo methods for numerical integration,
optimization, and sampling.

Features:
- 2-dimensional Halton sequence (bases 2 and 3)
- 32-bit integer arithmetic
- Configurable scales (11 for base 2, 7 for base 3)
- Synchronous design with clock and reset
- Pop/reseed interface matching Python API
- Valid output flag for timing control
*/

module halton_32bit #(
    parameter SCALE_0 = 11,    // Scale for base 2
    parameter SCALE_1 = 7      // Scale for base 3
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] halton_out_0,  // Halton output dimension 0 (base 2)
    output reg  [31:0] halton_out_1,  // Halton output dimension 1 (base 3)
    output reg         valid          // Output valid flag
);

    // Internal signals for Van der Corput generators
    wire [31:0] vdc_out_0, vdc_out_1;
    wire        vdc_valid_0, vdc_valid_1;
    reg         pop_enable_reg;
    reg  [31:0] seed_reg;
    reg         reseed_enable_reg;

    // Control signals
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam POP_0 = 2'b01;
    localparam POP_1 = 2'b10;
    localparam OUTPUT = 2'b11;

    // Control signals for each VDC generator
    wire vdc0_pop_enable = pop_enable_reg && (state == POP_0);
    wire vdc1_pop_enable = pop_enable_reg && (state == POP_1);

    // Instantiate Van der Corput generator for base 2
    vdcorput_32bit #(
        .BASE(2),
        .SCALE(SCALE_0)
    ) vdc_gen_0 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(vdc0_pop_enable),
        .seed(seed_reg),
        .reseed_enable(reseed_enable_reg),
        .vdc_out(vdc_out_0),
        .valid(vdc_valid_0)
    );

    // Instantiate Van der Corput generator for base 3
    vdcorput_32bit #(
        .BASE(3),
        .SCALE(SCALE_1)
    ) vdc_gen_1 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(vdc1_pop_enable),
        .seed(seed_reg),
        .reseed_enable(reseed_enable_reg),
        .vdc_out(vdc_out_1),
        .valid(vdc_valid_1)
    );

    // State machine for coordinating the two VDC generators
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            halton_out_0 <= 32'd0;
            halton_out_1 <= 32'd0;
            valid <= 1'b0;
            pop_enable_reg <= 1'b0;
            seed_reg <= 32'd0;
            reseed_enable_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    pop_enable_reg <= 1'b0;
                    reseed_enable_reg <= 1'b0;

                    if (reseed_enable) begin
                        seed_reg <= seed;
                        reseed_enable_reg <= 1'b1;
                        state <= POP_0;
                    end else if (pop_enable) begin
                        pop_enable_reg <= 1'b1;
                        reseed_enable_reg <= 1'b0;
                        state <= POP_0;
                    end
                end

                POP_0: begin
                    pop_enable_reg <= 1'b0;
                    reseed_enable_reg <= 1'b0;
                    if (vdc_valid_0) begin
                        halton_out_0 <= vdc_out_0;
                        state <= POP_1;
                    end
                end

                POP_1: begin
                    // Trigger second VDC generator
                    pop_enable_reg <= 1'b1;
                    if (vdc_valid_1) begin
                        halton_out_1 <= vdc_out_1;
                        state <= OUTPUT;
                    end
                end

                OUTPUT: begin
                    valid <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule