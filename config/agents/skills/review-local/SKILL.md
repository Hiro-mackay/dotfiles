---
name: review-local
description: Review code changes for quality and security after implementation, before commit
context: fork
agent: code-reviewer
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *), Bash(git stash *)
---

## Context

Determine what to review based on git state:

1. If there are staged changes (`git diff --cached`): review staged changes
2. Else if there are unstaged changes (`git diff`): review all working tree changes
3. Else: review the latest commit (`git diff HEAD~1`)

Use the appropriate diff command for context, and `--name-only` variant for the file list.

## Task

Review the code changes. Apply these criteria with language-specific rigor:

### Bugs (Critical/High)
- Logic errors, off-by-one, null/nil handling, race conditions
- Resource leaks (unclosed connections, file handles, goroutines)
- Incorrect error propagation or swallowed errors

### Security (Critical/High)
- Apply `security-principles` skill criteria (injection, auth, secrets, input validation)
- Hardcoded secrets, tokens, or credentials in diff

### Resilience (High/Medium)
- Missing timeouts on external calls
- Missing error handling on async operations
- Non-idempotent retry logic

### Quality (Medium)
- Apply `readable-code` skill criteria (function length, nesting, parameters, naming)

### Over-engineering (Medium)
- `delete`: dead code, unused flexibility, speculative feature
- `stdlib`: hand-rolled thing the standard library ships -- name the function
- `native`: dependency doing what the platform already provides -- name the feature
- `yagni`: abstraction with one implementation, config nobody sets, layer with one caller
- `shrink`: same logic, fewer lines -- show the shorter form
- A single smoke test or assert-based self-check is not bloat; do not flag it

### Tests (Medium)
- Coverage gaps for changed code paths
- Missing edge case and error path tests

## Output Format

Group findings by severity (Critical > High > Medium > Low).
For each finding:
- File and line number
- Issue description
- Suggested fix

End with a brief overall assessment.
