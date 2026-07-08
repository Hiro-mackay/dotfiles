---
name: readable-code
description: Code readability guidelines covering function length, nesting depth, naming conventions, and abstraction decisions. Applies when writing or reviewing any code.
---

# Readable Code Rules

## Functions
- 30 lines max per function, single responsibility
- One level of abstraction per function
- Extract when a block needs a comment to explain what it does

## Nesting
- 3 levels max. Early return / guard clause first to reduce nesting
- Invert conditions to eliminate `else` blocks when possible

## Parameters
- 3 parameters max per function
- Group related parameters into a struct/object

## Comments
- Default to none. Write one only when the code cannot carry the meaning itself.
- WHY only, never WHAT (code must be self-documenting)
- 2 lines by default, 3 at most. Needing more means the fix is naming or structure, not more prose.
- Say each rationale once. Don't repeat an explanation across sibling functions — hoist it to a file- or type-level doc.
- A comment block longer than the code beneath it is a smell — compress to the point.
- Delete commented-out code -- version control exists
- Mark deliberate simplifications with their ceiling and upgrade trigger — e.g. `// global lock; switch to per-account if throughput matters`

### Compressing an over-long comment
Bad — 6-line paragraph restating the test flow:
    // ...verifies the single-claim fix end-to-end: two users racing to accept
    // the same invitation must result in exactly one membership... The unit
    // tests, which run against in-memory fakes, cannot exercise the FOR UPDATE
    // row lock... The race only double-admits when both accepts read the
    // still-pending invitation before either commits...
Good — 2 lines, only what the code can't say:
    // Integration-only: exercises the FOR UPDATE lock that in-memory fakes can't.
    // 8 rounds: a double-admit only lands when both accepts read pending before either commits.

## Abstraction
- Rule of Three -- do not abstract until the third duplication (see `architecture-decisions` for system-level YAGNI)
- Name things for what they represent, not how they work

## Branching
- if/else exceeding 3 branches -> switch/match or polymorphism
- Prefer lookup tables / maps over long if-else chains

## Error Messages
- Include context: what failed, what was expected, what to do next
- Bad: "Invalid input" / Good: "Expected positive integer for age, got -5"

## Magic Values
- No literal values in logic -- use named constants
- Exception: 0, 1, empty string, true/false
