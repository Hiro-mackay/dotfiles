---
name: review-local
description: Review local code changes for quality and security. Run only when the user explicitly asks for a review or invokes /review-local. Do not run on your own after implementing or before committing.
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

Assume this diff is wrong and try to break it. You are not checking it against a standard -- you are looking for the input, state, or sequence that makes it fail. Do not write down what is good about it.

Where a finding turns on a fact you are not certain of (a library's actual behavior, a platform guarantee, an API contract), read the source or the vendored code to confirm it. If you cannot confirm it, say so in the finding instead of asserting it.

Hunt along these lines, with language-specific rigor:

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
- Apply `readable-code` criteria (function length, nesting, parameters) and `naming-conventions` criteria (names that hide their purpose, generic suffixes, negated booleans)
- Comments: flag every comment the diff adds that isn't (a) required by tooling or a public API contract, (b) a fact the code cannot state, or (c) a deliberate simplification with its upgrade trigger. The fix is "delete it". WHAT-restatements, change/task narration, section banners, and doc comments that echo the signature all go. This is not a formatting nit -- do not skip it

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

Report everything you found. Do not pre-filter for severity, drop a finding because it looks minor, or stop because the list is getting long. Sorting happens in the second pass below, not while you are still looking.

Then sort the list you just wrote into two groups:

- **Confirmed** -- you can name the input or sequence, the code path it takes, and the wrong result that follows
- **Suspected** -- the shape is wrong but you could not trace a failing path. Report these under their own heading with the specific thing you could not confirm. Do not promote them into the confirmed group and do not delete them

Group confirmed findings by severity (Critical > High > Medium > Low).
For each finding:
- File and line number
- The failure: what input or state makes this go wrong, and what happens
- Suggested fix

End with `What held up:` and one or two lines on what you attacked and could not break. Be specific about what you tried -- "reviewed and looks fine" means the attack was never made.

## Remediation Order (for the caller)

When the findings get fixed in batch: fix all Critical/High, then Medium; sweep remaining Low in already-touched files in the same pass. Findings that need design work go to a follow-up issue, not into this diff.
