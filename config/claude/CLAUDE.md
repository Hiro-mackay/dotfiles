# Global Instructions

## Communication
- Respond in Japanese when the user writes in Japanese
- Use English for code, comments, and commit messages
- No emojis in code, comments, or documentation

## Workflow
- Explore -> Plan -> Code -> Verify -> Commit
- Use plan mode for 3+ steps or architectural decisions
- If something goes sideways, STOP and re-plan immediately -- don't keep pushing
- Verify: diff against main when relevant, ask "would a staff engineer approve this?"
- Run /verify before committing significant changes
- Use /compact at logical phase boundaries, not mid-task
- Use subagents for investigation to preserve main context
- /clear between unrelated tasks
- After ANY correction from the user, update memory files with the pattern to prevent recurrence
- Auto-team: default to team. Single only when 1 file AND 1 concern
- Team file ownership: each file belongs to exactly one teammate, no overlap

## Problem Solving
- Bug reports: fix autonomously -- don't ask for hand-holding, zero context switching for the user
- Find root causes -- no temporary fixes
- For non-trivial changes, pause: "is there a more elegant way?" Skip for simple, obvious fixes

## Git
- Conventional commits: type(scope): description
- Types: feat, fix, refactor, docs, test, chore
- Atomic commits, imperative mood, no period
- Always review diff before committing

## Files
- IMPORTANT: Do NOT create .md files unless the user explicitly asks
- Keep intermediate notes in context, not in files

## Code
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Remove console.log / fmt.Println before committing
- IMPORTANT: No hardcoded secrets — use environment variables
