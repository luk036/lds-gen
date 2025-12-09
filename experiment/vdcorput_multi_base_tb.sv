`timescale 1ns/1ps

/*
Multi-Base Van der Corput Testbench

This testbench verifies the functionality of the multi-base Van der Corput sequence generator
that simultaneously produces sequences for bases 2, 3, and 7.
*/

module vdcorput_multi_base_tb;

    // Test parameters
    parameter CLK_PERIOD = 10;
    parameter TEST_SCALE = 8;  // Use smaller scale for easier verification

    // Signals for DUT connections
    reg         clk;
    reg         rst_n;
    reg         pop_enable;
    reg  [31:0] seed;
    reg         reseed_enable;
    wire [31:0] vdc_out_2;
    wire [31:0] vdc_out_3;
    wire [31:0] vdc_out_7;
    wire        valid;

    // Expected values for testing (calculated from Python reference)
    reg [31:0] expected_2, expected_3, expected_7;
    reg [31:0] i;  // Loop variable for iverilog compatibility

    // Instantiate DUT
    vdcorput_multi_base #(
        .SCALE(TEST_SCALE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pop_enable(pop_enable),
        .seed(seed),
        .reseed_enable(reseed_enable),
        .vdc_out_2(vdc_out_2),
        .vdc_out_3(vdc_out_3),
        .vdc_out_7(vdc_out_7),
        .valid(valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 1'b0;
        pop_enable = 1'b0;
        reseed_enable = 1'b0;
        seed = 32'd0;

        // Apply reset
        #20;
        rst_n = 1'b1;
        #10;

        $display("=== Multi-Base Van der Corput Testbench ===");
        $display("Testing bases 2, 3, and 7 with scale %0d", TEST_SCALE);

        // Test 1: Basic sequence generation
        $display("\n--- Test 1: Basic Multi-Base Sequence ---");
        pop_enable = 1'b1;

        // Test first few values for all bases
        for (i = 1; i <= 10; i = i + 1) begin
            @(posedge valid);

            // Calculate expected values using Python logic
            expected_2 = calculate_expected(i, 2, TEST_SCALE);
            expected_3 = calculate_expected(i, 3, TEST_SCALE);
            expected_7 = calculate_expected(i, 7, TEST_SCALE);

            $display("k=%0d: Base2=%0d (exp=%0d) Base3=%0d (exp=%0d) Base7=%0d (exp=%0d)",
                     i, vdc_out_2, expected_2, vdc_out_3, expected_3, vdc_out_7, expected_7);

            // Verify values
            if (vdc_out_2 !== expected_2)
                $display("FAIL: Base 2 mismatch at k=%0d", i);
            if (vdc_out_3 !== expected_3)
                $display("FAIL: Base 3 mismatch at k=%0d", i);
            if (vdc_out_7 !== expected_7)
                $display("FAIL: Base 7 mismatch at k=%0d", i);
        end

        pop_enable = 1'b0;
        #20;

        // Test 2: Reseed functionality
        $display("\n--- Test 2: Reseed Test ---");
        reseed_enable = 1'b1;
        seed = 32'd5;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;

        pop_enable = 1'b1;
        @(posedge valid);

        expected_2 = calculate_expected(6, 2, TEST_SCALE);
        expected_3 = calculate_expected(6, 3, TEST_SCALE);
        expected_7 = calculate_expected(6, 7, TEST_SCALE);

        $display("After reseed to 5 (k=6): Base2=%0d Base3=%0d Base7=%0d",
                 vdc_out_2, vdc_out_3, vdc_out_7);

        if (vdc_out_2 !== expected_2 || vdc_out_3 !== expected_3 || vdc_out_7 !== expected_7)
            $display("FAIL: Reseed test failed");
        else
            $display("PASS: Reseed test passed");

        pop_enable = 1'b0;
        #20;

        // Test 3: Large values test
        $display("\n--- Test 3: Large Values Test ---");
        reseed_enable = 1'b1;
        seed = 32'd100;
        @(posedge clk);
        reseed_enable = 1'b0;
        #10;

        pop_enable = 1'b1;
        for (i = 101; i <= 105; i = i + 1) begin
            @(posedge valid);
            $display("k=%0d: Base2=%0d Base3=%0d Base7=%0d", i, vdc_out_2, vdc_out_3, vdc_out_7);
        end

        pop_enable = 1'b0;
        #20;

        $display("\n=== All Multi-Base Tests Completed ===");
        $finish;
    end

    // Function to calculate expected Van der Corput values (Python reference logic)
    function automatic [31:0] calculate_expected;
        input [31:0] k;
        input [31:0] base;
        input [31:0] scale;
        reg [31:0] k_temp;
        reg [31:0] vdc_val;
        reg [31:0] factor;
        reg [31:0] remainder;
        reg [31:0] scale_factor;
        reg [31:0] i;
        begin
            // Calculate base^scale
            scale_factor = 32'd1;
            for (i = 0; i < scale; i = i + 1) begin
                scale_factor = scale_factor * base;
            end

            k_temp = k;
            vdc_val = 32'd0;
            factor = scale_factor;

            while (k_temp != 32'd0) begin
                factor = factor / base;
                remainder = k_temp % base;
                k_temp = k_temp / base;
                vdc_val = vdc_val + (remainder * factor);
            end

            calculate_expected = vdc_val;
        end
    endfunction

    // Timeout protection
    initial begin
        #10000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
