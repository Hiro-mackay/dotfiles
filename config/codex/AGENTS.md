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

## Delegation & Review
- For independent or parallelizable work (codebase search, multi-file investigation, isolated implementation), delegate to a subagent to keep the main context clean
- After writing or modifying code, run a review pass (self-review or a dedicated reviewer subagent) before declaring the task done

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
