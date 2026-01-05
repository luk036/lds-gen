# Van der Corput SystemVerilog Implementation

This directory contains SystemVerilog implementations of the Van der Corput low-discrepancy sequence generator for bases 2, 3, and 7, converted from the Python implementation in `../src/lds_gen/ilds.py`.

## Files

### Core Modules
- **`vdcorput_32bit.sv`** - Single-base Van der Corput generator (configurable base)
- **`vdcorput_multi_base.sv`** - Multi-base generator (simultaneous bases 2, 3, 7)

### Testbenches
- **`vdcorput_32bit_tb.sv`** - Testbench for single-base module
- **`vdcorput_multi_base_tb.sv`** - Testbench for multi-base module

### Utilities
- **`run_vdcorput_sim.py`** - Python script to generate reference values
- **`README_vdcorput.md`** - This documentation file

## Implementation Details

### Algorithm
The Van der Corput sequence converts integer `count` to a reversed base representation:
1. Repeatedly divide `count` by the base, collecting remainders
2. Multiply each remainder by decreasing powers of the base
3. Sum the results to get the Van der Corput value

### Features
- **32-bit integer arithmetic**
- **Configurable scale parameter** (number of digits)
- **Synchronous design** with clock and reset
- **Pop/reseed interface** matching Python API
- **Parameterized bases** (2, 3, 7)
- **Valid output flag** for timing control

### Interface
```systemverilog
module vdcorput_32bit #(
    parameter BASE = 2,      // Base of the sequence (2, 3, or 7)
    parameter SCALE = 16     // Scale factor (number of digits)
) (
    input  wire        clk,           // Clock signal
    input  wire        rst_n,         // Active-low reset
    input  wire        pop_enable,    // Enable pop operation
    input  wire [31:0] seed,          // Seed value for reseed
    input  wire        reseed_enable, // Enable reseed operation
    output reg  [31:0] vdc_out,       // Van der Corput output
    output reg         valid          // Output valid flag
);
```

## Reference Values

### Base 2 (scale=10)
```
count= 1: 512    count= 2: 256    count= 3: 768    count= 4: 128    count= 5: 640
count= 6: 384    count= 7: 896    count= 8: 64     count= 9: 576    count=10: 320
```

### Base 3 (scale=10)
```
count= 1: 19683   count= 2: 39366   count= 3: 6561    count= 4: 26244   count= 5: 45927
count= 6: 13122   count= 7: 32805   count= 8: 52488   count= 9: 2187    count=10: 21870
```

### Base 7 (scale=10)
```
count= 1: 40353607   count= 2: 80707214   count= 3: 121060821  count= 4: 161414428
count= 5: 201768035  count= 6: 242121642  count= 7: 5764801    count= 8: 46118408
count= 9: 86472015   count=10: 126825622
```

## Simulation

### Running the Python Verification
```bash
cd experiment
python run_vdcorput_sim.py
```

### Running SystemVerilog Simulation
Use your preferred SystemVerilog simulator (ModelSim, Vivado, etc.):

```bash
# For single-base test
vlog vdcorput_32bit.sv vdcorput_32bit_tb.sv
vsim -c vdcorput_32bit_tb -do "run -all; quit"

# For multi-base test
vlog vdcorput_multi_base.sv vdcorput_multi_base_tb.sv
vsim -c vdcorput_multi_base_tb -do "run -all; quit"
```

## Design Notes

1. **Scale Factor**: Larger scale values provide more precision but require more bits
2. **Base Selection**: Only prime bases (2, 3, 7) are implemented as per the original Python code
3. **Timing**: All operations are combinatorial within the clock cycle
4. **Overflow**: 32-bit arithmetic may overflow for large scale factors with bases 3 and 7

## Comparison with Python Implementation

The SystemVerilog implementation faithfully reproduces the Python `VdCorput.pop()` method:
- Same algorithmic steps
- Identical numerical results
- Matching interface behavior (pop/reseed)
- 32-bit integer arithmetic vs Python's arbitrary precision

## Future Enhancements

- Add support for additional bases
- Implement floating-point output mode
- Add pipeline stages for higher clock frequencies
- Include overflow detection and handling