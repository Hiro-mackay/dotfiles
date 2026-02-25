---
name: check-fix
description: Run all static analysis tools and fix errors
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
---

AI guessing is the LAST resort. Always run the project's own tools first and fix based on their output.

## Step 1: Discover Tools

Detect project type and available tools:

| Check | Go | TypeScript | Python |
|-------|-----|-----------|--------|
| Build | `go build ./...` | `npx tsc --noEmit` / `pnpm build` | `python -m py_compile` |
| Type | `go vet ./...` | (covered by tsc) | `mypy` / `pyright` |
| Lint | `golangci-lint run` | `npx eslint . --max-warnings=0` | `ruff check .` |
| Format | `gofmt -l .` | `npx prettier --check .` | `ruff format --check .` |

Also check for project-specific config: `Makefile`, `package.json` scripts (`lint`, `check`, `typecheck`), `pyproject.toml`, `.golangci.yml`.

**Prefer project scripts** (e.g., `pnpm lint`) over raw tool invocations.

## Step 2: Run All Tools, Collect All Errors

Run every available tool and capture full output BEFORE fixing anything.
Do NOT start fixing after the first tool -- gather the complete picture.

## Step 3: Triage and Auto-fix

1. Group errors by root cause (one type error may cascade into 10 lint errors)
2. Fix dependency order: types -> build -> lint -> format
3. Run auto-fixers first: `eslint --fix`, `ruff check --fix`, `gofmt -w`, `prettier --write`
4. Re-run all tools after auto-fix to see what remains

## Step 4: Manual Fix Loop

For remaining errors:
1. Read the affected file and surrounding context
2. Fix based on the tool's error message, not AI guessing
3. Fix ONE root cause at a time, re-run the specific tool to verify
4. Repeat

## Step 5: Final Verification

Re-run ALL tools with zero tolerance. Report `[PASS]` / `[FAIL]` for each.

## Safety Rules

- NEVER suppress warnings (`eslint-disable`, `//nolint`, `# noqa`)
- NEVER weaken tool config (e.g., `error` -> `warn`)
- NEVER refactor unrelated code while fixing errors
- Stop and ask the user if a fix creates more errors, same error persists after 3 attempts, or fix requires architectural changes
