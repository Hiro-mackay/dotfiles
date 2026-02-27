---
paths:
  - "**/*.{tsx,jsx}"
---

# React Design Principles

## Server Components & Actions (skip if no framework)
- `'use client'` at leaf components only -- maximize Server Component usage
- Server Components for data fetching, not `useEffect`
- `action` prop + `useActionState` for forms, not `useState`/`onSubmit`
- `useFormStatus` / `isPending` for loading UI
- `useOptimistic` for instant UI feedback during Server Action execution
- Server Actions are public endpoints -- validate input (Zod), authenticate, authorize inside EVERY action
- `server-only` import on modules with secrets/DB access -- prevents accidental Client Component import
- `after()` for non-blocking operations (logging, analytics, cache invalidation)

## Waterfall Elimination (CRITICAL)
- Defer `await` into the branch where actually used -- early return before fetch
- `Promise.all([...])` for independent fetches in a single component -- never sequential awaits when requests do not depend on each other's results
- Suspense boundaries to stream content -- do NOT block entire layout for one data fetch
- RSC composition: move async work into sibling/child components for parallel fetching
- Parent awaiting data that only a child needs = waterfall -- push fetch down to child

## Bundle Optimization (CRITICAL)
- Direct imports from source, NOT barrel files (`lucide-react`, `@mui/*`, `react-icons`, `@radix-ui/*`)
- `next/dynamic` with `{ ssr: false }` for heavy components (editors, charts, maps)
- Defer non-critical third-party (analytics, error tracking) until after hydration
- Preload heavy bundles on hover/focus for perceived speed
- Conditional `import()` with `typeof window !== 'undefined'` guard for client-only modules
- Next.js 13.5+: prefer `optimizePackageImports` in config over manual direct imports

## Server-Side Performance (HIGH) (skip if no framework)
- `React.cache()` for per-request deduplication (auth checks, DB queries) -- NOT for `fetch` in Next.js (already deduped)
- `React.cache()` uses `Object.is` equality: inline objects/arrays as arguments ALWAYS miss cache. Pass primitives (`userId`) or stable module-level references, never `{ id }` literals
- Minimize RSC -> client serialization: pick only the fields client components actually use, not full DB/ORM objects. Server-side transformation that reduces payload size is encouraged
- Parallel fetching via component composition, not sequential awaits in parent
- LRU cache for cross-request data shared across sequential user actions

## Data Fetching
- **Never** raw `useEffect` + `fetch` -- use a query library (TanStack Query, SWR, etc.)
- Layered architecture:
  1. **API layer**: pure functions returning `Promise` -- no React, no hooks
  2. **Custom hooks**: thin query library wrappers -- one hook per use case
  3. **Components**: call hooks, render data -- no fetch logic
- Mutations: `useMutation` or equivalent, not `useEffect` + `fetch`
- Server Components: direct `async/await` -- no query library needed
- SWR/TanStack Query for automatic request deduplication across component instances

## Re-render Optimization (MEDIUM)
- Derive state during render, NOT via `useEffect` -- no redundant state
- Functional `setState(curr => ...)` for stable callbacks and no stale closures
- Lazy state init: `useState(() => expensive())` for costly initial values
- Defer reads: do NOT subscribe to `searchParams`/`localStorage` if only used in callbacks -- read on demand
- `startTransition` for non-urgent updates (scroll tracking, search filtering)
- `useRef` for transient values that change frequently but do NOT need re-render (mouse position, timers)
- Extract expensive computation into `memo()` child components -- parent early return skips child entirely
- Hoist default non-primitive props outside `memo()` components (`const NOOP = () => {}`)
- Narrow effect dependencies: use primitive values (`user.id`), not objects (`user`)
- Subscribe to derived booleans (`isMobile`), not raw continuous values (`width`)
- `useMemo` only for measurable gains; skip for simple primitive expressions (`a || b`)
- React Compiler: if enabled, remove manual `useMemo`/`useCallback`; without it: only for measurable gains

## Rendering Performance (MEDIUM)
- `content-visibility: auto` + `contain-intrinsic-size` for long lists (skip layout/paint for off-screen items)
- Hoist static JSX elements outside components to avoid re-creation on every render
- Ternary (`? :`) for conditional render, NOT `&&` (prevents rendering `0` / `NaN` as text)
- `<Activity mode="visible"|"hidden">` for expensive togglable components (preserves state/DOM) (experimental)
- Hydration without flicker: inline `<script>` for client-only data (theme, locale) before React hydrates
- `suppressHydrationWarning` for expected mismatches only (timestamps, random IDs) -- NOT to hide bugs
- Animate div wrapper around SVG, not SVG directly (hardware acceleration)
- `useTransition` with `isPending` over manual `useState` loading states

## Component Design
- Under 150 lines, single responsibility
- Composition over prop drilling (children, render props, compound pattern)
- Colocate state; extract custom hooks for reusable logic

## Project Structure
- **Package by feature**, not by type: `features/auth/` over `components/`, `hooks/`, `api/`
- Each feature directory colocates its components, hooks, API layer, types, and tests
- Shared UI primitives (Button, Modal, etc.) live in `components/` or `ui/`
- Cross-feature code goes in `lib/` or `utils/` -- keep it minimal

## Side Effects
- Event handlers for user actions; Effects only for external system sync (WebSocket, DOM listeners, timers)
- `useSyncExternalStore` for external store sync (browser APIs, third-party stores) -- prevents tearing; prefer over `useEffect` subscription
- `useEffect` is a synchronization mechanism -- NOT for user-triggered logic
- Data fetching MUST NOT be in raw `useEffect` + `fetch`/`axios` (see Data Fetching)
- Async effects: cleanup flag or AbortController
- `Suspense` for loading, Error Boundaries for errors -- not `if (loading)`
- App-wide init: module-level guard (`let didInit = false`), NOT `useEffect([])` alone (re-runs on remount in dev)
- Passive event listeners (`{ passive: true }`) for scroll/touch when `preventDefault()` is not needed

## Hooks
- No conditional/nested hooks; dependencies complete and minimal
- `useEffect` cleanup for subscriptions, timers, AbortController
- `use()` for Promises/Context in conditionals/loops (React 19+ only)
- `useEffectEvent` for stable callback refs in effects -- prevents re-subscription on callback changes (React 19+)
- Custom hooks: `use` prefix, one concern

## State
- Lift only as high as needed; Context for low-frequency, external store for high-frequency
- Derive from existing state/props -- no redundant state
- Forms: `useActionState` or form libraries
- Immutable updates: `.toSorted()`, `.toReversed()`, `.with()` -- NEVER `.sort()` on props/state
