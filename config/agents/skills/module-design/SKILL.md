---
name: module-design
description: Module boundary design covering coupling, cohesion, dependency direction, and interface contracts. Applies when deciding how to split code into modules, packages, or services, or when reasoning about dependency relationships.
---

# Module Design Principles

The boundary calls that go wrong. Definitions of coupling and cohesion are deliberately absent.

## Where the boundary goes
- Things that always change together are one module. If A's every change drags B along, the split is in the wrong place
- Split by domain capability, not by technical layer. `controller/`, `service/`, `repository/` groups code by what it is instead of what it is for, so every feature change touches all three
- Change frequency, team ownership, and independent deployability are all real boundaries. Weekly-churn code next to yearly-churn code is two modules
- Premature splitting costs as much as premature abstraction. Keep it merged until the boundary is obvious rather than predicted
- A microservice only when independent deployment or independent scaling is actually required. Start as a module inside the monolith

## Two tests
- Can you state the module's purpose in one sentence with no "and" in it?
- Can you replace its internals without touching a single caller?

## Dependency direction
- Volatile depends on stable, never the reverse. Stable means rarely changed with many dependents (domain model, core interfaces); volatile means often changed with few (UI, adapters, config)
- The interface belongs to the consumer. Define it where it is needed, not next to the implementation that happens to satisfy it
- A module that is both stable and concrete is the pain point in any codebase -- either give it an abstraction or reduce what depends on it

## Interfaces
- Expose the minimum. Every public name is a commitment you cannot withdraw without breaking someone
- But expose enough: a caller who has to know your internals to use the API correctly has an incomplete interface, not a simple one
- Accept liberally, return precisely
- Document which errors a caller can receive and what they are expected to do about each. An undocumented error contract makes every caller guess

## Cycles
- A circular dependency is a missing abstraction or a misplaced boundary, never a build-tool problem
- Fix it by extracting the shared concept, inverting one direction through a consumer-owned interface, replacing the call with an event, or merging the two -- they may genuinely be one thing
- Never by lazy loading, a service locator, or an import moved inside a function. Those hide the cycle and keep the design wrong
