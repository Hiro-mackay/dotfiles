---
name: module-design
description: Module boundary design covering coupling, cohesion, dependency direction, and interface contracts. Applies when deciding how to split code into modules, packages, or services, or when reasoning about dependency relationships.
---

# Module Design Principles

## Cohesion & Coupling
- High cohesion: a module does one thing well. Everything inside relates to the same concern
- Low coupling: modules interact through narrow, stable interfaces. Internal changes don't leak
- Change together = belong together. If A always changes when B changes, they're one module
- Cohesion test: can you describe the module's purpose in one sentence without "and"?
- Coupling test: can you replace this module's internals without changing its callers?

## Dependency Direction
- Depend toward stability: volatile modules depend on stable ones, never the reverse
- Stable: rarely changes, many dependents (domain model, core interfaces)
- Volatile: changes often, few dependents (UI, adapters, configuration)
- Dependency Inversion: high-level policy MUST NOT depend on low-level detail. Both depend on abstractions
- The interface belongs to the CONSUMER, not the provider. Define interfaces where they're needed

## Boundary Detection
- Split along change frequency: code that changes weekly vs code that changes monthly = different modules
- Split along team ownership: different teams = different modules with explicit contracts
- Split along deployment: if A can deploy without B, they're separate modules
- Do NOT split along technical layers alone (controller/service/repo). Split by domain capability
- Premature splitting is as harmful as premature abstraction -- merge until the boundary is obvious

## Interface Design
- Postel's Law: be liberal in what you accept, conservative in what you produce
- Principle of Least Surprise: behave as callers expect. Name reveals behavior
- Narrow interfaces: expose the minimum necessary. Every public API is a commitment
- Complete interfaces: callers should not need to know internals to use the API correctly
- Error contracts: document what errors can occur and what the caller should do about each

## Circular Dependency Resolution
- Circular dependencies signal a missing abstraction or incorrect boundary
- Resolution strategies:
  1. Extract shared concept into a new module that both depend on
  2. Invert one dependency through an interface (dependency inversion)
  3. Replace direct call with event/message (async decoupling)
  4. Merge the modules -- they may actually be one concern
- Never resolve with runtime tricks (lazy loading, service locator) -- fix the design

## Package/Module Sizing
- Too small: explosion of tiny modules with high coordination cost, import ceremony
- Too large: monolithic modules that change for unrelated reasons
- Right size: one team can own it, one sentence describes it, changes are usually internal
- Monorepo modules: share build tooling, but maintain clear dependency boundaries
- Microservice boundary: only when independent deployment and scaling are required. Start as a module within a monolith

## Stability & Volatility
- Stable components: abstract, depended upon, hard to change (changing breaks dependents)
- Volatile components: concrete, few dependents, easy to change
- The Stable Abstractions Principle: stable modules should be abstract (interfaces/types). Volatile modules should be concrete (implementations)
- If a module is both stable AND concrete, it's a pain point -- add abstractions or reduce dependents
