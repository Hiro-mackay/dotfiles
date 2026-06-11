---
name: visual-design
description: Visual design principles covering typography, color, layout, spacing, motion, and AI anti-patterns. Applies when building UI components, designing pages, or reviewing visual quality of interfaces.
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.html"
  - "**/tailwind.config.*"
---

# Visual Design Principles

## Typography
- Modular type scale with 5 sizes: xs (caption), sm (secondary), base (body), lg (subheading), xl+ (headline). Pick a ratio (1.25, 1.333, 1.5) and commit
- Pair fonts by contrast: serif + sans, geometric + humanist, condensed display + wide body. Never pair similar-but-not-identical fonts
- One font family in multiple weights often beats two competing typefaces
- Vertical rhythm: line-height is the base unit for all vertical spacing
- Fluid type (`clamp()`) for headings on content pages. Fixed `rem` scales for app UI and body text
- `max-width: 65ch` for readable measure. Increase line-height for light-on-dark text (+0.05-0.1)
- Avoid: Inter, Roboto, Arial, Open Sans as defaults. Monospace as shorthand for "technical"

## Color
- Use OKLCH for perceptually uniform palettes. Reduce chroma as lightness approaches extremes
- Tint all neutrals toward brand hue (chroma ~0.01). Pure gray looks dead
- 60-30-10 rule by visual weight: 60% neutral, 30% secondary, 10% accent. Accent works because it's rare
- Palette: 1 primary (3-5 shades), neutral scale (9-11 shades), 4 semantic colors (success/error/warning/info)
- Never pure black (#000) or pure white (#fff) -- always tint
- Dark mode is NOT inverted light mode: lighter surfaces for depth (no shadows), desaturate accents, reduce text font weight
- Semantic tokens (`--color-primary`) over primitive tokens (`--blue-500`). Redefine semantic layer for dark mode
- Avoid: gray text on colored backgrounds (use shade of background instead), cyan-on-dark / purple-to-blue gradient palette

## Layout & Spacing
- 4pt base grid: 4, 8, 12, 16, 24, 32, 48, 64, 96px. Name tokens semantically (`--space-sm`) not by value
- `gap` over margins for sibling spacing. `clamp()` for fluid spacing
- Visual rhythm through varied spacing: tight grouping (8-12px) for related, generous separation (48-96px) between sections
- Flexbox for 1D, Grid for 2D. Don't default to Grid when Flexbox with `flex-wrap` suffices
- `repeat(auto-fit, minmax(280px, 1fr))` for responsive grids without breakpoints
- Container queries (`@container`) for component-level responsiveness
- Gestalt principles: proximity (related items close), similarity (same style = same role), closure (the eye completes incomplete shapes), continuity (aligned elements feel connected)
- Squint test: blur vision -- can you identify primary element, secondary, and groupings?
- Hierarchy through 2-3 dimensions at once: size + weight + space
- Avoid: same spacing everywhere, cards for everything, nested cards, centering everything, identical card grids

## Motion
- Duration: 100-150ms (feedback), 200-300ms (state change), 300-500ms (layout change), 500-800ms (entrance)
- Exit animations at ~75% of entrance duration
- Exponential easing (`ease-out-quart/quint/expo`) for natural deceleration. Never bounce or elastic
- Animate ONLY `transform` and `opacity`. Height: use `grid-template-rows: 0fr → 1fr`
- Staggered reveals: `calc(var(--i) * 50ms)`, cap total stagger at ~500ms
- `prefers-reduced-motion`: crossfade instead of spatial motion. Preserve functional animations (progress, spinners)
- Micro-interactions: button press (scale 0.97, 100ms), success confirmation (checkmark draw-on, 300ms), toggle switch (thumb slide, 200ms). Feedback MUST be immediate (< 100ms perceived)
- `will-change`: apply only when animation is imminent (`:hover`, `.animating`), never statically
- Avoid: animating layout properties (`width`, `height`, `top`, `left`, `margin`), `ease` (compromise curve)

## Depth & Elevation
- Semantic z-index scale: dropdown (100) → sticky (200) → modal-backdrop (300) → modal (400) → toast (500) → tooltip (600)
- Consistent shadow scale (sm → lg). Shadows should be subtle
- Dark mode: use surface lightness for elevation, not shadows

## Anti-Patterns (AI Slop Detection)
- If someone would say "AI made this" at first glance, that's the problem
- Tells: cyan-on-dark palette, purple-to-blue gradients, gradient text on headings, glassmorphism everywhere, hero metric layout (big number + small label + stats), identical card grids, rounded rectangles with generic drop shadows, glowing accents on dark backgrounds, large icons with rounded corners above every heading
- Test: does this look like every other AI-generated interface from 2024-2025?
