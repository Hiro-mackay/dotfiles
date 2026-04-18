---
name: web-performance
description: Web platform performance principles covering image optimization, font loading, bundle size, Core Web Vitals, and animation performance. Applies when optimizing page load speed, reducing bundle size, fixing layout shift, or improving runtime performance. For React/framework-specific optimization, see react-principles rule.
---

# Web Performance Principles

## Core Web Vitals
- **LCP** (Largest Contentful Paint): < 2.5s. Preload hero image/font. Inline critical CSS. Avoid render-blocking resources
- **FID/INP** (Interaction to Next Paint): < 200ms. Break long tasks (> 50ms) with `requestIdleCallback` or `scheduler.yield()`. Defer non-critical JS
- **CLS** (Cumulative Layout Shift): < 0.1. Set explicit `width`/`height` on images/video. Reserve space for dynamic content. `font-display: swap` with fallback metric matching

## Image Optimization
- Format: WebP for photos, SVG for icons/illustrations, AVIF for maximum compression (with WebP fallback)
- Responsive: `srcset` with width descriptors + `sizes` attribute. Let browser choose optimal resolution
- Lazy loading: `loading="lazy"` for below-fold images. `loading="eager"` + `fetchpriority="high"` for hero
- Sizing: always set `width` and `height` attributes to prevent layout shift
- `<picture>` for art direction (different crops by viewport), not just resolution switching

## Font Loading
- `font-display: swap` to prevent invisible text (FOIT)
- Match fallback font metrics (`size-adjust`, `ascent-override`, `descent-override`) to minimize layout shift
- Preload critical fonts: `<link rel="preload" href="font.woff2" as="font" crossorigin>`
- Subset fonts to used character ranges. WOFF2 only (best compression)
- System fonts for body text are a valid choice: instant load, native feel

## Bundle Optimization
- Code split by route: each page loads only what it needs
- Dynamic `import()` for heavy components (editors, charts, maps) triggered by user action
- Tree-shake: use ES modules, avoid barrel files that defeat tree-shaking
- Analyze with `webpack-bundle-analyzer` or `source-map-explorer`. Target: < 200KB initial JS (compressed)
- Defer non-critical third-party scripts (analytics, chat widgets) until after interactive

## Animation Performance
- For motion design rules (easing, duration, `prefers-reduced-motion`), see `visual-design`
- Scroll-triggered: `IntersectionObserver`, not scroll events. Unobserve after first animation
- `content-visibility: auto` + `contain-intrinsic-size` for long lists -- skip layout/paint for off-screen items

## Resource Loading
- Critical path: inline critical CSS (< 14KB), defer non-critical. `<link rel="preload">` for key resources
- `<link rel="preconnect">` for third-party domains (CDN, API, fonts)
- HTTP caching: immutable assets with content hash (`app.a1b2c3.js`) + long `max-age`. HTML with `no-cache`
- Compression: Brotli > gzip. Enable at CDN/server level

## Measurement
- Synthetic: Lighthouse CI in pipeline, fail on regression
- Real User Monitoring (RUM): track p75 of CWV from actual users
- Measure first, optimize second. Don't guess bottlenecks
