/*
Debug angle calculation in Circle module
*/

`timescale 1ns/1ps

module debug_circle_angle;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] k_in;
    reg [1:0] base_sel;
    wire [31:0] result_x;
    wire [31:0] result_y;
    wire done;
    wire ready;

    // We'll directly instantiate the modules to probe internal signals
    // VdCorput instance
    wire vdc_ready, vdc_done;
    wire [31:0] vdc_result;
    reg vdc_start;

    // Angle register
    wire [31:0] angle_reg;

    // Create a test version that exposes internal signals
    reg [31:0] debug_k_reg;
    reg [31:0] debug_vdc_result;
    reg [31:0] debug_angle_reg;
    reg [15:0] debug_lut_angle;

    vdcorput_fsm_32bit_simple vdc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(vdc_start),
        .k_in(debug_k_reg),
        .base_sel(base_sel),
        .result(vdc_result),
        .done(vdc_done),
        .ready(vdc_ready)
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        k_in = 0;
        base_sel = 0;
        vdc_start = 0;
        debug_k_reg = 0;

        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        $display("Debugging Circle angle calculation");
        $display("==================================");

        // Test base 2, count=1
        $display("\nTest: base=2, count=1");
        debug_k_reg = 32'd1;
        base_sel = 2'b00;

        // Start VdCorput
        wait(vdc_ready == 1);
        @(posedge clk);
        vdc_start = 1;
        @(posedge clk);
        vdc_start = 0;

        // Wait for VdCorput to complete
        wait(vdc_done == 1);
        @(posedge clk);

        debug_vdc_result = vdc_result;
        $display("VdCorput result: 0x%08h (%0.10f)",
                 debug_vdc_result, $signed(debug_vdc_result) / 65536.0);

        // Calculate angle: vdc_result * 2π
        // 2π ≈ 6.283185 in 16.16 = 0x0006487F
        debug_angle_reg = (debug_vdc_result * 32'h0006487F) >> 16;
        $display("Angle (16.16): 0x%08h (%0.10f * 2π)",
                 debug_angle_reg, $signed(debug_angle_reg) / 65536.0);

        // LUT angle (upper 16 bits)
        debug_lut_angle = debug_angle_reg[31:16];
        $display("LUT angle index: 0x%04h (%0d)",
                 debug_lut_angle, debug_lut_angle);

        // Expected: vdc(1,2) = 0.5, angle = 0.5 * 2π = π ≈ 3.14159
        // In 16-bit (0-65535 for 0-2π): π = 32768
        $display("Expected LUT angle: 0x8000 (32768)");

        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
