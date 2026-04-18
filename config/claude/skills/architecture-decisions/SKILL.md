---
name: architecture-decisions
description: Trade-off analysis, complexity management, reversibility thinking, ADR format, and build-vs-buy decisions. Applies when making architectural choices, evaluating alternatives, assessing whether an abstraction or technology adds justified value, or documenting technical decisions.
---

# Architecture Decision Principles

## Trade-off Analysis
- No "best" solution exists -- only trade-offs in context. Make trade-offs explicit before choosing
- Evaluate on 4 axes: complexity, performance, maintainability, operational cost
- State what you're GAINING and what you're GIVING UP. If you can't name the downside, you don't understand the trade-off
- Prefer reversible decisions over optimal ones. Optimize for learning speed, not for being right the first time
- Constraints are not obstacles -- they're design inputs. Embrace them early

## Decision Types (Bezos Type 1/Type 2)
- **Type 1 (irreversible)**: database choice, public API contract, data model for persisted data, language/framework for core system
  - Invest in analysis. Prototype. Get multiple perspectives. Sleep on it
- **Type 2 (reversible)**: internal API shape, library choice, folder structure, naming conventions
  - Decide fast. Prefer convention. Course-correct later
- When unsure which type: ask "what's the cost of changing this in 6 months?"

## Architecture Decision Records (ADR)
- Document significant decisions, not every choice
- Format: Title, Status, Context, Decision, Consequences
- Context: what forces are at play? What constraints exist?
- Decision: what was chosen and WHY (not just what)
- Consequences: what becomes easier, what becomes harder
- Record rejected alternatives with reasons -- future readers need to know why NOT

## Build vs Buy vs Adopt
- **Build** when: core differentiator, unique constraints, no adequate solution exists
- **Buy/SaaS** when: commodity problem, time-to-market matters, operational burden is acceptable
- **Adopt (OSS)** when: active community, escape hatch exists, team can maintain if abandoned
- Migration cost is always higher than estimated -- factor 2-3x

## Deferring Decisions
- "Not deciding now" is a valid decision when information is insufficient
- Design for replaceability: if you can swap component X later, you don't need to choose X now
- Use interfaces/abstractions at decision boundaries -- but ONLY at decision boundaries (not everywhere)
- Spike/prototype to reduce uncertainty before committing

## Complexity Management
- Essential complexity: inherent in the problem domain. Cannot be removed, only managed
- Accidental complexity: introduced by our tools, abstractions, and decisions. CAN and SHOULD be removed
- Before adding complexity, ask: "Is this solving a real problem or a hypothetical one?"
- Every layer of abstraction adds understanding cost. Justified ONLY when it simplifies more than it complicates
- Direct code is easier to debug, trace, and modify than indirect code

## YAGNI at Every Scale
- Function level: don't add parameters "in case someone needs them"
- Module level: don't create abstractions until the third use case proves the pattern
- System level: don't add message queues, caches, or microservices until measured need
- Code that doesn't exist has no bugs, needs no tests, and requires no documentation
- Removing code is more valuable than adding code
- Every dependency is a liability. Regularly audit: "Do we still need this?"

## Choose Boring Technology
- Each team has a limited innovation budget (roughly 3 novel technologies at a time)
- Boring technology: well-understood failure modes, abundant documentation, easy hiring
- Novel technology: unknown failure modes, sparse expertise, excitement-driven adoption
- Innovation should go into the product, not the infrastructure
- Follow framework conventions unless there's a measured reason to deviate

## Simplicity Litmus Tests
- Can a new team member understand this in 15 minutes?
- Can you explain the architecture in one whiteboard diagram?
- If you removed this component, what would break? If nothing, remove it
- Is this the simplest solution that solves the actual (not hypothetical) problem?
