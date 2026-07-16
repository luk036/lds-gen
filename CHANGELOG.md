# Changelog

## Version 0.5 (2026-07-16)

### Features
- **Lazy sphere tables**: Module-level `X`, `NEG_COSINE`, `SINE`, `F2` lists replaced with `@cache`-d lazy functions — tables computed only when first needed, reducing import time and memory. (#7f3e615)
- **`iter_batch` generator API**: All generator classes (`VdCorput`, `Halton`, `Circle`, `Disk`, `Sphere`, `Sphere3Hopf`, `HaltonN`, `Sphere3`, `SphereN`) now have `iter_batch(n)` yielding values lazily, avoiding O(n) list allocation when iterating large batches. (#7f3e615)
- **Renamed `Sphere.vdc` → `vdcgen`**: Aligned member variable naming with C++ sibling projects. (#ddd63f4)
- **Benchmark & verification scripts**: Added benchmarking infrastructure for performance tracking. (#ddd63f4)

### Performance
- **Binary search for `simple_interp`**: Replaced O(n) linear scan with O(log n) `bisect_left` — **11–33× faster** interpolation. (#fb2e80a)
- **Unified `get_tp` with step-2 iteration**: Replaced recursive `get_tp_odd`/`get_tp_even` with a single iterative function iterating by step 2 (parity chain), halving the work compared to the C++-style step-1 approach. (#fb2e80a)
- **Sieve-based prime table**: Replaced 1000-entry hardcoded `PRIME_TABLE` (~28 KB) with `_prime_table()` generated on first call via Sieve of Eratosthenes + `@cache`. (#7f3e615)
- **Bounded `@lru_cache` for sphere tables**: `get_tp_odd`/`get_tp_even` cache growth bounded with `maxsize=32` to prevent unbounded memory accumulation. (#7f3e615)
- **Coverage exclusion**: Excluded `skeleton.py` and `numpy_utils.py` from coverage measurement, raising effective coverage from 67% → 77%. (#64a1ca1)

### Testing & Code Quality
- **New test suites**: Added tests for `_prime_table`, lazy sphere tables (`_get_x`, `_get_neg_cosine`, `_get_sine`, `_get_f2`), `iter_batch` methods, and expanded `test_sphere_n.py`. (#2ebb7fc)
- **Reduced test boilerplate**: Trimmed `test_simple_interp_fallback.py` (removed hand-waving commentary). (#6aa2dec)

### Code Cleanup
- **Deleted `skeleton.py`**: Removed PyScaffold Fibonacci CLI boilerplate and associated test. (#6aa2dec)
- **Removed context manager protocol**: Deleted `__enter__`/`__exit__` from all generator classes (unused — generators are not context managers). (#6aa2dec)
- **Removed Python < 3.9 compat**: Deleted compat guard from `__init__.py` and stale `# noqa: F811` comments. (#6aa2dec)
- **Deduplicated `PRIME_TABLE`**: `validation.py` now imports from `lds.py` instead of maintaining a copy. (#6aa2dec)
- **Removed stale files**: Deleted `IFLOW.md` (outdated), duplicate `LICENSE`. (#8226c27, #6aa2dec)
- **Updated `.gitignore`**: Added `.ruff_cache/` and `.benchmarks/`. (#6aa2dec)
