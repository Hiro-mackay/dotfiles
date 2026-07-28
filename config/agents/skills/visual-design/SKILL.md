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

Taste calls that do not come for free. Named composition laws are deliberately absent -- what follows is what they imply.

## Typography
- A modular scale of five sizes: caption, secondary, body, subheading, headline. Pick one ratio (1.25, 1.333, 1.5) and hold it
- One family across several weights usually beats two competing typefaces. If pairing, pair by contrast -- serif with sans, geometric with humanist, condensed display with wide body. Similar-but-not-identical is the one combination that always fails
- Line-height is the base unit for vertical spacing, not an afterthought applied to text
- `clamp()` for headings on content pages; fixed `rem` steps for app UI and body text
- `max-width: 65ch` for measure. Light text on dark needs +0.05-0.1 line-height
- Not Inter, Roboto, Arial, or Open Sans by default, and monospace is not shorthand for "technical"

## Color
- OKLCH for perceptually even palettes, dropping chroma as lightness approaches either extreme
- Tint every neutral toward the brand hue at roughly 0.01 chroma. Untinted gray reads as dead
- Roughly 60% neutral, 30% secondary, 10% accent by visual weight. The accent works because it is scarce
- One primary in 3-5 shades, a neutral ramp of 9-11, and four semantic colors
- Never `#000` or `#fff`
- Dark mode is not inverted light mode: lift surfaces for depth instead of casting shadows, desaturate accents, and drop text weight a step
- Semantic tokens (`--color-primary`) over primitives (`--blue-500`), with the semantic layer redefined for dark mode
- Not gray text on a colored background -- use a shade of that background instead

## Layout and spacing
- 4pt grid: 4, 8, 12, 16, 24, 32, 48, 64, 96. Name the tokens by role, not by value
- `gap` rather than sibling margins; `clamp()` for fluid spacing
- Spacing carries the grouping: 8-12px inside a group, 48-96px between sections. Uniform spacing everywhere reads as no hierarchy at all
- `repeat(auto-fit, minmax(280px, 1fr))` for responsive grids without breakpoints, `@container` for component-level response
- Build hierarchy from two or three dimensions at once -- size and weight and space
- Not: a card around everything, cards inside cards, everything centered, identical card grids

## Motion
- 100-150ms for feedback, 200-300ms for a state change, 300-500ms for layout, 500-800ms for entrances. Exits at about 75% of their entrance
- Exponential easing (`ease-out-quart` / `quint` / `expo`). Never bounce or elastic, and never plain `ease`
- Animate `transform` and `opacity` only. For height, `grid-template-rows: 0fr` to `1fr`
- Stagger with `calc(var(--i) * 50ms)`, capped around 500ms total
- `prefers-reduced-motion` swaps spatial motion for a crossfade; progress and spinners stay
- Press is scale 0.97 over 100ms, success is a 300ms checkmark draw-on, a toggle slides in 200ms. Perceived feedback under 100ms or it feels broken
- `will-change` only when the animation is imminent (`:hover`, `.animating`), never as a static declaration

## Depth
- Semantic z-index steps: dropdown 100, sticky 200, modal backdrop 300, modal 400, toast 500, tooltip 600
- A consistent, subtle shadow scale in light mode; surface lightness rather than shadow in dark mode

## Working from a visual source
When implementing from a sketch, mockup, or screenshot:
- The source is the truth. Do not let the codebase's existing tokens and components drag the result back toward how the app already looks
- Trace exact values -- colors, gradients, fonts, spacing, column counts. "Close enough" deviations compound across a page
- Render the result and compare it against the source side by side before saying it is done, and report the deviations that remain rather than claiming a match

## What not to ship
- If the first reaction would be "this was AI-generated", that is the defect
- The tells: cyan on dark, purple-to-blue gradients, gradient text on headings, glassmorphism everywhere, the big-number hero metric with a small label and a stats row, identical card grids, rounded rectangles with generic drop shadows, glowing accents on dark, a large rounded icon above every heading
