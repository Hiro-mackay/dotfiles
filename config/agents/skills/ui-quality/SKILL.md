---
name: ui-quality
description: UI implementation quality covering accessibility, responsive design, interactive states, error/empty/loading states, and UX writing. Applies when implementing UI components, handling edge cases, or improving interface resilience and usability.
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.html"
---

# UI Quality Principles

The specifics that get dropped when the happy path is working. Named usability laws are deliberately absent -- what follows is what they imply.

## Accessibility
- Semantic elements: `<button>`, never `<div onClick>`. `<nav>`, `<main>`, `<article>`, and a heading hierarchy with no skipped levels
- Contrast 4.5:1 for text and placeholders, 3:1 for large text and UI components
- Every interactive element is reachable by Tab. `focus-visible` for the keyboard ring; `outline: none` only ever with a replacement
- `aria-label` on icon-only buttons, `aria-describedby` linking an error to its field, `role` on custom controls
- `alt` carries the information ("Revenue +40% in Q4"), not the medium ("Chart"). `alt=""` when decorative
- Never `user-scalable=no`; the layout has to survive 200% zoom
- 44px minimum touch targets -- expand the hit area with padding or a pseudo-element rather than the visual size
- Honor `prefers-reduced-motion` (motion guidelines: `visual-design`)

## States
- Eight states, all designed: default, hover, focus, active, disabled, loading, error, success
- Focus is not hover. Keyboard users never see a hover state, so anything only reachable through hover is unreachable
- Focus ring 2-3px at 3:1 contrast, offset from the element, identical across every control
- Disabled means reduced opacity **and** `pointer-events: none` **and** `aria-disabled="true"`
- Anything clickable looks clickable. Flat text that happens to be a link is a bug

## Forms
- A visible `<label>`, always. Placeholders vanish on input, so they are not labels -- format hints go in the placeholder or help text
- Validate on blur, not per keystroke (password strength excepted). Errors sit below the field, wired with `aria-describedby`, never collected into a banner

## Error, empty, loading
- An error says what happened, why, and how to fix it: "Email needs an @ symbol. Try: name@example.com". It does not assign blame to the user
- Network failures get a message, a retry, and an offline indicator
- Prefer undo to a confirmation dialog. Confirmations get clicked through without reading
- An empty state is an onboarding moment: acknowledge, say what the thing is for, give the action. "No projects yet. Create your first project to get started."
- Skeletons over spinners. Optimistic UI for low-stakes actions only -- never payments or deletions. Past a few seconds, say how long it usually takes and offer cancel
- Confirmation and completion screens carry disproportionate weight in how the whole flow is remembered. Do not leave them as an afterthought

## Words
- Buttons are verb + object: "Save changes", "Delete project". Never "OK", "Submit", "Yes"
- A destructive button names the destruction and the count: "Delete 5 items"
- One term per concept, forever: Delete, not Remove or Trash. Settings, not Preferences or Options
- Say it once. Don't restate the heading in the intro or explain a button that explains itself
- Translations expand -- German by ~30%, French by ~20%. Keep numbers out of the string and translate whole sentences, not fragments

## Structure
- Follow the platform's existing convention before inventing one. Users arrive with expectations built elsewhere, and a novel interaction spends attention that the actual task needed
- Predictable placement: logo top-left linking home, primary actions top-right, navigation left or top
- Primary navigation stays at 5-7 items; group into categories beyond that. Current location always visible via active state or breadcrumbs
- More than three levels deep, flatten or add breadcrumbs plus a contextual sidebar. The back button is not navigation
- Offer search once content passes roughly 20 items or spans categories
- Show it if more than ~80% of users need it, hide it behind disclosure if fewer than ~20%, reveal it contextually in between. Wizards for linear flows of 3-7 steps, with progress and working back navigation

## Responsive and overlays
- Mobile-first base styles with `min-width` queries. Put breakpoints where the design actually breaks, not at device widths -- three usually covers it
- `@media (pointer: coarse)` and `(hover: hover)` for input capability. Nothing functional may depend on hover
- `env(safe-area-inset-*)` with `viewport-fit=cover` on notched devices. Tables become cards on mobile via `data-label`
- `<dialog>` with `.showModal()` for real focus trapping and Escape handling, plus `inert` on the background. Popover API for tooltips and dropdowns
- Position dropdowns with `position: fixed` or the top layer. `position: absolute` inside a clipped container will be cut off
- Responsive images (srcset, sizes, picture): `web-performance` skill
