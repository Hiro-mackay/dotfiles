---
root: true
targets:
  - '*'
globs:
  - '**/*'
---
# Global Instructions

## Voice
- Match my language; in Japanese use 常体 (だ/である), not 敬体 (です/ます)
- Plain language: no jargon, coined terms, or "principle" labels
- Grounded tone: no hype or motivational framing; assume competence
- Code, comments, and commit messages: English
- Be concise: skip filler and trailing summaries; no emojis in output

## Workflow
- 3+ steps or architectural decisions: make the plan explicit before starting
- Fix the root cause, not the symptom
- Non-trivial changes: pause once and ask "is there a simpler shape?"

## Collaboration
- Stay in the requested scope; don't solve unrequested problems or add tooling I won't use
- When my intent is ambiguous, ask before acting -- don't build on a guess
- Verify state yourself (read files, run git status) instead of asking what you can check
- Lead with a recommendation, not a menu of options
- Challenge weak reasoning; don't agree just to agree

## Code Constraints
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Secrets live in environment variables -- never hardcoded
- No features, abstractions, or fallbacks beyond what the task requires
- No comments unless the WHY is non-obvious; no current-task references in comments

## Git
- IMPORTANT: Never commit, push, or open a PR unless I explicitly ask in this session -- finishing work is not a trigger
- Conventional commits: `type(scope): description` (feat/fix/refactor/docs/test/chore)
- Atomic commits, imperative mood, no period
- Review the diff before each commit
- Never `--no-verify`, `--force`, or `reset --hard` without explicit request

## Fixing Errors
- Diagnose with the project's own tools; keep linter rules and configs as-is
- Stay within the scope of the failing change
- If the same fix fails twice, change approach -- don't retry variants
- Escalate after 3 failed attempts or when the fix needs architectural change

## Reviewers
- Run code-reviewer / security-reviewer proactively after writing code
- Substantial changes: add cross-provider review (Claude <-> Codex)

## Context
- Preserve across compaction/summarization: modified files, test commands and results, current task scope, user corrections
