//! Examples of integer low-discrepancy sequences

use lds_gen::ilds::{Halton, VdCorput};

fn main() {
    println!("=== Integer Low-Discrepancy Sequence Examples ===\n");

    // Example 1: Integer Van der Corput sequence
    println!("1. Integer Van der Corput sequence (base 2, scale 10):");
    println!("   (Values represent 0.x * 2^10)");
    let mut ivdc = VdCorput::new(2, 10);
    ivdc.reseed(0);
    for i in 0..5 {
        let value = ivdc.pop();
        let float_value = value as f64 / 1024.0; // 2^10 = 1024
        println!("  Value {}: {} (≈ {:.6})", i + 1, value, float_value);
    }
    println!();

    // Example 2: Integer Halton sequence
    println!("2. Integer Halton sequence (bases [2, 3], scales [11, 7]):");
    println!("   First dimension: 0.x * 2^11 = 0.x * 2048");
    println!("   Second dimension: 0.x * 3^7 = 0.x * 2187");
    let mut ihalton = Halton::new([2, 3], [11, 7]);
    ihalton.reseed(0);
    for i in 0..3 {
        let point = ihalton.pop();
        let float_point = [
            point[0] as f64 / 2048.0, // 2^11 = 2048
            point[1] as f64 / 2187.0, // 3^7 = 2187
        ];
        println!(
            "  Point {}: [{}, {}] (≈ [{:.6}, {:.6}])",
            i + 1,
            point[0],
            point[1],
            float_point[0],
            float_point[1]
        );
    }
    println!();

    // Example 3: Different scales
    println!("3. Integer Van der Corput with different scales:");
    for &scale in &[8, 10, 12, 16] {
        let mut vdc = VdCorput::new(2, scale);
        vdc.reseed(0);
        let value = vdc.pop();
        let max_value = 2u32.pow(scale);
        let float_value = value as f64 / max_value as f64;
        println!(
            "  Scale {}: {} / {} = {:.6}",
            scale, value, max_value, float_value
        );
    }
    println!();

    // Example 4: Reseeding
    println!("4. Reseeding demonstration:");
    let mut vdc = VdCorput::new(2, 10);

    println!("  Starting from seed 0:");
    vdc.reseed(0);
    for i in 0..3 {
        println!("    Value {}: {}", i + 1, vdc.pop());
    }

    println!("  Reseeding to seed 5:");
    vdc.reseed(5);
    for i in 0..3 {
        println!("    Value {}: {}", i + 1, vdc.pop());
    }

    println!("  Going back to seed 0:");
    vdc.reseed(0);
    for i in 0..3 {
        println!("    Value {}: {}", i + 1, vdc.pop());
    }
}
