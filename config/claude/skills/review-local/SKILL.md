---
name: review-local
description: Review recent code changes for quality and security
disable-model-invocation: true
context: fork
agent: code-reviewer
allowed-tools: Read, Glob, Grep
---

## Context

- Recent changes: !`git diff HEAD~1`
- Changed files: !`git diff --name-only HEAD~1`

## Task

Review the code changes above. Focus on:

1. **Bugs**: Logic errors, null handling, edge cases, race conditions
2. **Security**: Injection, auth bypass, secret exposure, XSS
3. **Quality**: Readability, naming, complexity, duplication
4. **Tests**: Coverage gaps, missing edge case tests

## Output Format

Group findings by severity (Critical > High > Medium > Low).
For each finding:
- File and line number
- Issue description
- Suggested fix

End with a brief overall assessment.
