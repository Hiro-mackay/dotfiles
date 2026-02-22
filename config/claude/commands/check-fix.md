---
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
description: Run all static analysis tools and fix errors
---

## Static Analysis First

AI guessing is the LAST resort. Always run the project's own tools first and fix based on their output.

### Step 1: Discover Tools

Detect project type and available tools:

| Check | Go | TypeScript | Python |
|-------|-----|-----------|--------|
| Build | `go build ./...` | `npx tsc --noEmit` / `pnpm build` | `python -m py_compile` |
| Type | `go vet ./...` | (covered by tsc) | `mypy` / `pyright` |
| Lint | `golangci-lint run` | `npx eslint . --max-warnings=0` | `ruff check .` |
| Format | `gofmt -l .` | `npx prettier --check .` | `ruff format --check .` |

Also check for project-specific config: `Makefile`, `package.json` scripts (`lint`, `check`, `typecheck`), `pyproject.toml`, `.golangci.yml`.

**Prefer project scripts** (e.g., `pnpm lint`) over raw tool invocations.

### Step 2: Run All Tools, Collect All Errors

Run every available tool and capture full output BEFORE fixing anything.
Do NOT start fixing after the first tool -- gather the complete picture.

### Step 3: Triage by Root Cause

- Group errors by root cause (one type error may cascade into 10 lint errors)
- Fix dependency order: types -> build -> lint -> format
- Identify which errors are auto-fixable (`eslint --fix`, `ruff check --fix`, `gofmt -w`)

### Step 4: Auto-fix First

Run auto-fixers before manual fixes:
- `npx eslint . --fix`
- `ruff check --fix .`
- `ruff format .`
- `gofmt -w .`
- `npx prettier --write .`

Re-run all tools after auto-fix to see what remains.

### Step 5: Manual Fix Loop

For remaining errors:
1. Read the affected file and surrounding context
2. Fix based on the tool's error message, not AI guessing
3. Fix ONE root cause at a time
4. Re-run the specific tool to verify the fix
5. Repeat

### Step 6: Final Verification

Re-run ALL tools from Step 2 with zero tolerance:
- Build: must pass
- Type check: must pass
- Lint: zero warnings (`--max-warnings=0`)
- Format: must pass

Report: `[PASS]` / `[FAIL]` for each tool.

## Safety Rules

- NEVER suppress warnings with `// eslint-disable`, `//nolint`, `# noqa` etc.
- NEVER weaken tool config (e.g., changing `error` to `warn` in eslint)
- Stop and ask the user if:
  - A fix creates more errors than it solves
  - Same error persists after 3 attempts
  - Fix requires architectural changes or new dependencies
- NEVER refactor unrelated code while fixing errors
