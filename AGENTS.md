# AGENTS.md - Agent Guidelines for lds-gen

## Build/Lint/Test Commands

### Testing
```bash
# Run all tests
tox
pytest

# Run single test
pytest tests/test_file.py::test_function_name
pytest -k "test_pattern"

# With verbose output
pytest -v
```

### Linting & Formatting
```bash
# Run pre-commit hooks (recommended before committing)
pre-commit run --all-files

# Individual tools
black .               # Format code
isort .               # Sort imports
flake8 .              # Check style (max_line_length=127)
mypy src/             # Type check (Python 3.12 target)
```

### Building
```bash
tox -e build          # Build sdist + wheel
tox -e build -- --wheel  # Wheel only
tox -e clean           # Remove build artifacts
```

### Documentation
```bash
tox -e docs           # Build HTML docs
tox -e doctests       # Run doctests
```

## Code Style Guidelines

### Imports
- **Order**: stdlib → third-party → local (PEP8)
- **Tooling**: isort with Black profile (`.isort.cfg`)
- Type hints from `typing` module: `List`, `Sequence`, `Final`, `Union`, `ABC`

### Formatting
- **Formatter**: Black
- **Line length**: 127 characters (not default 88)
- **Compatible**: flake8 ignores E203, W503 for Black compatibility
- **Pre-commit**: Enforced via `.pre-commit-config.yaml`

### Type Hints
- **Required**: All function parameters and return types
- **Style**: `param: type`, `-> ReturnType`
- **Class attributes**: Type-annotated (e.g., `vdc: VdCorput`)
- **Constants**: Use `Final` (e.g., `TWO_PI: Final[float] = 2.0 * pi`)
- **Check**: mypy with Python 3.12 target

### Naming Conventions
- **Classes**: PascalCase (e.g., `VdCorput`, `Halton`, `SphereGen`)
- **Functions/Methods**: snake_case (e.g., `pop()`, `reseed()`, `linspace()`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `TWO_PI`, `PRIME_TABLE`)
- **Private members**: Single underscore prefix (e.g., `_count`, `_lock`)

### Error Handling
- **Thread safety**: Use `threading.Lock` for shared mutable state
- **Critical generators**: `VdCorput`, `Sphere3`, `SphereN` are thread-safe
- **Pattern**:
  ```python
  def pop(self) -> float:
      with self._count_lock:
          self._count += 1
          return vdc(self._count, self.base)
  ```

### Docstrings
- **Primary style**: Sphinx/reStructuredText with `:param:`, `:type:`, `:return:`
- **Alternative**: Google-style in some files (`Args:`, `Returns:`)
- **Doctests**: Included in class/method docstrings with `>>>` examples
- **Module docs**: Comprehensive with SVG diagrams (see `lds.py` header)

### Code Organization
- **Source**: `src/lds_gen/` with namespace package structure
- **Tests**: `tests/` mirroring source files (test_lds.py → lds.py)
- **Classes**: Abstract base classes for shared interfaces (e.g., `SphereGen`)
- **Decorators**: Use `@cache` for memoization, `@abstractmethod` for interfaces

### Thread Safety
- **Generators**: Protect internal state with `threading.Lock()`
- **Methods**: Use `with self._lock:` for atomic operations
- **Testing**: Include thread safety tests using `ThreadPoolExecutor`

## Key Configuration Files
- `setup.cfg` - pytest, flake8 settings
- `pyproject.toml` - build system (setuptools_scm)
- `tox.ini` - task automation (test, build, docs, publish)
- `.isort.cfg` - import sorting (Black profile)
- `mypy.ini` - type checking (Python 3.12)
- `.pre-commit-config.yaml` - code quality hooks

## Project Info
- **Package**: `lds_gen` (low-discrepancy sequence generators)
- **Python**: 3.10+ (tested on 3.10, 3.11)
- **Build**: setuptools_scm (version_scheme=no-guess-dev)
- **License**: MIT

## Development Workflow
```bash
# Before committing
pre-commit run --all-files
pytest

# Test single file/function
pytest tests/test_lds.py::test_vdcorput_thread_safety

# Build and verify package
tox -e clean && tox -e build && tox -e docs
```
