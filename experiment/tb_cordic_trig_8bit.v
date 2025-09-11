module cordic_trig_tb;
    // Signal declarations
    reg clk;
    reg rst;
    reg [7:0] angle;
    wire [7:0] sine;
    wire [7:0] cosine;

    // Instantiate the DUT
    cordic_trig dut (
        .clk(clk),
        .rst(rst),
        .angle(angle),
        .sine(sine),
        .cosine(cosine)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Test case 1: Reset
        rst = 1;
        angle = 8'd0;
        #10;
        rst = 0;
        #10;

        // Test case 2: 0 degrees
        angle = 8'd0;
        #20;
        if (cosine !== 8'b01111111 || sine !== 8'b00000000)
            $display("Error: 0 degrees test failed");

        // Test case 3: 45 degrees
        angle = 8'd64;
        #20;
        if (cosine <= 8'b01011010 || sine <= 8'b01011010)
            $display("Error: 45 degrees test failed");

        // Test case 4: 90 degrees
        angle = 8'd128;
        #20;
        if (cosine !== 8'b00000000 || sine !== 8'b01111111)
            $display("Error: 90 degrees test failed");

        // Test case 5: 180 degrees
        angle = 8'd255;
        #20;
        if (cosine >= 8'b10000000 || sine !== 8'b00000000)
            $display("Error: 180 degrees test failed");

        // Test case 6: Rapid angle changes
        angle = 8'd32;  // 22.5 degrees
        #10;
        angle = 8'd96;  // 67.5 degrees
        #10;
        angle = 8'd160; // 112.5 degrees
        #10;

        // End simulation
        #100;
        $display("Test completed");
        $finish;
    end

    // Optional waveform dump
    initial begin
        $dumpfile("cordic_test.vcd");
        $dumpvars(0, cordic_trig_tb);
    end

endmodule
