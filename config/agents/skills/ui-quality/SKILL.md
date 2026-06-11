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

## Design Foundations
- Affordance: interactive elements MUST look interactive. Flat text that's clickable = broken
- Jakob's Law: users expect your site to work like sites they already know. Follow platform conventions before innovating
- Fitts's Law: important targets large and close to cursor/thumb. Why touch targets are 44px
- Hick's Law: decision time grows with options. Why nav ≤ 7 items, choices ≤ 4
- Aesthetic-usability: polished UI is perceived as more usable. Visual quality IS functional quality
- Peak-end rule: users judge experience by its peak moment and ending. Nail confirmations and completion screens

## Accessibility
- Semantic HTML: `<button>` not `<div onclick>`, `<nav>`, `<main>`, `<article>`, proper heading hierarchy (h1→h2→h3, no skips)
- Contrast: 4.5:1 for text, 3:1 for large text and UI components. Placeholders need 4.5:1 too
- Keyboard: every interactive element reachable via Tab. `focus-visible` for keyboard-only focus rings. Never `outline: none` without replacement
- ARIA: `aria-label` on icon buttons, `aria-describedby` linking errors to fields, `role` on custom controls
- Images: `alt` describes information ("Revenue +40% in Q4"), not the image ("Chart"). `alt=""` for decorative
- Zoom: never `user-scalable=no`. Layout MUST work at 200% zoom
- Touch targets: 44px minimum. Use padding or pseudo-elements to expand hit area beyond visual size
- Reduced motion: `prefers-reduced-motion` (see `visual-design` for motion guidelines)

## Responsive Design
- Mobile-first: base styles for mobile, `min-width` queries to add complexity
- Content-driven breakpoints: resize until design breaks, add breakpoint there. 3 breakpoints usually suffice
- Input detection: `@media (pointer: coarse)` for touch, `(hover: hover)` for mouse. Don't rely on hover for functionality
- Safe areas: `env(safe-area-inset-*)` with `viewport-fit=cover` for notched devices
- Responsive images: see `web-performance` for srcset, sizes, and picture element guidelines
- Navigation: hamburger on mobile → compact on tablet → full on desktop
- Tables: transform to card layout on mobile with `data-label` attributes

## Interactive States
- Design ALL 8 states: default, hover, focus, active, disabled, loading, error, success
- Focus and hover are different. Keyboard users never see hover states
- Focus ring: 2-3px, high contrast (3:1), offset from element, consistent across all controls
- Disabled: reduced opacity + `pointer-events: none` + `aria-disabled="true"`

## Form Design
- Visible `<label>` always. Placeholders are NOT labels (they disappear on input)
- Validate on blur, not per-keystroke. Exception: password strength
- Errors below fields with `aria-describedby`. Inline, near the field, not in a banner
- Format hints in placeholder or help text, not in label

## Error States
- Answer: what happened, why, how to fix. "Email needs an @ symbol. Try: name@example.com"
- Don't blame user: "Please enter a date in MM/DD/YYYY format" not "You entered an invalid date"
- Network errors: clear message + retry button + offline indicator
- Provide undo over confirmation dialogs. Users click through confirmations mindlessly

## Empty States
- Onboarding moment, not dead end: acknowledge, explain value, provide clear action
- "No projects yet. Create your first project to get started." not "No items"

## Loading States
- Skeleton screens over spinners -- preview content shape, feel faster
- Optimistic UI for low-stakes actions (likes, follows). Not for payments or destructive actions
- Set expectations for long waits: "This usually takes 30-60 seconds"
- Show progress when possible. Offer cancel for long operations

## UX Writing
- Button labels: verb + object ("Save changes", "Delete project"). Never "OK", "Submit", "Yes/No"
- Destructive buttons: name the destruction + count ("Delete 5 items")
- Consistency: pick one term and stick with it (Delete not Remove/Trash, Settings not Preferences/Options)
- One message, said once. Don't repeat heading in intro. Don't explain a clear button
- i18n: German +30%, French +20%. Keep numbers separate. Use full sentences as translation units

## Navigation & Information Architecture
- Primary nav: 5-7 items max. More = cognitive overload. Group under categories if needed
- Current location: always visible (active state, breadcrumbs). User should never ask "where am I?"
- Predictable placement: logo top-left (home link), primary actions top-right, nav left or top
- Deep hierarchies (> 3 levels): flatten or use breadcrumbs + contextual sidebar. Never rely on back button alone
- Search: provide when content exceeds ~20 items or spans multiple categories

## Progressive Disclosure
- Show only what's needed at each step. Details on demand, not upfront
- Wizards: for linear multi-step processes (3-7 steps). Show progress, allow back navigation
- Accordion/expandable: for reference content users scan selectively. One open at a time or independent
- Inline expansion: "Show more" / "Advanced options" for power-user settings. Hide complexity, not functionality
- Decision: if > 80% of users need it, show it. If < 20%, hide behind disclosure. Middle ground = contextual reveal

## Modals & Overlays
- Use `<dialog>` with `.showModal()` for native focus trapping and Escape handling
- `inert` attribute on background content when modal is open
- Popover API for tooltips, dropdowns, non-modal overlays (light-dismiss, proper stacking)
- Dropdown positioning: `position: fixed` or top layer to escape `overflow: hidden`. Never `position: absolute` inside clipped containers
