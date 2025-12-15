# lds-gen C++ Library

C++20 implementation of the lds-gen Python library for generating low-discrepancy sequences.

## Features

- **Van der Corput sequence**: Base-b low-discrepancy sequence
- **Halton sequence**: Multi-dimensional low-discrepancy sequence
- **Circle sequence**: Points on a unit circle
- **Disk sequence**: Points in a unit disk
- **Sphere sequence**: Points on a unit sphere
- **Sphere3 Hopf sequence**: Points on a 3-sphere using Hopf fibration
- **N-dimensional Halton sequence**: Arbitrary dimensional Halton sequences
- **Sphere3 sequence**: Points on a 3-sphere using cylindrical mapping
- **SphereN sequence**: Points on n-dimensional spheres
- **Integer versions**: Integer-based sequences for fixed-point arithmetic

## Requirements

- C++20 compatible compiler (GCC 10+, Clang 10+, MSVC 2019+)
- CMake 3.20+ or xmake
- doctest (automatically downloaded for tests)

## Building with CMake

```bash
mkdir build
cd build
cmake ..
cmake --build .
```

### Build options

- `BUILD_SHARED_LIBS`: Build shared library (default: OFF)
- `BUILD_TESTS`: Build tests (default: ON)
- `BUILD_EXAMPLES`: Build examples (default: ON)

## Building with xmake

```bash
xmake
xmake run example  # Run example
xmake run test_lds # Run tests
```

## Usage

```cpp
#include "lds_gen.hpp"
#include <iostream>

int main() {
    // Van der Corput sequence
    lds_gen::VdCorput vgen(2);
    vgen.reseed(0);
    for (int i = 0; i < 10; ++i) {
        std::cout << vgen.pop() << "\n";
    }

    // Halton sequence
    lds_gen::Halton hgen({2, 3});
    hgen.reseed(0);
    auto point = hgen.pop();
    std::cout << "[" << point[0] << ", " << point[1] << "]\n";

    return 0;
}
```

## API Overview

### Floating-point sequences

- `double vdc(uint64_t k, uint64_t base = 2)`: Van der Corput function
- `class VdCorput`: Van der Corput sequence generator
- `class Halton`: 2D Halton sequence generator
- `class Circle`: Unit circle sequence generator
- `class Disk`: Unit disk sequence generator
- `class Sphere`: Unit sphere sequence generator
- `class Sphere3Hopf`: 3-sphere Hopf sequence generator
- `class HaltonN`: N-dimensional Halton sequence generator
- `const std::vector<uint64_t> PRIME_TABLE`: First 1000 prime numbers

### N-dimensional sphere sequences

- `class SphereGen`: Base class for sphere generators
- `class Sphere3`: 3-sphere sequence generator
- `class SphereN`: N-dimensional sphere sequence generator
- `std::vector<double> get_tp(int n)`: Table-lookup of mapping function
- `double simple_interp(double x, const std::vector<double>& xp, const std::vector<double>& yp)`: 1D interpolation
- `std::vector<double> linspace(double start, double stop, size_t num)`: Linear spacing

### Integer sequences

- `class VdCorputInt`: Integer Van der Corput sequence generator
- `class HaltonInt`: Integer 2D Halton sequence generator

## Testing

Tests use doctest framework and are automatically built with CMake or xmake:

```bash
# CMake
cd build
ctest

# xmake
xmake run test_lds
xmake run test_ilds
```

## Examples

See `examples/example.cpp` for comprehensive usage examples.

## License

MIT License - see LICENSE file

## Acknowledgments

Based on the Python lds-gen library by Wai-Shing Luk (luk036@gmail.com)