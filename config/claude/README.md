# Claude Code Global Config

Claude Code's global settings managed via dotfiles + GNU Stow.

> This `README.md` is NOT loaded into Claude Code context. Only `CLAUDE.md` is auto-loaded.

## Structure

```
claude/
  CLAUDE.md              # Global instructions (auto-loaded in all projects)
  settings.json          # Permissions, hooks, plugins
  agents/                # Specialized agents (invoked on demand)
  commands/              # Slash commands (invoked on demand)
  contexts/              # System prompts for shell aliases (ccdev, ccreview, ccsearch)
```

## Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/plan` | Create an implementation plan | `/plan add user auth` |
| `/verify` | 6-step pre-commit verification (build, type, lint, test, secrets, git) | `/verify` |
| `/review-local` | Review latest commit for bugs and security | `/review-local` |
| `/build-fix` | Auto-fix build and type errors one at a time | `/build-fix` |
| `/tdd` | RED-GREEN-REFACTOR workflow | `/tdd implement password validation` |
| `/test-coverage` | Analyze coverage, generate missing tests | `/test-coverage` or `/test-coverage src/auth/` |
| `/orchestrate` | Run multi-agent workflows | `/orchestrate feature login page` |

### `/orchestrate` **Workflows**

| Workflow | Pipeline |
|----------|----------|
| `feature` | planner -> tdd-guide -> code-reviewer -> security-reviewer |
| `bugfix` | planner -> tdd-guide -> code-reviewer |
| `refactor` | planner -> refactor-cleaner -> code-reviewer |
| `security` | security-reviewer -> code-reviewer -> planner |

## Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| `planner` | sonnet | Task decomposition and implementation planning |
| `architect` | opus | System design decisions and trade-off analysis |
| `code-reviewer` | sonnet | General quality and security review |
| `go-reviewer` | sonnet | Go: idioms, concurrency, error handling (1.22+) |
| `typescript-reviewer` | sonnet | TS: type safety, async patterns, narrowing |
| `react-reviewer` | sonnet | React: components, hooks, Server Components, state |
| `security-reviewer` | sonnet | Vulnerability analysis (OWASP Top 10) |
| `tdd-guide` | sonnet | Test-driven development with red-green-refactor |
| `refactor-cleaner` | sonnet | Dead code detection and safe removal |

## Team Mode

Claude automatically decides when to use agent teams based on task complexity:

- **Auto-team**: 3+ independent concerns or 4+ files triggers team creation
- **Single agent**: Simple tasks (bug fixes, single-file changes) run normally
- **Opt-out**: Say "single agent" or "no team" to force single mode

Protocol details: [`agents/team-protocol.md`](agents/team-protocol.md)

Key rules:
- Each file belongs to exactly one teammate (no concurrent edits)
- Shared types/interfaces are owned by their creator; dependents wait via `blockedBy`
- Teams run `/verify` after all tasks complete

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
| `detect-console-log.sh` | PostToolUse (Edit/Write) | Warn on `console.log` / `fmt.Println` |
| `go-vet.sh` | PostToolUse (Edit/Write) | Run `go vet` on Go file changes |
| `block-dev-server.sh` | PreToolUse (Bash) | Block long-running dev servers |
| `block-arbitrary-md.sh` | PreToolUse (Write) | Prevent creating arbitrary .md files |
| `notify.sh` | Stop / Notification | Desktop notification on task completion |

## Plugins

- `hookify` -- Hook management
- `commit-commands` -- `/commit`, `/commit-push-pr`
- `context7` -- Library documentation context

> `gopls-lsp`, `typescript-lsp` are enabled per-project, not globally.
