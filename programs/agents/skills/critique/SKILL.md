---
name: critique
description: Evaluate a specified UI or UX. Use only when the user explicitly requests a design critique or invokes /critique.
argument-hint: "[target component, page, or feature]"
context: fork
agent: design-reviewer
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *)
---

# Design Critique

Review only the requested target. In Codex, use an available `design-reviewer` role for an explicitly requested critique. If already running as that reviewer, evaluate directly; never spawn another reviewer. If no such role is available, review inline.

## Design context

Read `.impeccable.md` at the project root if present. Otherwise use the task and existing project context to establish the audience, primary user goal, and relevant brand constraints. Return missing context to the parent; when working inline, ask only for information essential to a useful evaluation. Do not create or modify files as part of the critique.

## Evaluation

Read the relevant target files and inspect the rendered interface when available. Evaluate these five dimensions without treating source inspection as a visual or interaction test.

1. **Visual hierarchy.** Check whether typography, color, spacing, and layout communicate priority and support the interface's purpose.

2. **Nielsen heuristics.** Assess all ten using the [scoring guide](reference/heuristics-scoring.md): status visibility, real-world match, user control, consistency, error prevention, recognition, efficiency, minimalism, error recovery, and help. Score 0-4 only where evidence supports a score. A total out of 40 requires all ten to be assessed.

3. **Cognitive load.** Apply the [8-item checklist](reference/cognitive-load.md). Distinguish observed failures from items that could not be assessed. Use a failure count out of eight only when all items were assessed.

4. **Technical quality.** Assess accessibility, responsive behavior, theming, and measured performance. Label inferred risks and identify the observation needed to confirm them.

5. **Personas.** Choose 2-3 relevant [personas](reference/personas.md) and trace the primary action for each. Identify the exact failing step. Label hypothetical walkthroughs as predictions, not observed user tests.

## Output

Use P0-P3 as the only finding groups, ordered by severity. Omit empty groups and do not duplicate findings by evaluation dimension.

- P0: The primary task is blocked for all or nearly all users, requiring immediate correction.
- P1: A core task is blocked for an affected user group or a severe error lacks recovery.
- P2: A usability problem causes avoidable effort or confusion but has a workable path.
- P3: A minor consistency or presentation issue has limited user impact.

For each finding, give the location, evidence, user impact, and concrete fix. Name relevant evaluation dimensions and include scores only when they clarify the finding. Preserve useful existing behavior in the proposed fix.

State unverified areas and missing context in a brief ungrouped paragraph. Do not promote a prediction into a confirmed finding. If no findings are supported, say so and state the limits of the review.
