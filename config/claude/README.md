# Claude Code Global Config

Claude Code's global settings managed via dotfiles + GNU Stow.

> This `README.md` is NOT loaded into Claude Code context. Only `CLAUDE.md` is auto-loaded.

## Structure

```
claude/
  CLAUDE.md              # Global instructions (auto-loaded in all projects)
  settings.json          # Permissions, hooks, plugins
  agents/                # Specialized agents -- process (invoked on demand)
  rules/                 # Path-filtered rules (auto-loaded by file pattern)
  skills/                # Knowledge skills -- design principles (auto-loaded on trigger)
  contexts/              # System prompts for shell aliases (ccdev, ccreview, ccsearch)
```

## Skills

Skills load on demand based on description matching. Language rules load based on file path patterns.

| Skill | Location | Trigger |
|-------|----------|---------|
| `go-principles` | `rules/` | `**/*.go` |
| `typescript-principles` | `rules/` | `**/*.{ts,tsx}` |
| `react-principles` | `rules/` | `**/*.{tsx,jsx}` |
| `python-principles` | `rules/` | `**/*.py` |
| `sql-implementation` | `rules/` | `**/*.sql`, `**/migrations/**` |
| `dockerfile` | `rules/` | `**/Dockerfile*`, `**/docker-compose*` |
| `readable-code` | `skills/` | Code writing/review |
| `api-design` | `skills/` | HTTP API design |
| `ddd-principles` | `skills/` | Domain modeling |
| `test-strategy` | `skills/` | Testing tasks |
| `team-conventions` | `skills/` | Team operations |
| `security-principles` | `skills/` | Auth, input validation, secrets, crypto |
| `observability` | `skills/` | Logging, tracing, metrics, alerting |
| `error-handling` | `skills/` | Retry, timeout, circuit breaker, resilience |
| `git-workflow` | `skills/` | Branching, PRs, code review |
| `architecture-decisions` | `skills/` | Trade-off analysis, complexity management, ADR |
| `system-design` | `skills/` | Distributed systems, CAP, failure domains, scaling |
| `module-design` | `skills/` | Coupling, cohesion, dependency direction, boundaries |
| `naming-conventions` | `skills/` | Naming signals, conventions, anti-patterns |
| `db-schema-design` | `skills/` | Schema design, data modeling, relationship patterns |
| `visual-design` | `skills/` | Typography, color, layout, motion, AI anti-patterns |
| `ui-quality` | `skills/` | A11y, responsive, states, UX writing |
| `web-performance` | `skills/` | Images, fonts, bundle, CWV, animation perf |
| `critique` | `skills/` | `/critique` UX evaluation (manual, fork context) |
| `note` | `skills/` | `/note` (manual) |
| `review-local` | `skills/` | `/review-local` (manual) |

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `code-reviewer` | sonnet | General quality and security review |
| `go-reviewer` | sonnet | Go: idioms, concurrency, error handling (1.22+) |
| `typescript-reviewer` | sonnet | TS: type safety, async patterns, narrowing |
| `react-reviewer` | sonnet | React: components, hooks, Server Components, state |
| `security-reviewer` | opus | Vulnerability analysis (OWASP Top 10) |
| `python-reviewer` | sonnet | Python: type safety, error handling, modern patterns |

## Team Mode

Claude automatically decides when to use agent teams based on task complexity:

- **Auto-team**: 3+ independent concerns or 4+ files triggers team creation
- **Single agent**: Simple tasks (bug fixes, single-file changes) run normally
- **Opt-out**: Say "single agent" or "no team" to force single mode

Protocol details: [`skills/team-conventions/SKILL.md`](skills/team-conventions/SKILL.md)

Key rules:
- Each file belongs to exactly one teammate (no concurrent edits)
- Shared types/interfaces are owned by their creator; dependents wait via `blockedBy`

## Shell Aliases

Defined in `zsh/.zshrc`:

| Alias | Command |
|-------|---------|
| `cc` | `claude --dangerously-skip-permissions` |
| `ccdev` | `cc` + dev mode system prompt (code-first) |
| `ccreview` | `cc` + review mode system prompt (read-only analysis) |
| `ccsearch` | `cc` + research mode system prompt (exploration) |
| `ccconfig` | `cd` to Claude config directory |

## Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `detect-console-log.sh` | PostToolUse (Edit/Write) | Warn on `console.log` / `fmt.Println` / `print()` |
| `go-vet.sh` | PostToolUse (Edit/Write) | Run `go vet` on Go file changes |
| `block-dev-server.sh` | PreToolUse (Bash) | Block long-running dev servers |
| `filter-test-output.sh` | PreToolUse (Bash) | Filter verbose test output |
| `notify.sh` | Stop / Notification | Desktop notification on task completion |

## Plugins

- `hookify` -- Hook management
- `commit-commands` -- `/commit`, `/commit-push-pr`
- `context7` -- Library documentation context
- `security-guidance` -- Security checks on file edits

> `gopls-lsp`, `typescript-lsp` are enabled per-project, not globally.
