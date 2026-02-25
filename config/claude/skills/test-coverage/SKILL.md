---
name: test-coverage
description: Analyze code coverage and generate missing tests
disable-model-invocation: true
argument-hint: "[file or directory]"
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
---

## Coverage Analysis for: $ARGUMENTS

### Step 1: Run Coverage

Detect test framework and run with coverage:
- Go: `go test -coverprofile=coverage.out ./...`
- TypeScript: detect Jest/Vitest from package.json, run with `--coverage`
- Python: `pytest --cov --cov-report=term-missing`

### Step 2: Identify Gaps

- Extract per-file coverage percentages
- List files below 80% threshold, sorted worst-first
- Identify uncovered lines and functions

### Step 3: Generate Tests

Prioritize per uncovered file:
1. **Happy path**: Core functionality with valid inputs
2. **Error handling**: Error branches, edge cases, invalid inputs
3. **Boundary conditions**: Empty inputs, nil/null, max values

Follow existing test patterns. Use descriptive names: "should [behavior] when [condition]".

### Step 4: Verify

Re-run coverage and report before/after comparison:
```
Coverage Report:
  Before: X% overall
  Files below 80%:
    - path/to/file.go: 45% (uncovered: lines 23-35, 67-80)
  Tests Generated: N new tests across M files
  After: Y% overall (+Z%)
```
