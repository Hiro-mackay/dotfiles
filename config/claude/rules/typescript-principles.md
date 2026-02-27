---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript Design Principles

## Type Safety
- No `any` -- use `unknown` with type guards or narrowing (Escape Hatches below for rare exceptions)
- No `as T` assertions -- use type guards, `z.parse()`, or `satisfies`
- No non-null assertions (`!`) without justification
- `as const` for literal types, `satisfies` for compile-time validation without widening
- `catch`: narrow `unknown` with `instanceof Error` before property access
- Zod/Valibot validation at system boundaries (API responses, user input, env vars)
- Prefer ECMAScript features over TS-only features: union types over `enum`, modules over `namespace`
- No object wrapper types -- `string` not `String`, `number` not `Number`, `boolean` not `Boolean`

## Type Design
- Types MUST represent only valid states -- invalid combinations MUST be unrepresentable
- Prefer unions of interfaces over interfaces with union properties
- Push `null`/`undefined` to the perimeter -- inner functions receive validated data
- `null` for intentionally absent values from external sources (DB, API); `undefined` for optional/not-provided -- do not mix
- Do NOT embed `| null` or `| undefined` in reusable type aliases -- callers compose nullability at the usage site
- Discriminated unions with exhaustive `switch` + `never` default for completeness
- Prefer string literal unions over bare `string` (e.g., `"pending" | "active"`)
- Structural typing: two types with the same shape are interchangeable -- use branded types (`UserId` vs `OrderId`) to make invalid substitutions a compile error
- Name types in domain language -- `Temperature`, not `NumberWithUnit`
- Avoid optional properties when a value is always present in a given state -- use separate types per state
- Limit repeated parameters of the same type -- use named objects instead
- Be liberal in what you accept, strict in what you produce -- input params accept `readonly T[]`, return types are concrete
- DRY types: derive with `Pick`, `Omit`, `Partial`, `ReturnType`, `typeof` -- one source of truth
- Prefer `Record<K, V>` or mapped types over index signatures (`{[key: string]: T}`)
- Prefer imprecise types to inaccurate types -- a `string` param accepting some invalid values is better than a complex template literal that rejects valid inputs

## Type Inference & Narrowing
- Let TypeScript infer when the type is obvious -- annotate return types and public API boundaries
- `satisfies` to verify inferred types match an expected shape without widening
- Narrow with `in`, `instanceof`, discriminant checks -- avoid user-defined type guards unless necessary
- After narrowing, use the narrowed variable consistently -- do NOT fall back to the original unnarrowed alias
- Build objects all at once instead of incrementally adding properties
- `readonly` for data that MUST NOT mutate (props, config, store state, function params that should not be modified)
- Prefer `type` for unions, intersections, mapped types; `interface` for extensible object shapes and better compiler caching
- Do NOT reuse a variable for different types -- create a new `const` with a descriptive name
- Extracting a callback to a named function can lose generic type context -- inline when types depend on surrounding generics
- Use functional constructs (`map`, `filter`, `flatMap`) over imperative loops -- types flow through without manual annotation

## Generics
- Think of generics as functions between types -- input type -> output type
- Avoid unnecessary type parameters -- if a param appears only once, remove it
- Constrain type parameters with `extends` when possible (e.g., `<T extends HTMLElement>`) -- prevents unintended inference and improves internal safety
- Prefer conditional types over function overloads when the output type is a pure function of the input type; use overloads when call-site narrowing or runtime dispatch is the primary concern
- `Record<K, V>` to enforce exhaustive handling of a union -- compiler errors when a new variant is added
- Use optional `never` properties to model exclusive-or types (`{ a: string; b?: never } | { a?: never; b: number }`)
- Write type-level tests for complex generics -- use `expectType` or `tsd` to verify type behavior

## Async & Concurrency
- All `async` functions MUST have error handling
- No floating promises (missing `await` or `void`)
- Sequential `await` -> `Promise.all`/`Promise.allSettled` when independent
- Accept `AbortSignal` for fetch or long-running I/O

## Imports & Security
- No circular dependencies or barrel file re-export bloat
- Use `import type` / `export type` for type-only imports -- prevents circular reference issues and improves build performance
- No XSS via innerHTML -- sanitize user input
- Watch for prototype pollution in object spread and `Object.assign`

## Escape Hatches
When `any` or assertions are unavoidable:
- Use the narrowest possible scope -- `any` in a local variable, not a function signature
- Prefer precise variants: `unknown[]` over `any[]`, `Record<string, unknown>` over `any`, `(...args: unknown[]) => unknown` over `Function`
- Hide unsafe assertions inside well-typed wrapper functions -- callers see a safe API, unsafety is contained and documented

## Runtime Patterns
- `Object.keys()` returns `string[]`, not `(keyof T)[]` -- wrap in a typed helper or use `Map<K, V>` when key types matter
- `Object.entries()` values are typed but keys are `string` -- same caveat
- Covariant array trap: `Dog[]` assignable to `Animal[]` can cause runtime errors via mutation -- accept `readonly Animal[]` at API boundaries to prevent callers from pushing incompatible subtypes

## Module & Library Design
- Export all types that appear in public API signatures -- consumers MUST NOT need to extract them
- Put `@types/*` in `devDependencies`, not `dependencies`
- Mirror types (redefine minimal shapes) to avoid heavy transitive dependency chains

## Compiler Performance
- Prefer interfaces over intersections (`A & B`) for object types -- interfaces are cached, intersections are recomputed
- Avoid deeply nested conditional types -- flatten or use codegen for complex type mappings
- Use `@ts-expect-error` over `@ts-ignore` -- the former errors when the suppression becomes unnecessary
