---
name: security-audit
description: Security audit of local code changes (auth, input handling, secrets, injection, crypto) before commit
context: fork
agent: security-reviewer
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *)
---

## Context

Determine what to audit based on git state:

1. If there are staged changes (`git diff --cached`): audit staged changes
2. Else if there are unstaged changes (`git diff`): audit all working tree changes
3. Else: audit the latest commit (`git diff HEAD~1`)

Use the appropriate diff command for context, and `--name-only` variant for the file list.

## Task

Audit the changes following your standard process (secrets scan, input handling, auth/authz, query construction, error-handling leakage, dependency versions). Read surrounding code (auth flows, middleware) where the diff alone lacks context.

Report findings in your standard output format (Vulnerability / Location / Severity / Fix, CWE-referenced). If nothing is found, report "Clean" with the list of checks performed.
