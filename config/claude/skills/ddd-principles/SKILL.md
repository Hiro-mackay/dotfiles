---
name: ddd-principles
description: Domain-Driven Design tactical patterns including aggregates, domain events, bounded contexts, and anti-corruption layers. Applies when modeling business domains or designing domain layers.
---

# Domain-Driven Design Principles

## When to Apply
- Full tactical DDD for core domains with complex business rules only
- Supporting/generic subdomains (CRUD, config, integrations): simpler patterns are fine
- Not every service needs Aggregates, Repositories, and Domain Events -- avoid ceremony without complexity

## Discovery Process
1. **Identify domain events**: what happened? Past tense verbs (`OrderPlaced`, `PaymentFailed`). Start from business outcomes and work backward
2. **Group events into commands**: what triggered each event? (`PlaceOrder` -> `OrderPlaced`). Commands reveal user intent
3. **Identify aggregates**: which entity enforces the rules for each command? That entity is the aggregate root
4. **Draw bounded contexts**: where does the same word mean different things? (`Account` in billing vs auth = two contexts)
5. **Map context relationships**: upstream/downstream, shared kernel, conformist, anti-corruption layer
- Context boundaries often align with team boundaries and deployment units
- Two contexts that always deploy together are probably one context
- If domain experts from different departments use different vocabulary, that's a context boundary
- For naming conventions and anti-patterns, see `naming-conventions` skill

## Design Rules
- One transaction per aggregate -- no cross-aggregate transactions
- Keep aggregates small -- only include what MUST be immediately consistent
- Reference other aggregates by ID, not direct object reference
- Push business logic into domain objects, not services or controllers
- Application layer orchestrates; domain layer decides
- Write side MUST go through aggregates. Read side CAN bypass domain when practical (joins, search, reporting)
- Domain objects MUST NOT depend on infrastructure (Dependency Inversion)
- Prefer behavior methods over getters
- Factory when aggregate creation involves invariants or complex assembly
- Anti-Corruption Layer when integrating with external systems or legacy contexts

## Aggregate Sizing
- Default to single-entity aggregates -- expand only when invariants demand immediate consistency
- Two entities without shared invariant = two aggregates
- Large aggregates cause contention and slow loads -- split aggressively

## Event Design
- Past tense naming: OrderPlaced, PaymentReceived
- Include: aggregate ID, timestamp, causation ID, correlation ID
- Events are immutable facts -- never modify after publishing
- Prefer thin events (IDs + changed fields) over fat events (full state) -- consumers query if they need more

## Modeling Heuristics
- Model what the system DOES, not what the real world IS. Software models are purpose-built
- Start with behaviors (what happens), not structures (what exists). Verbs before nouns
- If two concepts have different lifecycles, they're different entities
- If two concepts always change together, they might be one entity
- Time is almost always relevant: "when did this happen?" should be answerable
- State machines: if an entity has distinct phases with different rules, model it as explicit states
- Avoid god entities: if `User` has 30 fields, it's modeling multiple concepts
- Ubiquitous language: code, docs, and conversation MUST use the same terms. Code IS the executable glossary

## Language-Specific Notes
- Apply through the lens of the active language rule
- Go: exported fields are idiomatic; avoid getter/setter ceremony
- TypeScript: `readonly` for Value Objects; discriminated unions for Domain Events
- Python: frozen dataclasses or Pydantic models for Value Objects; `@property` for controlled access
