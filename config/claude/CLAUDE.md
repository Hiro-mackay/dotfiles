# Global Instructions

## Communication
- Respond in Japanese when the user writes in Japanese
- Use English for code, comments, and commit messages
- No emojis in code, comments, or documentation

## Workflow
- Explore -> Plan -> Code -> Verify -> Commit
- Run /verify before committing significant changes
- Use /compact at logical phase boundaries, not mid-task
- Use subagents for investigation to preserve main context
- /clear between unrelated tasks

## Git
- Conventional commits: type(scope): description
- Types: feat, fix, refactor, docs, test, chore
- Atomic commits, imperative mood, no period
- Always review diff before committing

## Code
- IMPORTANT: Keep files under 300 lines
- IMPORTANT: Remove console.log / fmt.Println before committing
- IMPORTANT: No hardcoded secrets — use environment variables

## Available Agents
- planner — Task decomposition and implementation planning
- architect — System design decisions (Opus)
- code-reviewer — Quality and security review
- security-reviewer — Vulnerability analysis (OWASP Top 10)
- tdd-guide — Test-driven development with red-green-refactor
