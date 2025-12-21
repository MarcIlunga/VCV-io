# UC Framework CI/CD

This directory contains the CI/CD workflows for the UC (Universal Composability) framework.

## Workflows

### `uc-ci.yml` - UC Framework CI

A comprehensive CI workflow that tests the UC framework implementation.

**Triggers:**
- Push to `copilot/specify-uc-in-lean` branch
- Push to `main` branch
- Pull requests to `main`
- Manual workflow dispatch

**Jobs:**

1. **check-uc-imports** - Verifies all UC modules are properly imported in `VCVio.lean`
2. **build-uc** - Builds all UC framework modules individually and as a library
3. **test-uc-examples** - Verifies UC examples compile correctly
4. **verify-specification** - Checks specification documentation completeness
5. **status-report** - Provides comprehensive CI status summary

**What it tests:**
- ✅ All UC modules build successfully
- ✅ UC framework integrates with VCV-io properly
- ✅ Basic examples compile (authenticated channels, secure communication, etc.)
- ✅ Advanced examples compile (two-party computation)
- ✅ Specification documentation is complete
- ✅ All basic UC patterns are documented

### `build.yml` - Main Build Workflow

The main build workflow that runs on all pushes. It includes:
- Import checking for all library files
- Full project build
- Example builds

The UC framework is automatically included in this workflow as part of the VCVio library.

### `ci.yml` - Standard Lean CI

Uses the standard Lean action to build the project. This provides a simpler, canonical build test.

## Running CI Locally

### Building the UC Framework

```bash
# Get mathlib cache (faster builds)
lake exe cache get

# Build individual UC modules
lake build VCVio.UC.Basic
lake build VCVio.UC.Monad
lake build VCVio.UC.Serializable
lake build VCVio.UC.Communication
lake build VCVio.UC.Functionality
lake build VCVio.UC.Security

# Build all UC modules
lake build VCVio.UC

# Build entire VCVio library (includes UC)
lake build VCVio
```

### Running UC Tests

```bash
# Build the UC test suite
lake build VCVio.UC.Test

# Build basic examples
lake build VCVio.UC.BasicExamples

# Build advanced examples
lake build VCVio.UC.AdvancedExample
```

### Verifying Imports

The CI checks that all `.lean` files in `VCVio/` are imported in `VCVio.lean`. To verify locally:

```bash
# Generate expected imports
git ls-files 'VCVio/*.lean' | LC_ALL=C sort | sed 's/\.lean//;s,/,.,g;s/^/import /' > expected_imports.txt

# Compare with actual VCVio.lean
diff expected_imports.txt VCVio.lean
```

## UC Framework Test Coverage

The CI ensures the following UC components are tested:

### Core Components
- [x] Basic types (SessionID, PartyId, UCContext, LocalState)
- [x] UC monad operations
- [x] Serialization typeclass and instances
- [x] Communication primitives (send, receive, leak)
- [x] Functionality definitions
- [x] Protocol definitions

### Standard Functionalities
- [x] F_AUTH (authenticated communication)
- [x] F_SEC (secure communication)
- [x] F_ZK (zero-knowledge proofs)
- [x] F_COM (commitment schemes)
- [x] F_SIG (digital signatures)
- [x] F_KE (key exchange)

### Examples
- [x] Authenticated channel protocol
- [x] Secure communication protocol
- [x] Commitment protocol
- [x] Zero-knowledge authentication
- [x] Two-party computation
- [x] Secure message transfer (composition example)

### Documentation
- [x] Plain markdown specification (UC_SPECIFICATION.md)
- [x] Implementation summary
- [x] Architecture overview
- [x] Module README

## CI Status Badge

Add this to your README to show CI status:

```markdown
[![UC Framework CI](https://github.com/MarcIlunga/VCV-io/actions/workflows/uc-ci.yml/badge.svg)](https://github.com/MarcIlunga/VCV-io/actions/workflows/uc-ci.yml)
```

## Troubleshooting

### Build Failures

If the build fails:

1. Check import order - imports must be in sorted order
2. Verify all UC modules are listed in VCVio.lean
3. Check for syntax errors in Lean files
4. Ensure mathlib cache is up to date: `lake exe cache get`

### Import Check Failures

If the import check fails:

1. Run the import generation command locally
2. Update VCVio.lean with any missing imports
3. Ensure imports are sorted (LC_ALL=C sort)

### Test Failures

If UC tests fail:

1. Build modules individually to isolate the issue
2. Check VCVio.UC.Test for syntax errors
3. Verify examples compile: `lake build VCVio.UC.BasicExamples`

## Adding New UC Modules

When adding a new UC module:

1. Create the `.lean` file in `VCVio/UC/`
2. Update `VCVio/UC.lean` to import it (if it should be public)
3. The CI will automatically detect it and verify it's imported in `VCVio.lean`
4. Add any tests to `VCVio/UC/Test.lean`

The import check workflow will fail if any `.lean` file is not imported, ensuring complete test coverage.
