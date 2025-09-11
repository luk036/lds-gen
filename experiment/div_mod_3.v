/*
Division by 3 Circuit (div_mod_3.v)

This Verilog module implements a digital circuit that divides an 8-bit number by 3 and produces both the quotient and remainder. Let's break it down in simple terms.

Purpose: The circuit performs division by 3 on any number between 0 and 255 (8 bits) and tells you both how many times 3 goes into that number (quotient) and what's left over (remainder).

Inputs and Outputs:

- Input: An 8-bit number 'n' that you want to divide by 3
- Outputs:
    - An 8-bit quotient (how many times 3 goes into n)
    - A 2-bit remainder (what's left over, which can only be 0, 1, or 2)

How it works: The circuit uses a clever method that breaks down the division process into four iterations. Instead of doing regular division, it uses a series of additions and bit manipulations. Here's the step-by-step process:

1. First iteration: It splits the input number into two parts and adds them together
2. Second iteration: Takes the result from step 1, splits it again, and adds those parts
3. Third iteration: Repeats the process with the result from step 2
4. Fourth iteration: Does one final split and add operation

The final step checks if the last remainder equals 3 (binary '11'). If it does, it adds 1 to the quotient and sets the remainder to 0, because if we have a remainder of 3, that means we can fit in one more complete division by 3.

The beauty of this design is that it avoids complex division operations by using simpler operations like addition and bit selection. This makes it efficient to implement in digital hardware. The circuit processes all these steps simultaneously (in parallel) since it uses wires rather than sequential operations.

This is particularly useful in digital systems where you need to perform division by 3 quickly and efficiently, such as in digital signal processing or certain types of data encoding.
*/
module div_mod_3(
    input wire [7:0] n,
    output wire [7:0] quotient,
    output wire [1:0] remainder
);
    // First iteration
    wire [5:0] q1 = n[7:2];
    wire [1:0] r1 = n[1:0];
    wire [6:0] rem1 = q1 + r1;

    // Second iteration
    wire [4:0] q2 = rem1[6:2];
    wire [1:0] r2 = rem1[1:0];
    wire [5:0] rem2 = q2 + r2;

    // Third iteration
    wire [3:0] q3 = rem2[5:2];
    wire [1:0] r3 = rem2[1:0];
    wire [4:0] rem3 = q3 + r3;

    // Fourth iteration
    wire [1:0] q4 = rem3[4:2];
    wire [1:0] r4 = rem3[1:0];
    wire [1:0] rem4 = q4 + r4;

    // Final quotient sum
    wire [7:0] quotient_sum = q1 + q2 + q3 + q4;

    // Final check and output assignment
    assign quotient = (rem4 == 2'b11) ? quotient_sum + 1 : quotient_sum;
    assign remainder = (rem4 == 2'b11) ? 2'b00 : rem4[1:0];
endmodule
