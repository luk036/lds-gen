# lds-gen - Low-Discrepancy Sequence Generator in Rust

A Rust implementation of low-discrepancy sequence generators, ported from the Python `lds-gen` library.

## Overview

This library provides a set of low-discrepancy sequence generators that create sequences of numbers that are more evenly distributed than random numbers. These sequences are particularly useful in various fields such as computer graphics, numerical integration, and Monte Carlo simulations.

## Features

- **Van der Corput sequence**: Base implementation for 1D sequences
- **Halton sequence**: 2D and N-dimensional sequences using different bases
- **Geometric sequences**: 
  - `Circle`: Points on the unit circle
  - `Disk`: Points in the unit disk  
  - `Sphere`: Points on the unit sphere
  - `Sphere3Hopf`: Points on the 3-sphere using Hopf fibration
- **N-dimensional spheres**: 
  - `Sphere3`: Points on 3-sphere (4D)
  - `SphereN`: Points on n-sphere for arbitrary dimensions
- **Integer sequences**: Integer versions of Van der Corput and Halton sequences
- **Prime table**: First 1000 prime numbers for use as sequence bases

## Installation

Add this to your `Cargo.toml`:

```toml
[dependencies]
lds-gen = "0.1.0"
```

## Usage

### Basic Van der Corput Sequence

```rust
use lds_gen::VdCorput;

let mut vgen = VdCorput::new(2);
vgen.reseed(0);
println!("First value: {}", vgen.pop()); // 0.5
println!("Second value: {}", vgen.pop()); // 0.25
```

### 2D Halton Sequence

```rust
use lds_gen::Halton;

let mut hgen = Halton::new([2, 3]);
hgen.reseed(0);
let point = hgen.pop();
println!("Point: {:?}", point); // [0.5, 0.3333333333333333]
```

### Points on a Sphere

```rust
use lds_gen::Sphere;

let mut sgen = Sphere::new([2, 3]);
sgen.reseed(0);
let point = sgen.pop();
println!("Sphere point: {:?}", point); // Point on unit sphere
```

### N-Dimensional Spheres

```rust
use lds_gen::sphere_n::{Sphere3, SphereN, SphereGen};

// 3-sphere (4D)
let mut sgen3 = Sphere3::new(&[2, 3, 5]);
sgen3.reseed(0);
let point3 = sgen3.pop();
println!("3-sphere point: {:?}", point3); // 4D point on unit 3-sphere

// n-sphere (5D)
let mut sgen_n = SphereN::new(&[2, 3, 5, 7]);
sgen_n.reseed(0);
let point_n = sgen_n.pop();
println!("n-sphere point: {:?}", point_n); // 5D point on unit 4-sphere
```

### Integer Sequences

```rust
use lds_gen::ilds::{VdCorput, Halton};

// Integer Van der Corput
let mut ivdc = VdCorput::new(2, 10);
ivdc.reseed(0);
println!("Integer value: {}", ivdc.pop()); // 512

// Integer Halton
let mut ihalton = Halton::new([2, 3], [11, 7]);
ihalton.reseed(0);
let int_point = ihalton.pop();
println!("Integer point: {:?}", int_point); // [1024, 729]
```

## API Reference

### Core Types

- `VdCorput`: Van der Corput sequence generator
- `Halton`: 2D Halton sequence generator  
- `Circle`: Unit circle sequence generator
- `Disk`: Unit disk sequence generator
- `Sphere`: Unit sphere sequence generator
- `Sphere3Hopf`: 3-sphere sequence generator using Hopf coordinates
- `HaltonN`: N-dimensional Halton sequence generator

### N-Dimensional Sphere Types (in `sphere_n` module)

- `sphere_n::SphereGen`: Trait for sphere generators
- `sphere_n::Sphere3`: 3-sphere (4D) sequence generator
- `sphere_n::SphereN`: N-sphere sequence generator for arbitrary dimensions

### Integer Types (in `ilds` module)

- `ilds::VdCorput`: Integer Van der Corput sequence generator
- `ilds::Halton`: Integer 2D Halton sequence generator

### Constants

- `TWO_PI`: Constant for 2π
- `PRIME_TABLE`: First 1000 prime numbers

## Examples

See the [examples](examples/) directory for more usage examples.

## Testing

Run the tests with:

```bash
cargo test
```

## Performance

The Rust implementation provides significant performance improvements over the Python version, with zero-cost abstractions and efficient memory usage.

## License

MIT License - see [LICENSE](LICENSE) file.

## Acknowledgments

Based on the original Python implementation by Wai-Shing Luk (luk036@gmail.com).