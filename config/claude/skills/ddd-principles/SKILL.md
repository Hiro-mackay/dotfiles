---
name: ddd-principles
description: Domain-Driven Design principles for modeling complex domains. Use when designing domain models, defining bounded contexts, or structuring aggregates and repositories.
user-invocable: false
---

# Domain-Driven Design Principles

## Core Concepts
- **Ubiquitous Language**: Use domain terms in code, docs, and conversation. No translation layer between business and code.
- **Bounded Context**: Each context has its own model. Same term can mean different things across contexts.
- **Context Map**: Define relationships between contexts (Shared Kernel, Anti-Corruption Layer, Conformist, etc.)

## Building Blocks
- **Entity**: Has identity, lifecycle matters. Compare by ID, not attributes.
- **Value Object**: Immutable, no identity. Compare by attributes. Prefer over entities when possible.
- **Aggregate**: Consistency boundary. One root entity controls access. Reference other aggregates by ID only.
- **Repository**: Collection-like interface for aggregate persistence. One repository per aggregate root.
- **Domain Event**: Record of something that happened. Past tense naming (OrderPlaced, PaymentReceived).
- **Domain Service**: Stateless operation that doesn't belong to any entity or value object.

## Design Rules
- One transaction per aggregate -- no cross-aggregate transactions
- Keep aggregates small -- only include what must be immediately consistent
- Reference other aggregates by ID, not direct object reference
- Push business logic into domain objects, not services or controllers
- Application layer orchestrates; domain layer decides
- Prefer behavior methods over getters -- follow language conventions (e.g., Go uses exported fields)
