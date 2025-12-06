/*
Disk Sequence Generator (32-bit)

This SystemVerilog module implements a Disk sequence generator for bases [2,3], [2,7], and [3,7].
The Disk sequence generates uniformly distributed points on the unit disk by combining:
1. A Van der Corput sequence for angle: theta = vdc0 * 2π
2. A Van der Corput sequence for radius: radius = sqrt(vdc1)
3. Converting to Cartesian coordinates: x = radius * cos(theta), y = radius * sin(theta)

The algorithm works by:
1. Generating two Van der Corput sequence values in [0,1)
2. Converting first to angle: theta = vdc0 * 2π
3. Converting second to radius: radius = sqrt(vdc1)
4. Computing coordinates: x = radius * cos(theta), y = radius * sin(theta)

This implementation generates 32-bit fixed-point outputs for both coordinates.
The Disk sequence is useful for applications requiring uniform sampling on circular
domains, such as antenna pattern testing, circular antenna arrays, and polar coordinate
sampling.

Features:
- Configurable base pairs ([2,3], [2,7], [3,7])
- 32-bit fixed-point arithmetic for cos/sin/sqrt outputs
- Synchronous design with clock and reset
- Pop/reseed interface matching Python API
- Valid output flag for timing control
- Built-in cosine, sine, and square root approximations
*/

module disk_32bit #(
    parameter BASE_0 = 2,          // Base for angle (2, 3, or 7)
    parameter BASE_1 = 3,          // Base for radius (2, 3, or 7)
    parameter SCALE = 16,          // Scale for Van der Corput precision
    parameter ANGLE_BITS = 16      // Bits for angle representation
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] disk_x,        // Disk x-coordinate output
    output reg  [31:0] disk_y,        // Disk y-coordinate output
    output reg         valid          // Output valid flag
);

    // Internal signals for Van der Corput generators
    wire [31:0] vdc_out_0, vdc_out_1;
    wire        vdc_valid_0, vdc_valid_1;
    
    // Angle and radius calculation
    reg [ANGLE_BITS-1:0] angle_reg;
    reg [31:0] vdc_value_0_reg, vdc_value_1_reg;
    reg [31:0] radius_reg;
    
    // Trigonometric and square root calculation signals
    reg [31:0] cos_val, sin_val;
    reg [4:0] calc_iter;
    reg        calc_active;
    
    // Constants for 2π scaling and fixed-point arithmetic
    localparam TWO_PI_SCALE = (1 << ANGLE_BITS);
    localparam FIXED_SCALE = 32'd2147483648;  // 2^31 for Q32 fixed point
    
    // Instantiate Van der Corput generators
    vdcorput_32bit #(
        .BASE(BASE_0),
        .SCALE(SCALE)
    ) vdc_gen_0 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out(vdc_out_0),
        .valid(vdc_valid_0)
    );
    
    vdcorput_32bit #(
        .BASE(BASE_1),
        .SCALE(SCALE)
    ) vdc_gen_1 (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out(vdc_out_1),
        .valid(vdc_valid_1)
    );
    
    // State machine
    reg [3:0] state;
    localparam IDLE = 4'b0000;
    localparam WAIT_VDC = 4'b0001;
    localparam ANGLE_CALC = 4'b0010;
    localparam RADIUS_CALC = 4'b0011;
    localparam TRIG_START = 4'b0100;
    localparam TRIG_CALC = 4'b0101;
    localparam OUTPUT = 4'b0110;
    
    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            disk_x <= 32'd0;
            disk_y <= 32'd0;
            valid <= 1'b0;
            angle_reg <= {ANGLE_BITS{1'b0}};
            vdc_value_0_reg <= 32'd0;
            vdc_value_1_reg <= 32'd0;
            radius_reg <= 32'd0;
            cos_val <= 32'd0;
            sin_val <= 32'd0;
            calc_iter <= 5'b0;
            calc_active <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    calc_active <= 1'b0;
                    
                    if (pop_enable) begin
                        state <= WAIT_VDC;
                    end
                end
                
                WAIT_VDC: begin
                    if (vdc_valid_0 && vdc_valid_1) begin
                        vdc_value_0_reg <= vdc_out_0;
                        vdc_value_1_reg <= vdc_out_1;
                        state <= ANGLE_CALC;
                    end
                end
                
                ANGLE_CALC: begin
                    // Convert VDC value to angle: angle = vdc * 2π
                    angle_reg <= (vdc_value_0_reg * TWO_PI_SCALE) >> SCALE;
                    state <= RADIUS_CALC;
                end
                
                RADIUS_CALC: begin
                    // Convert VDC value to radius: radius = sqrt(vdc)
                    radius_reg <= sqrt_approx(vdc_value_1_reg);
                    state <= TRIG_START;
                end
                
                TRIG_START: begin
                    // Initialize trigonometric calculation
                    calc_iter <= 5'b0;
                    calc_active <= 1'b1;
                    state <= TRIG_CALC;
                end
                
                TRIG_CALC: begin
                    // Simplified trigonometric calculation using lookup table
                    if (calc_iter < 1) begin
                        calc_iter <= calc_iter + 1'b1;
                    end else begin
                        calc_active <= 1'b0;
                        state <= OUTPUT;
                    end
                end
                
                OUTPUT: begin
                    // Apply radius to trigonometric values
                    disk_x <= (cos_val * radius_reg) >> 31;
                    disk_y <= (sin_val * radius_reg) >> 31;
                    valid <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Simplified trigonometric approximation
    always @(posedge clk) begin
        if (calc_active) begin
            // Use angle_reg to compute cos and sin
            case (angle_reg[ANGLE_BITS-1:ANGLE_BITS-4])  // Use top 4 bits for coarse approximation
                4'b0000: begin cos_val <= 32'd2147483648; sin_val <= 32'd0; end      // 0°
                4'b0001: begin cos_val <= 32'd2048909069; sin_val <= 32'd673720364; end  // 22.5°
                4'b0010: begin cos_val <= 32'd1518500250; sin_val <= 32'd1518500250; end // 45°
                4'b0011: begin cos_val <= 32'd673720364; sin_val <= 32'd2048909069; end  // 67.5°
                4'b0100: begin cos_val <= 32'd0; sin_val <= 32'd2147483648; end         // 90°
                4'b0101: begin cos_val <= 32'd3621193184; sin_val <= 32'd2048909069; end // 112.5°
                4'b0110: begin cos_val <= 32'd628646298; sin_val <= 32'd1518500250; end // 135°
                4'b0111: begin cos_val <= 32'd976064279; sin_val <= 32'd673720364; end // 157.5°
                4'b1000: begin cos_val <= 32'd2147483648; sin_val <= 32'd0; end        // 180°
                4'b1001: begin cos_val <= 32'd976064279; sin_val <= 32'd3621193184; end // 202.5°
                4'b1010: begin cos_val <= 32'd628646298; sin_val <= 32'd628646298; end // 225°
                4'b1011: begin cos_val <= 32'd3621193184; sin_val <= 32'd976064279; end // 247.5°
                4'b1100: begin cos_val <= 32'd0; sin_val <= 32'd2147483648; end        // 270°
                4'b1101: begin cos_val <= 32'd673720364; sin_val <= 32'd976064279; end // 292.5°
                4'b1110: begin cos_val <= 32'd1518500250; sin_val <= 32'd628646298; end // 315°
                4'b1111: begin cos_val <= 32'd2048909069; sin_val <= 32'd3621193184; end // 337.5°
                default: begin cos_val <= 32'd2147483648; sin_val <= 32'd0; end
            endcase
        end
    end
    
    // Square root approximation function
    function automatic [31:0] sqrt_approx;
        input [31:0] x;
        reg [31:0] result;
        reg [31:0] temp;
        reg [5:0] i;
        begin
            result = 32'd0;
            temp = 32'd0;
            
            // Simple Newton-Raphson approximation for sqrt(x/scale)
            if (x != 0) begin
                // Initial guess
                result = (x >> 1) + (1 << (SCALE/2));
                
                // Few iterations of Newton-Raphson
                for (i = 0; i < 4; i = i + 1) begin
                    temp = result + (x << SCALE) / result;
                    result = temp >> 1;
                end
            end
            
            sqrt_approx = result;
        end
    endfunction

endmodule