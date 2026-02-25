---
name: verify
description: Run 7-step verification before commit or PR
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep
---

Execute these checks in order. Stop on critical failures.

## Step 1: Build
- Go: `go build ./...`
- TypeScript: `npx tsc --noEmit` or `pnpm build`
- Python: `python -m py_compile` on changed files

## Step 2: Type Check
- Go: `go vet ./...`
- TypeScript: covered by Step 1 -- skip
- Python: `mypy` (if configured)

## Step 3: Lint
- Go: `golangci-lint run` (if available), otherwise `go vet`
- TypeScript: `npx eslint .` or `pnpm lint`
- Python: `ruff check .` (if available)

## Step 4: Test
- Go: `go test -cover ./...`
- TypeScript: `npm test` or `pnpm test`
- Python: `pytest --cov` (if configured)

## Step 5: Dependency Vulnerability Check
Run if dependency manifest exists. Report as [WARN], do NOT auto-fix.
- Go: `govulncheck ./...`
- TypeScript: `npm audit --audit-level=high` or `pnpm audit`
- Python: `pip audit`

## Step 6: Secret & Debug Scan
Search for: `console.log`, `fmt.Println`, debug `print(`, hardcoded API key patterns, `.env` in staged changes.

## Step 7: Git Status
Show uncommitted changes, untracked files, confirm correct branch.

## Output
`[PASS]` / `[FAIL]` for each step.
Final: `Overall: READY / NOT READY for commit`
