# VdCorput FSM-Based Sequential Implementation (32-bit)

## Overview

This directory contains a hardware implementation of the Van der Corput sequence generator using a Finite State Machine (FSM) approach. The design supports bases 2, 3, and 7, and uses 32-bit fixed-point arithmetic (16.16 format).

## Files

1. **`vdcorput_fsm_32bit_simple.v`** - Main Verilog module with FSM implementation
2. **`vdcorput_fsm_32bit_simple_tb.v`** - Testbench for verification
3. **`div_mod_3.v`** - Division by 3 module (reused from existing design)
4. **`div_mod_7.v`** - Division by 7 module (reused from existing design)
5. **`test_vdc_reference.py`** - Python reference implementation
6. **`vdcorput_sequential_test.py`** - Python sequential test generator
7. **`vdcorput_fsm_32bit.sv`** - SystemVerilog version (advanced features)
8. **`vdcorput_fsm_32bit_tb.sv`** - SystemVerilog testbench

## Algorithm

The Van der Corput sequence converts an integer `count` to a floating-point value by:
1. Repeatedly dividing `count` by the base
2. Accumulating remainders divided by decreasing powers of the base

Mathematically: `vdc(count, base) = Σ (remainder_i / base^(i+1))`

## FSM Design

The implementation uses a 7-state FSM:

1. **IDLE** - Wait for start signal
2. **INIT** - Initialize registers based on base selection
3. **DIVIDE** - Perform division (count / base)
4. **ACCUMULATE** - Add remainder * power_of_base to accumulator
5. **UPDATE** - Update count = quotient, power_of_base /= base
6. **CHECK** - Check if count == 0
7. **FINISH** - Output result

## Fixed-Point Representation

- **Format**: 16.16 fixed-point (16 integer bits, 16 fractional bits)
- **Range**: 0.0 to 65535.9999847
- **Precision**: 1/65536 ≈ 0.00001526

Key constants (16.16 format):
- `FP_ONE` = 0x00010000 (1.0)
- `FP_HALF` = 0x00008000 (0.5)
- `FP_THIRD` = 0x00005555 (1/3 ≈ 0.333333)
- `FP_SEVENTH` = 0x00002492 (1/7 ≈ 0.142857)

## Interface

### Inputs
- `clk` - System clock
- `rst_n` - Active-low reset
- `start` - Start computation
- `k_in[31:0]` - Input integer count
- `base_sel[1:0]` - Base selection (00=2, 01=3, 10=7)

### Outputs
- `result[31:0]` - 32-bit fixed-point result
- `done` - Computation complete
- `ready` - Module ready for new input

## Verification

### Test Cases
The testbench verifies 18 test cases (6 per base):
- Base 2: count = 1, 2, 3, 4, 5, 11
- Base 3: count = 1, 2, 3, 4, 5, 11
- Base 7: count = 1, 2, 3, 4, 5, 11

### Expected Results (from Python `vdc` function)
```
Base 2:
  vdc(1, 2) = 0.5        (0x00008000)
  vdc(2, 2) = 0.25       (0x00004000)
  vdc(3, 2) = 0.75       (0x0000C000)
  vdc(4, 2) = 0.125      (0x00002000)
  vdc(5, 2) = 0.625      (0x0000A000)
  vdc(11, 2) = 0.8125    (0x0000D000)

Base 3:
  vdc(1, 3) = 0.333333   (0x00005555)
  vdc(2, 3) = 0.666667   (0x0000AAAA)
  vdc(3, 3) = 0.111111   (0x00001C71)
  vdc(4, 3) = 0.444444   (0x000071C7)
  vdc(5, 3) = 0.777778   (0x0000C71C)
  vdc(11, 3) = 0.703704  (0x0000B425)

Base 7:
  vdc(1, 7) = 0.142857   (0x00002492)
  vdc(2, 7) = 0.285714   (0x00004924)
  vdc(3, 7) = 0.428571   (0x00006DB6)
  vdc(4, 7) = 0.571429   (0x00009249)
  vdc(5, 7) = 0.714286   (0x0000B6DB)
  vdc(11, 7) = 0.591837  (0x00009782)
```

## Building and Running

### Compilation
```bash
cd hwdesign
iverilog -o vdcorput_simple_test div_mod_3.v div_mod_7.v vdcorput_fsm_32bit_simple.v vdcorput_fsm_32bit_simple_tb.v
```

### Simulation
```bash
vvp vdcorput_simple_test
```

### Python Reference
```bash
python test_vdc_reference.py
python vdcorput_sequential_test.py
```

## Performance

- **Clock cycles per computation**: ~7 + (number of digits in base representation of count)
- **Maximum count value**: 2^32 - 1 (4,294,967,295)
- **Throughput**: Can pipeline computations for continuous sequence generation

## Design Notes

1. **Division Implementation**:
   - Base 2: Simple right shift
   - Base 3: Uses `div_mod_3` module (8-bit)
   - Base 7: Uses `div_mod_7` module (9-bit)

2. **Fixed-Point Arithmetic**:
   - Multiplication: `remainder * power_reg` (remainder is small: 0-6)
   - Division by base: Multiply by reciprocal constant

3. **FSM Optimization**:
   - States can be merged for reduced latency
   - Pipeline registers can be added for higher throughput

## Extensions

Possible enhancements:
1. Support for more bases (5, 11, 13, etc.)
2. Pipelined version for higher throughput
3. Configurable fixed-point precision
4. Streaming interface for continuous sequence generation
5. Integration with other LDS generators (Halton, Circle, etc.)

## References

1. Python `lds_gen` library: `src/lds_gen/lds.py`
2. Van der Corput sequence algorithm
3. Fixed-point arithmetic techniques
4. FSM design patterns for digital circuits
