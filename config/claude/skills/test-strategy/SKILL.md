---
name: test-strategy
description: Testing principles and strategy for all languages. Use when writing tests, designing test architecture, or evaluating test quality. Covers TDD cycle, coverage targets, and test patterns.
user-invocable: false
---

# Test Strategy

## Principles
- Test behavior, not implementation details
- One assertion per test when possible
- Test names: "should [behavior] when [condition]"
- Test the public API, not internal methods
- Mock external dependencies (network, filesystem, third-party APIs), not internal modules

## Coverage Targets
- 80% minimum overall, 100% for critical business logic
- Test error paths and edge cases
- Integration tests for module boundaries

## Test Prioritization
For each module, write tests in this order:
1. **Happy path**: Core functionality with valid inputs
2. **Error handling**: Error branches, edge cases, invalid inputs
3. **Boundary conditions**: Empty inputs, nil/null, max values

## TDD Cycle
1. **RED**: Write a failing test for the next behavior
2. **GREEN**: Write ONLY the code to make THIS test pass
3. **REFACTOR**: Clean up while tests stay green
4. Repeat until all requirements are implemented
