---
name: ddd-principles
description: Domain-Driven Design tactical patterns including aggregates, domain events, bounded contexts, and anti-corruption layers. Applies when modeling business domains, designing domain layers, or implementing business logic anywhere in the codebase.
paths:
  - "**/domain/**"
  - "**/usecase/**"
  - "**/usecases/**"
  - "**/application/**"
  - "**/service/**"
  - "**/services/**"
  - "**/repository/**"
  - "**/repositories/**"
  - "**/aggregate/**"
  - "**/entity/**"
---

# Domain-Driven Design Principles

The calls that go wrong when applying DDD. The pattern catalogue itself is deliberately absent.

## Whether to apply it at all
- Full tactical DDD is for core domains with genuinely complex rules. CRUD, config, and integration subdomains get simpler patterns
- Aggregates, repositories, and domain events are not a baseline. Ceremony without complexity is the common failure, not the reverse

## Boundaries
- The same word meaning two things is the boundary (`Account` in billing vs auth). Different departments using different vocabulary for the same thing is the same signal
- Two contexts that always deploy together are one context
- Context boundaries tend to land on team and deployment boundaries
- Naming conventions and anti-patterns: `naming-conventions` skill

## Aggregates
- One transaction, one aggregate. Reference other aggregates by ID, never by object
- Default to a single entity per aggregate. Expand only when an invariant demands immediate consistency; two entities with no shared invariant are two aggregates. Large aggregates mean contention and slow loads
- The write side goes through aggregates. The read side may bypass the domain where it pays -- joins, search, reporting
- Business rules live in domain objects, not in services or controllers. The application layer orchestrates, the domain layer decides, and behavior methods beat getters
- Domain objects depend on no infrastructure

## Events
- Carry the aggregate ID, timestamp, causation ID, and correlation ID
- Thin events (IDs plus what changed) over fat ones. Consumers that need more can query

## Modeling
- Model what the system does, not what the world is. Start from behaviors -- verbs before nouns
- Different lifecycles mean different entities; things that always change together may be one
- A `User` with 30 fields is several concepts wearing one name
- Code is the executable glossary: the term in the conversation is the term in the code

## By language
- Go: exported fields are idiomatic -- skip the getter/setter ceremony
- TypeScript: `readonly` for value objects, discriminated unions for domain events
- Python: frozen dataclasses or Pydantic for value objects, `@property` for controlled access
