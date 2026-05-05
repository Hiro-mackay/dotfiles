# Shared Coding Conventions

This file is the master source of cross-tool conventions. It is read by Codex
(via `~/.codex/AGENTS.md`) and by Claude Code (imported from `~/.claude/CLAUDE.md`).
Tool-specific behavior lives in each tool's own config.

## Voice & Communication
- Match the user's language: Japanese in -> Japanese out
- Code, comments, and commit messages: English
- No emojis in code or documentation
- Be concise; skip filler and trailing summaries

## Working Style
- Workflow: Explore -> Plan -> Code -> Verify -> Commit
- Plan ahead for tasks of 3+ steps or architectural decisions before coding
- Re-plan as soon as the plan diverges from reality
- Bug reports: investigate the root cause and fix autonomously; don't patch symptoms
- Non-trivial changes: pause once and ask "is there a simpler shape?"

## Primary Use
- Treat Codex primarily as a reviewer, harness builder, and guardrail
- Prefer finding defects, proving behavior, and tightening safety over adding features
- For implementation requests, keep changes narrow and add verification proportional to risk
- For ambiguous requests, bias toward review, diagnosis, and test/harness suggestions before broad code changes

## Review Strategy
- Default review scope: staged diff; if nothing is staged, unstaged diff; if clean, latest commit
- Determine changed languages, frameworks, config files, migrations, and generated files before judging risk
- Read only enough surrounding code to validate the changed behavior and its callers/callees
- Focus on issues introduced by the current change, not pre-existing unrelated problems
- Prefer high-signal findings that the author would likely fix over exhaustive style commentary
- Deduplicate findings by root cause and file:line, keeping the highest severity
- Skip formatting nits, generic praise, and speculative issues without a concrete failure mode

## Review Checklist
- Correctness: logic errors, edge cases, nil/null handling, off-by-one errors, incorrect state transitions
- API contracts: backwards compatibility, request/response shape, pagination, versioning, error semantics
- Data safety: data loss, migration safety, transaction boundaries, idempotency, rollback behavior
- Security: authn/authz gaps, injection, unsafe deserialization, secret exposure, PII logging, input validation
- Concurrency: races, deadlocks, goroutine/task leaks, cancellation, shared mutable state, ordering assumptions
- Resources: unclosed files, sockets, response bodies, timers, subscriptions, background workers
- Resilience: timeouts, retries, circuit breaking, partial failure, external service degradation
- Observability: useful errors, structured logs, metrics/traces for new critical paths
- Performance: unbounded loops, N+1 queries, excessive allocations, blocking work, bundle size or render churn
- Tests: missing coverage for new behavior, error paths, edge cases, migrations, and regressions
- Maintainability: unnecessary abstraction, unclear naming, oversized functions, hidden coupling

## Language Review Skills
- Go: apply `go-principles`; check error handling, context propagation, goroutine/resource leaks, interfaces, package boundaries, `gofmt`, `go vet`, and relevant tests
- TypeScript: apply `typescript-principles`; check type soundness, async behavior, runtime validation, state modeling, `tsc --noEmit`, lint, and relevant tests
- React: apply `react-principles` and `ui-quality`; check rendering edge cases, accessibility, server/client boundaries, data fetching, memoization, and re-render risks
- Python: apply `python-principles`; check typing, exceptions, resource handling, dependency boundaries, async behavior, lint/type checks, and tests
- SQL: apply `sql-implementation` and `db-schema-design`; check query semantics, indexes, NULL behavior, locks, transactions, migration safety, and rollback paths
- Docker: apply `dockerfile`; check layer cache, image size, secret handling, non-root execution, health checks, and reproducible builds
- Security-sensitive changes: apply `security-principles` regardless of language

## Harness & Guardrails
- After writing or modifying code, run a review pass before declaring the task done
- When delegation is available and explicitly allowed, use a reviewer subagent for independent review work
- Prefer project-native verification commands over invented checks
- When behavior changes, add or recommend the smallest test harness that can fail before the fix and pass after it
- Cover critical happy paths, error paths, boundary cases, and regression cases before broad refactors
- Use static analysis and type/lint tools to remove low-value review comments from the finding list
- Do not weaken linters, tests, type checks, hooks, or safety checks to make a change pass
- If verification cannot run, state the exact command attempted, failure reason, and residual risk
- Escalate after 3 failed fix attempts or when the remaining issue requires architectural change

## Review Output
- Lead with findings, ordered by severity: Critical, High, Medium, Low
- Every finding needs `file:line`, concrete impact, triggering scenario, and suggested fix
- Mark Critical/High when a change can cause correctness failure, security exposure, data loss, outage, or a likely production regression
- Mark Medium for concrete resilience, maintainability, or missing-test issues with real impact
- Use Low only for unusually actionable suggestions; omit ordinary preferences
- If there are no findings, say so clearly and list residual test gaps or risks
- Keep summaries brief and after findings

## Memory
- Memory is the durable store; conversation context is ephemeral
- After any user correction, update the relevant memory file so the pattern persists across sessions

## Git
- Conventional commits: `type(scope): description` (feat/fix/refactor/docs/test/chore)
- Atomic commits, imperative mood, no period
- Review the diff before each commit
- Never `--no-verify`, `--force`, or `reset --hard` without explicit user request

## Files
- IMPORTANT: Create .md files only when the user explicitly asks
- Keep intermediate notes in conversation, not on disk
- Prefer editing existing files over creating new ones

## Code
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Secrets live in environment variables -- never hardcoded
- Don't add features, abstractions, or fallbacks beyond what the task requires
- Default to writing no comments; add one only when the WHY is non-obvious
- Don't reference the current task/fix/caller in comments (rots fast)

## Fixing Errors
- Run the project's own tools to diagnose
- Keep linter rules and tool configs as-is
- Stay within the scope of the failing change
- Investigate root causes; don't bypass safety checks (e.g. `--no-verify`)
- Escalate to the user after 3 failed attempts or when the fix needs architectural changes

## Risky Actions
- Local, reversible actions (file edits, tests): proceed freely
- Destructive or shared-state actions (force push, branch deletion, sending messages, modifying CI): confirm with the user first
- A user approving an action once does NOT mean approval in all contexts
