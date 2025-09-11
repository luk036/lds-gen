module cordic_trig_tb;
    reg clk;
    reg rst;
    reg [7:0] angle;
    wire [7:0] sine;
    wire [7:0] cosine;

    // Instantiate the CORDIC trigonometric module
    cordic_trig uut (
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
        $dumpfile("cordic_trig.vcd");
        $dumpvars(0, cordic_trig_tb);

        // Test case 1: Reset
        rst = 1;
        angle = 8'd0;
        #10;
        rst = 0;
        #100;

        // Test case 2: 0 degrees (0)
        angle = 8'd0;
        #100;

        // Test case 3: 90 degrees (64)
        angle = 8'd64;
        #100;

        // Test case 4: 180 degrees (128)
        angle = 8'd128;
        #100;

        // Test case 5: 270 degrees (192)
        angle = 8'd192;
        #100;

        // Test case 6: 45 degrees (32)
        angle = 8'd32;
        #100;

        $display("All tests completed");
        $finish;
    end

    // Monitor changes
    // initial begin
    //     $monitor("Time=%0t angle=%d sine=%d cosine=%d",
    //             $time, angle, $signed(sine), $signed(cosine));
    // end
endmodule
