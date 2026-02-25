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

## Project Structure
- **Package by feature**, not by type: `features/auth/` over `components/`, `hooks/`, `api/`
- Each feature directory colocates its components, hooks, API layer, types, and tests
- Shared UI primitives (Button, Modal, etc.) live in `components/` or `ui/`
- Cross-feature code goes in `lib/` or `utils/` -- keep it minimal

## Component Design
- Under 150 lines, single responsibility
- Composition over prop drilling (children, render props, compound pattern)
- Colocate state; extract custom hooks for reusable logic

## Side Effects
- Event handlers for user actions; Effects only for external system sync (WebSocket, DOM listeners, timers)
- `useEffect` is NOT for logic -- it is a synchronization mechanism
- User-triggered logic must NOT be in `useEffect`
- Data fetching must NOT be in raw `useEffect` + `fetch`/`axios` (see Data Fetching)
- Async effects: cleanup flag or AbortController
- `Suspense` for loading, Error Boundaries for errors -- not `if (loading)`

## Data Fetching
- **Never** raw `useEffect` + `fetch` -- use a query library (TanStack Query, SWR, etc.)
- Layered architecture:
  1. **API layer**: pure functions returning `Promise` -- no React, no hooks
  2. **Custom hooks**: thin query library wrappers -- one hook per use case
  3. **Components**: call hooks, render data -- no fetch logic
- Mutations: `useMutation` or equivalent, not `useEffect` + `fetch`
- Server Components: direct `async/await` is fine -- no query library needed

## Hooks
- No conditional/nested hooks; dependencies complete and minimal
- `useEffect` cleanup for subscriptions, timers, AbortController
- React Compiler: remove manual `useMemo`/`useCallback`; without it: only for measurable gains
- `use()` for Promises/Context in conditionals/loops (React 19+ only)
- Custom hooks: `use` prefix, one concern

## State
- Lift only as high as needed; Context for low-frequency, external store for high-frequency
- Derive from existing state/props -- no redundant state
- Forms: `useActionState` or form libraries
