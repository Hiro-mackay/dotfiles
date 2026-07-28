---
name: react-principles
description: React component design principles covering hooks, rendering, server components and actions, state management, accessibility, and common anti-patterns. Apply when reading, writing, or reviewing .tsx or .jsx files.
user-invocable: false
paths:
  - "**/*.{tsx,jsx}"
---

# React Design Principles

These are the calls you would otherwise get wrong. Idiomatic React and anything the ESLint hooks plugin already flags is deliberately absent.

## Server Components and Actions (skip if no framework)
- `'use client'` on leaf components only -- every boundary pushed upward drags its whole subtree onto the client
- Server Actions are public endpoints: validate input, authenticate, and authorize inside every one of them, not in the component that calls it
- `server-only` import on any module touching secrets or the database, so a Client Component importing it fails the build instead of shipping it
- `React.cache()` for per-request deduplication of auth checks and DB queries -- not for `fetch` in Next.js, which is deduped already. It compares arguments with `Object.is`, so an inline `{ id }` literal never hits: pass `userId` or a module-level reference
- Serialize only the fields the client renders across the RSC boundary, not whole ORM objects

## Fetching and waterfalls
- Never raw `useEffect` + `fetch`, for reads or mutations. A query library (TanStack Query, SWR) or a Server Component owns this
- Three layers kept apart: API functions returning promises with no React in them, one thin hook per use case wrapping the query library, components that call hooks and render
- A parent awaiting data only its child needs is a waterfall. Push the fetch down, run independent fetches under `Promise.all`, and give each its own Suspense boundary so one slow fetch doesn't block the layout

## Effects
- Event handlers for user actions. Effects only for synchronizing with an external system -- sockets, DOM listeners, timers. If a user triggered it, it is not an effect
- Derive during render. State computable from other state or props is redundant state
- `useSyncExternalStore` for external stores and browser APIs rather than a `useEffect` subscription -- it prevents tearing
- Every effect cleans up: subscriptions, timers, and an AbortController or cancelled flag for anything async
- Effect dependencies are primitives (`user.id`, `isMobile`), not objects or continuously changing values
- App-wide initialization goes behind a module-level guard, not `useEffect(..., [])` alone -- that re-runs on remount in dev
- `Suspense` for loading and an Error Boundary for failure, not `if (loading)` / `if (error)` branches

## Re-renders and bundle
- If React Compiler is on, delete manual `useMemo` / `useCallback`. Without it, add them only for a gain you measured -- never for `a || b`
- Ternary for conditional rendering, never `&&`: `0` and `NaN` render as text
- `suppressHydrationWarning` only for mismatches you expect (timestamps, random IDs), never to silence a real one
- Import from source, not barrel files (`lucide-react`, `@mui/*`, `react-icons`, `@radix-ui/*`); on Next.js 13.5+ set `optimizePackageImports` instead of doing it by hand
- `next/dynamic` with `{ ssr: false }` for editors, charts, and maps; defer analytics and error tracking until after hydration

## State and structure
- Lift state only as high as it is used. Context for low-frequency values, an external store for high-frequency ones
- Immutable updates only: `.toSorted()`, `.toReversed()`, `.with()`. Never `.sort()` on props or state
- Package by feature (`features/auth/`), not by type. Each feature colocates its components, hooks, API layer, types, and tests; shared primitives live in `ui/`, cross-feature code in `lib/` stays small
- Components under 150 lines with one responsibility. Reach for composition (children, render props) before prop drilling
