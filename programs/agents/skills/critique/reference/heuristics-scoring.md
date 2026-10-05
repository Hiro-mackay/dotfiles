# Heuristics Scoring Guide

Score each of Nielsen's 10 heuristics 0-4. A 4 means genuinely excellent, not "good enough."

| # | Heuristic | What to Check | 0 (Fail) | 2 (Partial) | 4 (Excellent) |
|---|-----------|---------------|----------|-------------|----------------|
| 1 | Visibility of System Status | Loading indicators, action confirmations, progress, current location | No feedback | Some states shown | Every action confirms |
| 2 | Match System / Real World | Familiar terms, logical order, recognizable icons | Pure jargon | Mixed language | Fluent user language |
| 3 | User Control and Freedom | Undo/redo, cancel, back, escape from flows | Users get trapped | Main flows have exits | Full control everywhere |
| 4 | Consistency and Standards | Same terms, same behaviors, visual consistency, platform conventions | Feels like different products | Main flows match | Fully cohesive |
| 5 | Error Prevention | Confirmations for destructive, constraints on input, smart defaults, autosave | No prevention | Some constraints | Errors nearly impossible |
| 6 | Recognition over Recall | Visible options, contextual help, persistent context, no memory bridges | Must memorize everything | Some context shown | Everything needed is visible |
| 7 | Flexibility and Efficiency | Shortcuts, customization, batch actions, expert paths | One-size-fits-all | Some shortcuts exist | Power users thrive |
| 8 | Aesthetic and Minimalist Design | Signal-to-noise ratio, visual hierarchy, only relevant info shown | Visual clutter | Mostly clean | Every element earns its place |
| 9 | Error Recovery | Clear error messages (what/why/how), suggestions, easy correction | Cryptic errors | Errors explained | Guided recovery |
| 10 | Help and Documentation | Contextual help, searchable docs, onboarding guidance | No help available | Some documentation | Help when and where needed |

## Severity Ratings for Issues

- **P0 Blocking**: prevents task completion -- fix immediately
- **P1 Major**: significant difficulty or WCAG AA violation -- fix before release
- **P2 Minor**: annoyance, workaround exists -- fix in next pass
- **P3 Polish**: nice-to-fix, no real user impact -- fix if time permits
