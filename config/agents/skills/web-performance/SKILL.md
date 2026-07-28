---
name: web-performance
description: Web platform performance principles covering image optimization, font loading, bundle size, Core Web Vitals, and animation performance. Applies when optimizing page load speed, reducing bundle size, fixing layout shift, or improving runtime performance. For React/framework-specific optimization, see react-principles skill (auto-loaded for .tsx/.jsx files).
---

# Web Performance Principles

The numbers and the platform specifics. General "make it fast" advice is deliberately absent.

## Targets
- LCP under 2.5s: preload the hero image and font, inline critical CSS, remove render-blocking resources
- INP under 200ms: break tasks longer than 50ms with `scheduler.yield()` or `requestIdleCallback`, defer non-critical JS
- CLS under 0.1: explicit `width` and `height` on every image and video, reserved space for anything injected later, and a fallback font whose metrics match
- Initial JS under 200KB compressed, measured with `source-map-explorer` or the bundler's analyzer
- Critical CSS inlined under 14KB, the rest deferred

## Images
- AVIF with a WebP fallback for photos, SVG for icons and illustrations
- `srcset` with width descriptors plus `sizes`, and let the browser pick
- `loading="lazy"` below the fold; the hero gets `loading="eager"` with `fetchpriority="high"`. Lazy-loading the hero is a common way to make LCP worse
- `<picture>` when the crop changes by viewport. For resolution alone, `srcset` is enough

## Fonts
- `font-display: swap`, WOFF2 only, subset to the character ranges actually used
- `size-adjust`, `ascent-override`, and `descent-override` on the fallback so the swap doesn't move the page
- `<link rel="preload" as="font" crossorigin>` for fonts on the critical path
- System fonts for body text are a legitimate choice, not a compromise: nothing to load and nothing to shift

## Loading
- Code split by route; `import()` heavy components (editors, charts, maps) on the interaction that needs them
- `<link rel="preconnect">` for third-party origins you will certainly hit -- CDN, API, font host
- Hashed asset filenames with a long `max-age` and `immutable`; HTML itself `no-cache`
- Brotli over gzip, configured at the CDN or server

## Runtime
- `IntersectionObserver` for scroll-triggered work, never a scroll listener, and unobserve once it has fired
- `content-visibility: auto` with `contain-intrinsic-size` on long lists so off-screen items skip layout and paint
- Easing, duration, and `prefers-reduced-motion`: `visual-design` skill

## Measurement
- Measure before optimizing. A guessed bottleneck usually costs a day and moves nothing
- Lighthouse CI in the pipeline, failing on regression, and RUM tracking the p75 of real users -- lab numbers and field numbers disagree, and the field one is the real one
