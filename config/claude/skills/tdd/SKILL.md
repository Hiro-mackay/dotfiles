---
name: tdd
description: Start a TDD red-green-refactor workflow
disable-model-invocation: true
argument-hint: "[target behavior or file]"
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
---

## TDD Workflow for: $ARGUMENTS

Follow the RED -> GREEN -> REFACTOR cycle strictly.

### Process
1. **Understand**: What behavior are we implementing or fixing?
2. **RED**: Write a failing test that defines the expected behavior
3. **Verify RED**: Run tests, confirm the new test FAILS
4. **GREEN**: Write minimum code to make the test pass
5. **Verify GREEN**: Run tests, confirm ALL tests PASS
6. **REFACTOR**: Clean up while keeping tests green
7. **Verify REFACTOR**: Run tests one final time

### Rules
- NEVER write implementation before tests
- One test at a time, one behavior per test
- Test behavior, not implementation details
- Minimum 80% coverage, 100% for critical logic

### Test Framework Detection
- Go: `go test ./...`
- TypeScript: detect Jest/Vitest from package.json
- Python: `pytest`
