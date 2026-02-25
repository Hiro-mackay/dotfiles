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
- WHY only, never WHAT (code must be self-documenting)
- Delete commented-out code -- version control exists

## Abstraction
- Rule of Three -- do not abstract until the third duplication
- Three similar lines of code is better than a premature abstraction
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
