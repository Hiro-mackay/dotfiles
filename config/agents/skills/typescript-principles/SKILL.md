---
name: typescript-principles
description: TypeScript design principles covering type safety, generics, async patterns, runtime validation (Zod/Valibot), and avoidance of any/as escape hatches. Apply when reading, writing, or reviewing .ts or .tsx files.
user-invocable: false
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript Design Principles

These are the calls you would otherwise get wrong. Idiomatic TypeScript and anything `tsc` or the project's ESLint config already flags is deliberately absent.

## `any` and assertions
- No `any`, no `as T`, no non-null `!`. Reach for `unknown` plus narrowing, a `satisfies` check, or a schema parse
- When an assertion is genuinely unavoidable: narrowest possible scope (a local, never a signature), the precise variant (`unknown[]` not `any[]`, `Record<string, unknown>` not `any`), and hidden inside a well-typed wrapper so callers see a safe API
- `@ts-expect-error`, never `@ts-ignore` -- the former starts failing once the suppression stops being needed

## Type design
- Types represent only valid states; invalid combinations are unrepresentable. Separate types per state beat one type whose optional properties are only sometimes set
- `null` for values intentionally absent from outside (DB, API), `undefined` for not-provided. Do not mix them, and do not bake `| null` or `| undefined` into a reusable alias -- callers compose nullability where they use it
- Push nullability to the perimeter so inner functions receive data that is already validated
- Branded types (`UserId` vs `OrderId`) where structural typing would let the wrong value through
- Prefer an imprecise type to an inaccurate one: a `string` that admits some invalid values beats a template literal type that rejects valid ones
- Drop a type parameter that appears only once -- it isn't doing generic work
- Union types over `enum`, modules over `namespace`
- `interface` for object shapes, `type` for unions and mapped types. Interfaces are cached by the compiler; an intersection (`A & B`) is recomputed at every use

## Boundaries
- Parse with Zod/Valibot at system boundaries only -- API responses, user input, env vars. Internal code trusts its own types
- Accept `readonly T[]` at API boundaries: a `Dog[]` passed as `Animal[]` lets the callee push the wrong element type into the caller's array
- Accept `AbortSignal` on fetch and long-running I/O

## Async
- Independent awaits go under `Promise.all` / `Promise.allSettled`. Sequential `await` is for genuine dependencies
- No floating promises: every call returning one is awaited, returned, or explicitly `void`-ed. Plain `eslint:recommended` does not catch this -- only the type-checked typescript-eslint config does, and most projects do not enable it

## Modules
- No circular dependencies, and no barrel file re-exporting the world -- both cost build time and hide the real graph
