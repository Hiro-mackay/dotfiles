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
Zero by default. The bar is not "is this useful?" — it is "can the code not say this itself?" Almost always it can.

Write a comment ONLY when it is one of these three:
1. A doc comment the language's tooling or a public API contract requires
2. A fact the code cannot state: an external spec or protocol quirk, a workaround for someone else's bug, an ordering the compiler won't enforce but the domain does, a non-obvious invariant
3. A deliberate simplification, with its upgrade trigger — `// global lock; switch to per-account if throughput matters`

Everything else is not written. If it is already there, delete it:
- Restating WHAT the next line does — `// increment the counter`, `// loop over users`, `// initialize the client`
- Narrating the change or the task — `// added for the retry feature`, `// per review feedback`, `// new in v2`
- Section banners — `// --- helpers ---`, `// ===== main logic =====`
- Doc comments that only echo the signature — `// GetUser returns the user.`
- Restating a name that already says it — if the comment is needed to understand the name, fix the name (see `naming-conventions`)
- Commented-out code — version control exists

Length: 1 line, 2 at most. Say each rationale once — don't repeat it across sibling functions; hoist it to a file- or type-level doc. A comment block longer than the code beneath it is a smell.

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
