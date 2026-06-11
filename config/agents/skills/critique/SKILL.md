---
name: critique
description: UX design evaluation using Nielsen heuristics, cognitive load analysis, accessibility audit, and persona testing. Use when reviewing, critiquing, or evaluating a UI design, or running a technical quality audit on an interface.
user-invocable: true
argument-hint: "[target component, page, or feature]"
context: fork
agent: design-reviewer
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *)
---

# Design Critique

## Design Context

Before evaluating, ensure design context exists:

1. Check if `.impeccable.md` exists in project root -- if yes, read it
2. If not, ask the user 3 questions before proceeding:
   - Who is the target audience and in what context do they use this?
   - What is the brand personality/tone? (e.g., playful, professional, minimal)
   - What is the primary user goal on this page/component?
3. Save answers to `.impeccable.md` for future sessions

## Evaluation

Read all target files completely, then evaluate across these dimensions:

### 1. AI Slop Detection (CRITICAL -- evaluate first)
Does this look AI-generated? Check against `visual-design` skill anti-patterns. Be brutally honest.

### 2. Heuristic Evaluation
Score Nielsen's 10 heuristics 0-4. See [scoring guide](reference/heuristics-scoring.md).

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | ? | |
| 2 | Match System / Real World | ? | |
| 3 | User Control and Freedom | ? | |
| 4 | Consistency and Standards | ? | |
| 5 | Error Prevention | ? | |
| 6 | Recognition over Recall | ? | |
| 7 | Flexibility and Efficiency | ? | |
| 8 | Aesthetic and Minimalist Design | ? | |
| 9 | Error Recovery | ? | |
| 10 | Help and Documentation | ? | |
| **Total** | | **??/40** | |

Rating: 18-20 Excellent, 14-17 Good, 10-13 Acceptable, 6-9 Poor, 0-5 Critical

### 3. Cognitive Load
Run the [8-item checklist](reference/cognitive-load.md). Report failure count: 0-1 = low (good), 2-3 = moderate, 4+ = critical.

### 4. Technical Quality
- Accessibility: contrast ratios, keyboard nav, ARIA, semantic HTML, zoom support
- Responsive: mobile breakpoints, touch targets (44px), overflow, input method detection
- Performance: layout thrashing, expensive animations, missing lazy load
- Theming: design token usage, dark mode correctness

### 5. Persona Red Flags
Select 2-3 relevant personas from [reference](reference/personas.md). Walk through primary action as each. Report specific failures.

## Output

### Anti-Patterns Verdict
Pass/fail with specific tells.

### What's Working
2-3 specific strengths.

### Priority Issues (P0-P3)
For each:
- **[P?] Issue**: name clearly
- **Impact**: how it hurts users
- **Fix**: concrete recommendation

### Scores
- Heuristic: ??/40
- Cognitive Load: ? failures / 8
- Technical: a11y / responsive / performance / theming (each 0-4, total /16)

### Recommended Next Steps
Prioritized list of what to fix and in what order.
