---
name: git-workflow
description: Git workflow conventions for branching strategy, PR creation, code review, and merge policies. Applies when creating branches, opening PRs, or reviewing code.
---

# Git Workflow Conventions

## Branch Naming
- Format: `{type}/{short-description}`
- Types: `feature/`, `fix/`, `refactor/`, `chore/`, `docs/`, `test/`
- Use kebab-case: `feature/add-user-auth`, not `feature/addUserAuth`
- Include ticket ID when available: `fix/PROJ-123-login-timeout`

## PR Size & Scope
- Target: under 300 lines changed (excluding generated files, lock files)
- One concern per PR -- do not mix feature + refactor + fix
- If a PR grows too large, split into stacked PRs with clear dependency chain
- Draft PR early for visibility on long-running work

## PR Description
- Title: imperative mood, under 70 characters, same conventions as commit messages
- Body structure:
  - **Summary**: 1-3 bullet points of what changed and why
  - **Test plan**: how to verify the changes work
  - **Breaking changes**: if any, with migration steps
- Link related issues with `Closes #123` or `Fixes #123`
- Include before/after screenshots for UI changes

## Code Review
- Review within 1 business day -- unblock teammates
- Approve when "good enough to ship" -- not "exactly how I would write it"
- Comment types:
  - `nit:` style preference, non-blocking
  - `suggestion:` improvement idea, author decides
  - `blocking:` MUST fix before merge (bugs, security, correctness)
- Reviewer checks: correctness, edge cases, test coverage, naming, security implications
- Author resolves all blocking comments before merge

## Merge Strategy
- Squash merge for feature branches (clean history)
- Merge commit for long-lived branches with meaningful intermediate commits
- NEVER force-push to shared branches (main, develop, release/*)
- Delete branch after merge

## Stacked PRs
- Base each PR on the previous PR's branch, not main
- Mark as draft until the base PR is merged
- Rebase onto main after base PR merges
- Keep each PR independently reviewable
