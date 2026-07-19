# Global Instructions

## Voice
- Match my language; in Japanese use 常体 (だ/である), not 敬体 (です/ます)
- Plain language: no jargon, coined terms, or "principle" labels
- Grounded tone: no hype or motivational framing; assume competence
- Code, comments, and commit messages: English
- Generated prose (issue bodies, PR descriptions, review findings, status reports) is Japanese too -- English is only for code, comments, and commit messages
- Be concise: skip filler and trailing summaries; no emojis in output
- IMPORTANT: Any Japanese prose that describes or explains something -- issue bodies, design docs, reports, notes, and explanations written to me in chat -- applies the `japanese-tech-writing` skill. Unconditional; skip only for one-or-two-line replies. Its 一文一行 rule is for prose written to files, not chat responses
- When that prose is meant to be read as a piece (a walkthrough, a rationale, an explanation of how something works -- in chat as much as in a file, not only articles), layer `cognitive-rhythm-writing` on top. Still lead with the conclusion; the rhythm rules govern the body, not the order

## Workflow
- 3+ steps or architectural decisions: enter plan mode and make the plan explicit before starting
- Architectural decisions, unclear design shape, or multi-system changes: have the planner subagent draft the plan
- Fix the root cause, not the symptom
- Before reporting a change as done, run it and observe the behavior; tests and type-checks alone are not verification
- Never assert a dependency or tool version as "latest" from memory -- verify against the official registry or release notes first
- Non-trivial changes: pause once and ask "is there a simpler shape?"
- Delegate to parallel subagents only at 3+ independent file edits or 10+ uniform mechanical ops; otherwise work inline (see `delegation` skill for spawn template). Exception: broad searches go to a subagent that returns the conclusion, not the file contents
- Read only the range you need: locate with Grep first, then Read with offset/limit. Never read a whole file to find one symbol, and never re-read a file already read this session

## Collaboration
- Stay in the requested scope; don't solve unrequested problems or add tooling I won't use
- When my intent is ambiguous, ask before acting -- don't build on a guess
- Verify state yourself (read files, run git status) instead of asking what you can check
- Lead with a recommendation, not a menu of options
- Challenge weak reasoning; don't agree just to agree

## Code Constraints
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Secrets live in environment variables -- never hardcoded
- Before writing code, stop at the first rung that holds: (1) does this need to exist? skip if speculative; (2) stdlib does it? use it; (3) native platform feature? use it; (4) installed dep solves it? use it; (5) one line? write one line; (6) only then: minimum that works
- No features, abstractions, or fallbacks beyond what the task requires
- IMPORTANT: Write zero comments by default. One is allowed ONLY if it is (1) a doc comment the language's tooling or a public API contract requires, (2) a fact the code cannot state -- an external spec, a workaround for someone else's bug, a forced ordering, a non-obvious invariant -- or (3) a deliberate simplification with its upgrade trigger. Everything else (restating WHAT the code does, section headers, narrating the change or the task) is not written, and is deleted when found
- An allowed comment is 1 line, 2 at most. Wanting more means the fix is naming or structure, not prose
- When writing or reviewing code, apply the `readable-code` and `naming-conventions` skills -- enforce them above the project's default bar
- When implementing business logic, apply the `ddd-principles` skill

## Git
- IMPORTANT: Never commit, push, or open a PR unless I explicitly ask in this session -- finishing work is not a trigger
- Conventional commits: `type(scope): description` (feat/fix/refactor/docs/test/chore)
- Atomic commits, imperative mood, no period
- Review the diff before each commit
- Never `--no-verify`, `--force`, or `reset --hard` without explicit request

## Fixing Errors
- Diagnose with the project's own tools; keep linter rules and configs as-is
- Stay within the scope of the failing change
- If the same fix fails twice, stop patching: discard the accumulated hypotheses and re-diagnose from the raw evidence before the next attempt
- Escalate after 3 failed attempts or when the fix needs architectural change

## Reviewers
- Run code-reviewer / security-reviewer proactively after writing code
- After implementing or modifying UI components or styles: run design-reviewer as well

## Context
- Preserve across compaction/summarization: modified files, test commands and results, current task scope, user corrections
