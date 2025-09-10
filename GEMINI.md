# GEMINI.md

## Project Overview

This project, `lds-gen`, is a Python library for generating low-discrepancy sequences. These sequences are more evenly distributed than random numbers and are useful in applications like computer graphics, numerical integration, and Monte Carlo simulations.

The library provides several types of low-discrepancy sequence generators, including:

*   Van der Corput sequence
*   Halton sequence
*   Circle sequence
*   Disk sequence
*   Sphere sequence
*   3-Sphere Hopf sequence
*   N-dimensional Halton sequence

The project is structured as a standard Python library and was scaffolded using PyScaffold.

## Building and Running

### Dependencies

The project's dependencies are listed in `requirements.txt` and `pyproject.toml`.

### Building the Project

To build the project, use the following command:

```bash
python -m build
```

### Running Tests

The project uses `pytest` for testing. To run the tests, use the following command:

```bash
pytest
```

You can also use `tox` to run the tests in isolated environments:

```bash
tox
```

### Running Linters

The project uses `pre-commit` with `isort`, `black`, and `flake8` for linting. To run the linters, use the following command:

```bash
pre-commit run --all-files
```

## Development Conventions

### Coding Style

The project follows the `black` code style and uses `isort` to sort imports.

### Testing

Tests are located in the `tests` directory and are written using `pytest`.

### Documentation

The documentation is located in the `docs` directory and is built using `sphinx`. To build the documentation, use the following command:

```bash
tox -e docs
```
