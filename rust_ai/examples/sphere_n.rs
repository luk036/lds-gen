//! Examples of n-dimensional sphere sequence generation

use lds_gen::sphere_n::{Sphere3, SphereN, SphereGen};

fn main() {
    println!("=== N-Dimensional Sphere Sequence Examples ===\n");

    // Example 1: 3-Sphere (4D)
    println!("1. 3-Sphere sequence (bases [2, 3, 5]):");
    println!("   Generates points on 3-sphere (4-dimensional)");
    let mut sgen3 = Sphere3::new(&[2, 3, 5]);
    sgen3.reseed(0);
    for i in 0..3 {
        let point = sgen3.pop();
        let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
        println!("  Point {}: {:?}", i + 1, point);
        println!("    Radius squared: {:.12} (should be 1.0)", radius_sq);
    }
    println!();

    // Example 2: 4-Sphere (5D)
    println!("2. 4-Sphere sequence (bases [2, 3, 5, 7]):");
    println!("   Generates points on 4-sphere (5-dimensional)");
    let mut sgen4 = SphereN::new(&[2, 3, 5, 7]);
    sgen4.reseed(0);
    for i in 0..2 {
        let point = sgen4.pop();
        let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
        println!("  Point {}: {:?}", i + 1, point);
        println!("    Radius squared: {:.12} (should be 1.0)", radius_sq);
    }
    println!();

    // Example 3: Higher dimensions
    println!("3. Higher dimensional spheres:");
    let dimensions = [3, 4, 5, 6];
    for &dim in &dimensions {
        let bases: Vec<u32> = (0..dim).map(|i| lds_gen::PRIME_TABLE[i] as u32).collect();
        let mut sgen = SphereN::new(&bases);
        sgen.reseed(0);
        let point = sgen.pop();
        let radius_sq = point.iter().map(|&x| x * x).sum::<f64>();
        println!("  {}-sphere ({}D): radius² = {:.12}", dim - 1, dim, radius_sq);
    }
    println!();

    // Example 4: Reseeding demonstration
    println!("4. Reseeding demonstration for 3-sphere:");
    let mut sgen = Sphere3::new(&[2, 3, 5]);
    
    println!("  Starting from seed 0:");
    sgen.reseed(0);
    for i in 0..2 {
        let point = sgen.pop();
        println!("    Point {}: {:?}", i + 1, point);
    }
    
    println!("  Reseeding to seed 5:");
    sgen.reseed(5);
    for i in 0..2 {
        let point = sgen.pop();
        println!("    Point {}: {:?}", i + 1, point);
    }
    
    println!("  Going back to seed 0:");
    sgen.reseed(0);
    for i in 0..2 {
        let point = sgen.pop();
        println!("    Point {}: {:?}", i + 1, point);
    }
    println!();

    // Example 5: Uniformity check
    println!("5. Uniformity check (1000 points on 3-sphere):");
    let mut sgen = Sphere3::new(&[2, 3, 7]);
    sgen.reseed(0);
    
    let mut octants = [0; 16]; // 16 octants in 4D
    for _ in 0..1000 {
        let point = sgen.pop();
        let mut octant = 0;
        for (i, &coord) in point.iter().enumerate() {
            if coord >= 0.0 {
                octant |= 1 << i;
            }
        }
        octants[octant] += 1;
    }
    
    let expected_per_octant = 1000.0 / 16.0;
    println!("  Expected points per octant: {:.1}", expected_per_octant);
    println!("  Octant distribution:");
    for (i, &count) in octants.iter().enumerate() {
        let deviation = (count as f64 - expected_per_octant) / expected_per_octant * 100.0;
        println!("    Octant {:04b}: {} points ({:+.1}%)", i, count, deviation);
    }
}