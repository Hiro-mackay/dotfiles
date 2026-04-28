# Global Instructions

## Voice & Communication
- Match the user's language: Japanese in -> Japanese out
- Code, comments, and commit messages: English
- No emojis in code or documentation

## Working Style
- Workflow: Explore -> Plan -> Code -> Verify -> Commit
- EnterPlanMode for tasks of 3+ steps or architectural decisions
- Re-plan as soon as the plan diverges from reality
- /compact at logical phase boundaries; /clear between unrelated tasks
- Bug reports: investigate the root cause and fix autonomously
- Non-trivial changes: pause once and ask "is there a simpler shape?"

## Subagent Delegation
- Invoke subagents explicitly via the Agent tool for codebase search, multi-file investigation, and parallelizable work -- Opus 4.7 spawns fewer by default, so opt in deliberately
- Run code-reviewer / security-reviewer proactively after writing code

## Memory
- After any user correction, update the relevant memory file so the pattern persists across sessions
- Treat memory as the durable store; conversation context is ephemeral

## Git
- Conventional commits: type(scope): description (feat/fix/refactor/docs/test/chore)
- Atomic commits, imperative mood, no period
- Review the diff before each commit

## Files
- IMPORTANT: Create .md files only when the user explicitly asks
- Keep intermediate notes in conversation, not on disk

## Code
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Secrets live in environment variables -- never hardcoded

## Compaction
- Preserve across compactions: modified files, test commands & results, current task scope, user corrections from this session

## Fixing Errors
- Run the project's own tools to diagnose
- Keep linter rules and tool configs as-is
- Stay within the scope of the failing change
- Escalate to the user after 3 failed attempts or when the fix needs architectural changes
