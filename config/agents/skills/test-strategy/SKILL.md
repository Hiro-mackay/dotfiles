---
name: test-strategy
description: TDD workflow (t-wada style), test reliability, test scope strategy, and AI-era testing guardrails. Applies when writing tests, planning test coverage, or practicing test-driven development.
paths:
  - "**/*_test.*"
  - "**/test_*.*"
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/conftest.py"
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/e2e/**"
---

# Test Strategy (t-wada Style)

TDD is a programming workflow with clear start/end conditions, not just "writing tests first."

## TDD Workflow (5 Steps)

1. **Test List** -- list behaviors needed for the change. This IS the start condition
2. **Red** -- pick one item, write a failing test. Start from the assertion (assert-first)
3. **Green** -- write the minimum code to pass. Fake It is legitimate
4. **Refactor** -- clean up while tests stay green. Implementation design happens here
5. **Repeat** -- until the test list is empty. This IS the end condition

## Red-Green-Refactor Discipline

- Divide and conquer: "working" and "clean" are separate goals. Green = working, Refactor = clean
- Red phase is interface design -- write code as a user would call it (use before build)
- Green phase allows shortcuts -- hardcoded values, duplication, ugly code. Speed over elegance
- Never refactor on Red -- all refactoring happens only when tests pass
- Commit at each phase boundary -- Red: test commit, Green: feat commit, Refactor: refactor commit(s)

## Implementation Strategies

Choose one per Green step:

- **Fake It** -- return a hardcoded value, then generalize. Use when unsure of the algorithm
- **Obvious Implementation** -- write the real code directly. Use when the solution is clear
- **Triangulation** -- add test cases to force generalization. Use when direction is unclear. Delete scaffolding tests once generalized

## Test Writing Rules

- One test, one behavior -- each test verifies exactly one thing
- AAA structure: Arrange, Act, Assert. Visually separate the three sections
- Assert-first -- write the assertion before setup. Fixes purpose and prevents scope drift
- Test names as specifications: "should [behavior] when [condition]"
- Tests are executable specifications -- a new developer should understand the spec by reading tests
- Test the public API, not internal methods
- Delete unnecessary tests -- triangulation tests, redundant tests. Tests have maintenance cost
- Do NOT test: getters/setters, framework internals, third-party library behavior, private methods, generated code

## Test Prioritization

For each module, write tests in this order:
1. **Happy path**: core functionality with valid inputs
2. **Error handling**: error branches, edge cases, invalid inputs
3. **Boundary conditions**: empty inputs, nil/null, max values

## Test Reliability

- No flaky tests -- fix or quarantine immediately. Above ~1% flaky rate, developers ignore all test results
- No brittle tests -- tests MUST NOT break on unrelated implementation changes. Test behavior, not structure
- Test isolation: each test creates its own state, no shared mutable state between tests. Parallel execution MUST be safe
- Test data: use factories/builders over shared fixtures. Fixtures drift and create hidden coupling between tests
- Teardown: transaction rollback (fastest) or truncate. Never rely on test execution order for cleanup
- Bug fix workflow: reproduce the bug as a failing test FIRST, then fix. The test IS the regression guard

## Test Doubles

- **Stub**: returns canned data. Use for queries / read operations
- **Mock**: verifies interactions. Use sparingly -- only when the side effect IS the behavior (e.g., "email was sent")
- **Fake**: working lightweight implementation (in-memory DB, local filesystem). Use for integration-like speed at unit cost
- **Spy**: records calls for later assertion. Prefer over mock when you need to verify AND get return values
- Mock at process boundaries -- DB, external APIs, filesystem. Do NOT mock internal collaborators unless for speed
- Over-mocking signal: if a test has more mock setup than assertions, you're testing wiring, not behavior

## Test Scope

- Test pyramid: many unit tests, fewer integration, fewest E2E
- 3x3 matrix: Size (small/medium/large) x Scope (unit/integration/E2E). Keep most tests small + unit
- Start where testability is highest: small scope, observable output, controllable input
- Coverage targets: 80% minimum overall, 90%+ for critical business logic
- Integration tests for module boundaries and external system interfaces
- Async/concurrency: test with deterministic scheduling where possible. Use latches/barriers for ordering, not sleep. Timeout every async assertion

## AI-Era Guardrails

- Tests are the spec for AI -- test code is less ambiguous than natural language prompts
- Human owns architecture and cohesion -- delegate mechanical test implementation to AI
- Use TDD vocabulary in prompts -- "TDD style", "Red-Green-Refactor", pattern names give AI effective context
- Degradation is faster with AI -- without tests as guardrails, codebase quality degrades in days, not months
