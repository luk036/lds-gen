/*
Simple test to debug angle calculation
*/

module test_angle_calc;

    initial begin
        $display("Testing angle calculation for Circle sequence");
        $display("=============================================");
        
        // Test case: base=2, k=1
        // Python: vdc(1,2) = 0.5
        // Angle = 0.5 * 2π = π ≈ 3.14159
        
        // In 16.16 fixed-point:
        // 0.5 = 0x00008000 (32768)
        // 2π ≈ 6.283185 = 0x0006487F
        
        // Calculate: 0x00008000 * 0x0006487F = ?
        reg [63:0] product;
        reg [31:0] angle_fp;
        
        product = 64'h00008000 * 64'h0006487F;
        $display("Product (64-bit): 0x%016h", product);
        
        // Right shift by 16 bits for fixed-point multiplication
        angle_fp = product[47:16];
        $display("Angle (16.16): 0x%08h", angle_fp);
        
        // Convert to decimal
        real angle_dec;
        angle_dec = $signed(angle_fp) / 65536.0;
        $display("Angle (radians): %0.10f", angle_dec);
        $display("Expected π: %0.10f", 3.1415926535);
        
        // Get upper 16 bits for LUT index
        reg [15:0] lut_index;
        lut_index = angle_fp[31:16];
        $display("LUT index (0-65535): 0x%04h (%0d)", lut_index, lut_index);
        
        // LUT uses upper 8 bits of 16-bit index
        reg [7:0] lut_entry;
        lut_entry = lut_index[15:8];
        $display("LUT entry (0-255): 0x%02h (%0d)", lut_entry, lut_entry);
        
        // Expected: π corresponds to 180° = 128 in 0-255 range
        $display("Expected LUT entry for π: 0x80 (128)");
        
        $display("\nTest case: base=2, k=2");
        // Python: vdc(2,2) = 0.25
        // Angle = 0.25 * 2π = π/2 ≈ 1.5708
        
        // 0.25 = 0x00004000 (16384)
        product = 64'h00004000 * 64'h0006487F;
        angle_fp = product[47:16];
        angle_dec = $signed(angle_fp) / 65536.0;
        lut_index = angle_fp[31:16];
        lut_entry = lut_index[15:8];
        
        $display("Angle (16.16): 0x%08h", angle_fp);
        $display("Angle (radians): %0.10f", angle_dec);
        $display("Expected π/2: %0.10f", 1.5707963268);
        $display("LUT index: 0x%04h (%0d)", lut_index, lut_index);
        $display("LUT entry: 0x%02h (%0d)", lut_entry, lut_entry);
        $display("Expected LUT entry for π/2: 0x40 (64)");
        
        $finish;
    end

endmodule