//! Command-line interface for lds-gen library
//!
//! This binary provides a simple CLI to generate low-discrepancy sequences.

use clap::{Parser, Subcommand};
use lds_gen::{VdCorput, Halton, Circle, Disk, Sphere, Sphere3Hopf, HaltonN, PRIME_TABLE};

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate Van der Corput sequence
    Vdc {
        /// Base of the sequence (default: 2)
        #[arg(short, long, default_value_t = 2)]
        base: u32,

        /// Number of values to generate (default: 10)
        #[arg(short, long, default_value_t = 10)]
        count: usize,

        /// Starting seed (default: 0)
        #[arg(short, long, default_value_t = 0)]
        seed: u32,
    },

    /// Generate Halton sequence
    Halton {
        /// First base (default: 2)
        #[arg(long, default_value_t = 2)]
        base1: u32,

        /// Second base (default: 3)
        #[arg(long, default_value_t = 3)]
        base2: u32,

        /// Number of points to generate (default: 10)
        #[arg(short, long, default_value_t = 10)]
        count: usize,

        /// Starting seed (default: 0)
        #[arg(short, long, default_value_t = 0)]
        seed: u32,
    },

    /// Generate points on unit circle
    Circle {
        /// Base of the sequence (default: 2)
        #[arg(short, long, default_value_t = 2)]
        base: u32,

        /// Number of points to generate (default: 10)
        #[arg(short, long, default_value_t = 10)]
        count: usize,

        /// Starting seed (default: 0)
        #[arg(short, long, default_value_t = 0)]
        seed: u32,
    },

    /// List first N primes from prime table
    Primes {
        /// Number of primes to list (default: 20)
        #[arg(short, long, default_value_t = 20)]
        count: usize,
    },
}

fn main() {
    let cli = Cli::parse();

    match cli.command {
        Commands::Vdc { base, count, seed } => {
            println!("Van der Corput sequence (base: {}, seed: {}):", base, seed);
            let mut vgen = VdCorput::new(base);
            vgen.reseed(seed);
            for i in 0..count {
                println!("  {}: {}", i + 1, vgen.pop());
            }
        }

        Commands::Halton { base1, base2, count, seed } => {
            println!("Halton sequence (bases: [{}, {}], seed: {}):", base1, base2, seed);
            let mut hgen = Halton::new([base1, base2]);
            hgen.reseed(seed);
            for i in 0..count {
                let point = hgen.pop();
                println!("  {}: [{:.6}, {:.6}]", i + 1, point[0], point[1]);
            }
        }

        Commands::Circle { base, count, seed } => {
            println!("Circle points (base: {}, seed: {}):", base, seed);
            let mut cgen = Circle::new(base);
            cgen.reseed(seed);
            for i in 0..count {
                let point = cgen.pop();
                println!("  {}: [{:.6}, {:.6}]", i + 1, point[0], point[1]);
            }
        }

        Commands::Primes { count } => {
            let n = count.min(PRIME_TABLE.len());
            println!("First {} primes:", n);
            for i in 0..n {
                print!("{} ", PRIME_TABLE[i]);
                if (i + 1) % 10 == 0 {
                    println!();
                }
            }
            if n % 10 != 0 {
                println!();
            }
        }
    }
}