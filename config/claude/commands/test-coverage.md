---
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
description: Analyze code coverage and generate missing tests
---

## Coverage Analysis Workflow

Analyze existing test coverage and generate tests for uncovered code.

### Step 1: Detect Test Framework
- Go: `go test -coverprofile=coverage.out ./...`
- TypeScript: detect Jest/Vitest from package.json, run with `--coverage`
- Python: `pytest --cov --cov-report=term-missing`

### Step 2: Parse Coverage Report
- Extract per-file coverage percentages
- Identify uncovered lines and functions
- List files below 80% threshold, sorted worst-first

### Step 3: Prioritize Test Targets
For each uncovered file, prioritize:
1. **Happy path**: Core functionality with valid inputs
2. **Error handling**: Error branches, edge cases, invalid inputs
3. **Boundary conditions**: Empty inputs, nil/null, max values

### Step 4: Generate Tests
- Follow existing test patterns in the project
- Use descriptive names: "should [behavior] when [condition]"
- One assertion per test when practical
- Mock external dependencies only

### Step 5: Verify Improvement
- Re-run coverage after adding tests
- Show before/after comparison per file
- Report overall coverage delta

### Output Format
```
Coverage Report:
  Before: X% overall
  Files below 80%:
    - path/to/file.go: 45% (uncovered: lines 23-35, 67-80)
    - path/to/other.go: 62% (uncovered: lines 12-18)

Tests Generated: N new tests across M files
Coverage After: Y% overall (+Z%)
```
