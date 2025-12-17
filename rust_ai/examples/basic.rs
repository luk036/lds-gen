//! Basic examples of using the lds-gen library

use lds_gen::{Circle, Disk, Halton, HaltonN, PRIME_TABLE, Sphere, VdCorput};

fn main() {
    println!("=== Basic Low-Discrepancy Sequence Examples ===\n");

    // Example 1: Van der Corput sequence
    println!("1. Van der Corput sequence (base 2):");
    let mut vgen = VdCorput::new(2);
    vgen.reseed(0);
    for i in 0..5 {
        println!("  Value {}: {}", i + 1, vgen.pop());
    }
    println!();

    // Example 2: Halton sequence
    println!("2. Halton sequence (bases [2, 3]):");
    let mut hgen = Halton::new([2, 3]);
    hgen.reseed(0);
    for i in 0..3 {
        let point = hgen.pop();
        println!("  Point {}: [{:.6}, {:.6}]", i + 1, point[0], point[1]);
    }
    println!();

    // Example 3: Circle sequence
    println!("3. Points on unit circle (base 2):");
    let mut cgen = Circle::new(2);
    cgen.reseed(0);
    for i in 0..3 {
        let point = cgen.pop();
        println!("  Point {}: [{:.6}, {:.6}]", i + 1, point[0], point[1]);
    }
    println!();

    // Example 4: Disk sequence
    println!("4. Points in unit disk (bases [2, 3]):");
    let mut dgen = Disk::new([2, 3]);
    dgen.reseed(0);
    for i in 0..3 {
        let point = dgen.pop();
        let radius = (point[0] * point[0] + point[1] * point[1]).sqrt();
        println!(
            "  Point {}: [{:.6}, {:.6}] (radius: {:.6})",
            i + 1,
            point[0],
            point[1],
            radius
        );
    }
    println!();

    // Example 5: Sphere sequence
    println!("5. Points on unit sphere (bases [2, 3]):");
    let mut sgen = Sphere::new([2, 3]);
    sgen.reseed(0);
    for i in 0..3 {
        let point = sgen.pop();
        let radius = (point[0] * point[0] + point[1] * point[1] + point[2] * point[2]).sqrt();
        println!(
            "  Point {}: [{:.6}, {:.6}, {:.6}] (radius: {:.6})",
            i + 1,
            point[0],
            point[1],
            point[2],
            radius
        );
    }
    println!();

    // Example 6: N-dimensional Halton sequence
    println!("6. 4D Halton sequence (first 4 primes):");
    let bases = &PRIME_TABLE[0..4];
    let mut hgen_n = HaltonN::new(bases);
    hgen_n.reseed(0);
    for i in 0..2 {
        let point = hgen_n.pop();
        println!("  Point {}: {:?}", i + 1, point);
    }
    println!();

    // Example 7: Using prime table
    println!("7. First 10 primes from PRIME_TABLE:");
    for i in 0..10 {
        print!("{} ", PRIME_TABLE[i]);
    }
    println!("\n");
}
