---
name: git-workflow
description: Git workflow conventions for branching strategy, PR creation, code review, and merge policies. Applies when creating branches, opening PRs, or reviewing code.
---

# Git Workflow Conventions

House conventions. Commit message format and the rule against committing unasked live in the global instructions.

## Branches
- `{type}/{kebab-case-description}` with type from feature, fix, refactor, chore, docs, test. Ticket ID in front of the description when there is one: `fix/PROJ-123-login-timeout`
- Delete the branch after merge. Squash merge feature branches; keep a merge commit only where the intermediate commits carry meaning

## Pull requests
- Under 300 lines changed, excluding generated and lock files. One concern per PR -- never a feature and a refactor and a fix together
- Past that size, stack them: each PR based on the previous branch rather than main, marked draft until its base merges, rebased onto main once it does, and each one independently reviewable
- Open a draft early on long-running work so it is visible before it is finished
- Title in imperative mood, under 70 characters. Body carries a summary of what changed and why, a test plan describing how to verify it, and breaking changes with their migration steps. `Closes #123` for the linked issue, before-and-after screenshots for UI

## Review
- Within one business day. A blocked teammate costs more than the review does
- Approve at "good enough to ship", not "how I would have written it". The alternative turns review into rewriting
- Prefix by intent: `nit:` for a style preference the author can ignore, `suggestion:` for an idea the author decides on, `blocking:` for bugs, security, and correctness. Everything marked blocking is resolved before merge
