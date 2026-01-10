/*
Testbench for 16-bit CORDIC
*/

`timescale 1ns/1ps

module test_cordic_16bit;

    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] angle;
    wire [31:0] cosine;
    wire [31:0] sine;
    wire done;
    wire ready;

    cordic_trig_16bit_working dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .angle(angle),
        .cosine(cosine),
        .sine(sine),
        .done(done),
        .ready(ready)
    );

    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end

    integer cycle_count;

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
    end

    task wait_cycles;
        input integer num_cycles;
        begin
            repeat(num_cycles) @(posedge clk);
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        angle = 0;
        cycle_count = 0;

        // Apply reset
        wait_cycles(2);
        rst_n = 1;
        wait_cycles(2);

        $display("Testing 16-bit CORDIC");
        $display("=====================");

        // Test 1: Angle 0° (should give cos=1, sin=0)
        $display("\nTest 1: Angle 0°");
        angle = 0;  // 0° = 0 in 16-bit (0-65535 maps to 0-2π)
        wait_cycles(20);  // Wait for CORDIC to converge

        $display("cos(0°) = 0x%08h (%0.3f)", cosine, $signed(cosine) / 65536.0);
        $display("sin(0°) = 0x%08h (%0.3f)", sine, $signed(sine) / 65536.0);

        // Test 2: Angle 90° (π/2)
        $display("\nTest 2: Angle 90°");
        // 90° = π/2 = 1/4 of 2π = 65536/4 = 16384
        angle = 16384;
        wait_cycles(20);

        $display("cos(90°) = 0x%08h (%0.3f)", cosine, $signed(cosine) / 65536.0);
        $display("sin(90°) = 0x%08h (%0.3f)", sine, $signed(sine) / 65536.0);

        // Test 3: Angle 180° (π)
        $display("\nTest 3: Angle 180°");
        // 180° = π = 1/2 of 2π = 65536/2 = 32768
        angle = 32768;
        wait_cycles(20);

        $display("cos(180°) = 0x%08h (%0.3f)", cosine, $signed(cosine) / 65536.0);
        $display("sin(180°) = 0x%08h (%0.3f)", sine, $signed(sine) / 65536.0);

        // Test 4: Angle 45° (π/4)
        $display("\nTest 4: Angle 45°");
        // 45° = π/4 = 1/8 of 2π = 65536/8 = 8192
        angle = 8192;
        wait_cycles(20);

        $display("cos(45°) = 0x%08h (%0.3f)", cosine, $signed(cosine) / 65536.0);
        $display("sin(45°) = 0x%08h (%0.3f)", sine, $signed(sine) / 65536.0);

        // Test 5: Angle 30° (π/6)
        $display("\nTest 5: Angle 30°");
        // 30° = π/6 = 1/12 of 2π = 65536/12 ≈ 5461
        angle = 5461;
        wait_cycles(20);

        $display("cos(30°) = 0x%08h (%0.3f)", cosine, $signed(cosine) / 65536.0);
        $display("sin(30°) = 0x%08h (%0.3f)", sine, $signed(sine) / 65536.0);

        $display("\nTotal cycles: %0d", cycle_count);
        $finish;
    end

endmodule
