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

TDD is a workflow with explicit start and end conditions, not "writing tests first". These are the calls you would otherwise get wrong; standard testing vocabulary and structure is deliberately absent.

## The loop
1. **Test list** -- enumerate the behaviors the change needs. This is the start condition
2. **Red** -- take one item and write a failing test, starting from the assertion
3. **Green** -- minimum code to pass
4. **Refactor** -- clean up while green. Implementation design happens here, not in Green
5. Repeat until the list is empty. That is the end condition

- "Working" and "clean" are separate goals, which is why Green and Refactor are separate steps
- Green is allowed to be ugly: hardcoded values, duplication, a faked return. Generalize in Refactor, or with triangulation, and delete the scaffolding tests once you have
- Never refactor while red
- Red is interface design: write the call the way a caller would want it, before the thing exists

## Writing the test
- Assertion first, setup second. It fixes the purpose and stops the test from drifting in scope
- One behavior per test. Name it as a specification: "should [behavior] when [condition]"
- Test the public API. Do not test getters and setters, private methods, framework internals, third-party behavior, or generated code
- Delete tests that stopped earning their maintenance cost -- triangulation scaffolding, duplicates
- A bug fix starts with a failing test that reproduces it. That test is the regression guard

## Reliability
- No flaky tests: fix or quarantine on sight. Past roughly 1% flaky, people stop reading results at all
- Test behavior, not structure -- a test that breaks on an unrelated refactor is a liability
- Each test builds its own state. No shared mutable state, and parallel execution must be safe
- Factories and builders over shared fixtures; fixtures drift and couple tests invisibly. Tear down by transaction rollback or truncate, never by relying on execution order
- Async: deterministic scheduling, latches or barriers for ordering, never `sleep`. Every async assertion gets a timeout

## Doubles and scope
- Mock at process boundaries only -- DB, external APIs, filesystem. Internal collaborators get the real thing unless speed forces otherwise
- More mock setup than assertions means the test is checking wiring, not behavior
- 80% coverage minimum, 90%+ on critical business logic. Integration tests cover module boundaries and external interfaces
- Backfilling coverage on untested code: exercise the real service with fake process-boundary dependencies (in-memory repo, testcontainers). If it cannot be tested without changing production code, stop and say so -- a test-only task must not quietly refactor production code
