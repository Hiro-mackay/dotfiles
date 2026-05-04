# Global Instructions

Shared cross-tool conventions live in AGENTS.md and are imported below.
Sections in this file are Claude Code harness-specific (Skills, Hooks, MCP,
auto-memory, plan mode, compaction, named subagents) and don't apply to
other coding agents.

@~/.codex/AGENTS.md

## Plan Mode & Session Boundaries
- Use EnterPlanMode for tasks of 3+ steps or architectural decisions
- /compact at logical phase boundaries; /clear between unrelated tasks

## Subagent Delegation (Claude Code)
- Invoke subagents explicitly via the Agent tool -- Opus 4.7 spawns fewer by default, so opt in deliberately
- Run code-reviewer / security-reviewer proactively after writing code

## Compaction
- Preserve across compactions: modified files, test commands & results, current task scope, user corrections from this session
