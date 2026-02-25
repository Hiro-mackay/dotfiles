# Domain-Driven Design Principles

## When to Apply
- Apply full tactical DDD to core domains with complex business rules
- For supporting/generic subdomains (CRUD, config, integrations), simpler patterns are appropriate
- Not every service needs Aggregates, Repositories, and Domain Events -- avoid ceremony without complexity

## Core Concepts
- **Ubiquitous Language**: Use domain terms in code, docs, and conversation. No translation layer between business and code.
- **Bounded Context**: Each context has its own model. Same term can mean different things across contexts.
- **Context Map**: Define relationships between contexts (Shared Kernel, Anti-Corruption Layer, Conformist, etc.)

## Building Blocks
- **Entity**: Has identity, lifecycle matters. Compare by ID, not attributes.
- **Value Object**: Immutable, no identity. Compare by attributes. Prefer over entities when possible. Use for: money, addresses, date ranges, measurements, identifiers. They simplify testing and eliminate aliasing bugs.
- **Aggregate**: Consistency boundary. One root entity (Aggregate Root) controls access. All external operations go through the root. State changes MUST go through behavior methods that enforce invariants -- never expose mutable state directly.
- **Repository**: Interface defined in domain layer, implementation in infrastructure layer. Provides collection-like access to aggregates. One repository per aggregate root. Never expose query details (SQL, ORM) to domain.
- **Factory**: Encapsulates complex creation logic for aggregates and entities. Ensures all invariants are satisfied at construction time. Use when constructor alone is insufficient.
- **Domain Event**: Record of something that happened in the domain. Past tense naming (OrderPlaced, PaymentReceived). Use for: decoupling between aggregates, communicating across bounded contexts, recording domain-significant facts. Include aggregate ID and timestamp.
- **Domain Service**: Stateless operation that doesn't naturally belong to any Entity or Value Object. Common cases: logic spanning multiple aggregates, or domain rules requiring external domain knowledge.
- **Application Service (Command)**: Orchestrates write operations. Receives command, coordinates domain objects, persists via repository. No business logic -- delegates decisions to domain layer. Handles transactions.
- **Application Service (Query)**: Orchestrates read operations. CAN bypass domain layer for performance. Single aggregate retrieval can go through domain; cross-aggregate listings and searches CAN query read models directly. This Command/Query split is the simplest form of CQRS.
- **Module (Package)**: Groups related domain concepts. Naming MUST reflect ubiquitous language (e.g., `ordering`, `shipping`), not technical layers (e.g., `models`, `services`).

## Design Rules
- One transaction per aggregate -- no cross-aggregate transactions
- Keep aggregates small -- only include what MUST be immediately consistent
- Reference other aggregates by ID, not direct object reference
- Push business logic into domain objects, not services or controllers
- Application layer orchestrates; domain layer decides
- Write side MUST go through aggregates. Read side CAN bypass domain when practical (complex joins, search, reporting). Separate read models and event sourcing are optional escalations, not defaults
- Domain objects MUST NOT depend on infrastructure (Dependency Inversion)
- Prefer behavior methods over getters -- follow language conventions (e.g., Go uses exported fields as practical concession)
- Use Factory when aggregate creation involves invariants or complex assembly
- Anti-Corruption Layer when integrating with external systems or legacy contexts

## Language-Specific Notes
- Apply these principles through the lens of the active language rule (go-principles, typescript-principles, python-principles)
- Go: exported fields are idiomatic; avoid getter/setter ceremony
- TypeScript: use `readonly` properties for Value Objects; leverage discriminated unions for Domain Events
- Python: use frozen dataclasses or Pydantic models for Value Objects; `@property` for controlled access
