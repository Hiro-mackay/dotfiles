---
name: typescript-principles
description: TypeScript design principles for type safety and async patterns. Use when writing, reviewing, or designing TypeScript code.
user-invocable: false
---

# TypeScript Design Principles

## Type Safety
- No `any` -- use `unknown` with type guards
- No `as T` -- use type guards or `z.parse()`
- No non-null assertions (`!`) without justification
- `as const` for literals, `satisfies` for schema-checked objects
- Discriminated unions over complex conditionals; exhaustive switch with `never`
- `readonly` for immutable data (props, store state)
- Zod/Valibot validation at system boundaries
- `catch`: narrow `unknown` with `instanceof Error` before property access

## Async & Performance
- All `async` functions have error handling
- No floating promises (missing `await` or `void`)
- Sequential `await` -> `Promise.all`/`Promise.allSettled` when independent
- Accept `AbortSignal` for fetch or heavy I/O

## Imports & Security
- No circular dependencies or barrel file bloat
- No XSS via `dangerouslySetInnerHTML`; sanitize user input
- Watch for prototype pollution
