---
allowed-tools: Bash(go:*), Bash(npm:*), Bash(npx:*), Bash(pnpm:*), Bash(bun:*), Bash(python:*), Bash(python3:*), Bash(git status:*), Bash(git diff:*), Bash(grep:*), Bash(find:*), Read, Glob, Grep
description: Run 6-step verification before commit or PR
---

## Verification Pipeline

Execute these checks in order. Stop on critical failures.

### Step 1: Build
Detect project type and run appropriate build:
- Go: `go build ./...`
- TypeScript: `npx tsc --noEmit` or `pnpm build`
- Python: `python -m py_compile` on changed files

### Step 2: Type Check
- Go: `go vet ./...`
- TypeScript: `npx tsc --noEmit --strict`
- Python: `mypy` (if configured)

### Step 3: Lint
- Go: `golangci-lint run` (if available), otherwise `go vet`
- TypeScript: `npx eslint .` or `pnpm lint`
- Python: `ruff check .` (if available)

### Step 4: Test
Run tests with coverage:
- Go: `go test -cover ./...`
- TypeScript: `npm test` or `pnpm test`
- Python: `pytest --cov` (if configured)

### Step 5: Secret & Debug Scan
Search for:
- `console.log`, `fmt.Println` (debug statements)
- `print(` in Python (debug prints, not logging)
- Hardcoded strings matching API key patterns
- .env files in staged changes

### Step 6: Git Status
- Show uncommitted changes
- Show untracked files
- Confirm correct branch

## Output
For each step, output [PASS] or [FAIL] with details.
End with: `Overall: READY / NOT READY for commit`
If any step fails, list issues and suggest fixes.
