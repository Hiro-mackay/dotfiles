---
name: critique
description: UX design evaluation using Nielsen heuristics, cognitive load analysis, accessibility audit, and persona testing. Run only when the user explicitly asks to review or critique a design or interface, or invokes /critique. Do not run on your own after implementing or modifying UI code.
argument-hint: "[target component, page, or feature]"
context: fork
agent: design-reviewer
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *)
---

# Design Critique

## Design context

Read `.impeccable.md` from the project root if it exists. If it does not, ask three questions before evaluating, then save the answers there:

- Who is the audience, and in what situation do they use this?
- What is the brand personality?
- What is the primary user goal on this page or component?

## Evaluation

Read the target files completely, then work through five dimensions.

**1. Does it look AI-generated.** Check against the tells in `visual-design`. Answer this one first and without softening it -- if the answer is yes, the rest of the critique is downstream of it.

**2. Nielsen heuristics.** Score all ten from 0 to 4 using the [scoring guide](reference/heuristics-scoring.md), and report the table with a one-line issue against each: visibility of system status, match with the real world, user control and freedom, consistency and standards, error prevention, recognition over recall, flexibility and efficiency, aesthetic and minimalist design, error recovery, help and documentation.

Out of 40: 34+ excellent, 28-33 good, 20-27 acceptable, 12-19 poor, under 12 critical.

**3. Cognitive load.** Run the [8-item checklist](reference/cognitive-load.md). 0-1 failures is fine, 2-3 is moderate, 4 or more is critical.

**4. Technical quality.** Score accessibility, responsive behavior, performance, and theming 0-4 each. Accessibility and responsive criteria are in `ui-quality` (semantics, contrast, keyboard, ARIA, zoom, touch targets, breakpoints, input detection); theming is in `visual-design` (semantic tokens, dark mode as its own palette rather than an inversion). For performance, score against `web-performance` (lazy loading, bundle weight, font and image handling) plus two things it does not cover: layout thrashing -- reads of `offsetHeight` or `getBoundingClientRect` interleaved with writes inside a loop -- and animation of properties other than `transform` and `opacity`.

**5. Personas.** Pick 2-3 relevant [personas](reference/personas.md) and walk each through the primary action. Report the specific step where each one fails.

## Output

- **Verdict on the AI-slop question**: pass or fail, naming the specific tells
- **Issues, P0 to P3**: each with the issue named plainly, how it hurts users, and a concrete fix
- **Worth preserving**: anything the design genuinely gets right that a redesign might destroy. If there is nothing, say so rather than filling the section
- **Scores**: heuristics ??/40, cognitive load ?/8 failures, technical ??/16
- **Order to fix in**
