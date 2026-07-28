---
name: plan-template
description: Implementation-plan structure -- required sections including reversibility notes and test-tier declaration. Apply when drafting an implementation plan in plan mode.
user-invocable: false
---

# Plan Template

A plan is executable by someone with zero conversation context. Structure every implementation plan with these sections.

## Required sections

1. **Context** -- the problem, root cause if known, decisions the user already made, facts already verified (with file:line anchors)
2. **Approach** -- chosen design and why; one alternative considered and the deciding trade-off
3. **Changes** -- files to touch, grouped into atomic commits; when an in-repo pattern exists, name it and mirror it
4. **Reversibility** -- state it explicitly:
   - Reversible (code-only, additive): one line, "revert of these commits restores prior state"
   - Irreversible or stateful (migrations, `terraform apply`, deploys, data backfills, external side effects): mark each such step and hand it off for manual execution instead of running it
5. **Test tier** -- declare which tiers the change gets (unit / integration / manual observation) and why; name the commands
6. **Verification** -- map each acceptance criterion to an observable check (command, screenshot, log line)
7. **Scope / STOP** -- what is out of scope; conditions that require stopping to ask (e.g. production code changes needed to make something testable)

## Decision hooks

- ADR: state whether the change alters an architectural decision; if yes, which ADR gets written or updated
- Broken premise: if a plan's premise collapses mid-execution (branch abandoned, design PR closed, API removed), stop and re-plan -- do not salvage silently
