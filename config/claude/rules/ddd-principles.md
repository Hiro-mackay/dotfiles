# Domain-Driven Design Principles

## When to Apply
- Full tactical DDD for core domains with complex business rules only
- Supporting/generic subdomains (CRUD, config, integrations): simpler patterns are fine
- Not every service needs Aggregates, Repositories, and Domain Events -- avoid ceremony without complexity

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

## Language-Specific Notes
- Apply through the lens of the active language rule
- Go: exported fields are idiomatic; avoid getter/setter ceremony
- TypeScript: `readonly` for Value Objects; discriminated unions for Domain Events
- Python: frozen dataclasses or Pydantic models for Value Objects; `@property` for controlled access
