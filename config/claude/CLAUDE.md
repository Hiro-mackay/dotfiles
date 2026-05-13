# Global Instructions

## Voice
- Match the user's language: 日本語 in -> 日本語 out
- Code, comments, and commit messages: English
- No emojis in code, documentation, or output
- Be concise; skip filler and trailing summaries

## Workflow
- Explore -> Plan -> Code -> Verify -> Commit
- 3+ steps or architectural decisions: EnterPlanMode before coding
- Re-plan as soon as the plan diverges from reality
- Bug reports: investigate the root cause; don't patch symptoms
- Non-trivial changes: pause once and ask "is there a simpler shape?"

## Agent Coordination
- The active agent owns the requested work end to end
- Choose tools and agents by task fit, context, and verification needs
- Cross-provider review is a quality technique, not a hierarchy
- When handing work between agents, preserve scope, modified files, validation results, and unresolved risks
- Shared skills and conventions apply to all agents unless an agent-specific file says otherwise

## Code Constraints
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Secrets live in environment variables -- never hardcoded
- No features, abstractions, or fallbacks beyond what the task requires
- No comments unless the WHY is non-obvious; no current-task references in comments

## Git
- Conventional commits: `type(scope): description` (feat/fix/refactor/docs/test/chore)
- Atomic commits, imperative mood, no period
- Review the diff before each commit
- Never `--no-verify`, `--force`, or `reset --hard` without explicit user request

## Fixing Errors
- Run the project's own tools to diagnose
- Keep linter rules and tool configs as-is
- Stay within the scope of the failing change
- Escalate to the user after 3 failed attempts or when the fix needs architectural changes

## Subagent Delegation

### Orchestrator-Executor

The goal is wall-time reduction via parallelism. Forcing delegation on a 1-2
file serial edit adds spec-writing, round-trip, and verification cost without
parallel benefit. When in doubt, do it inline.

#### When to delegate to sonnet-executor

Delegate when ANY of:
- 3+ independent file edits with non-overlapping scope
- 10+ uniform mechanical operations

Do NOT delegate when:
- 1-2 file edit
- Sequential edit -> test -> fix loop
- The task references prior conversation decisions the executor cannot see

When the executor returns BLOCKED, read Progress / Blocker / Branches and
handle directly. Do not re-delegate the same ambiguity.

#### Parallel spawning

When delegating, send one batch of independent tasks. Sequential agent calls
are not parallel and should be used only when Task B depends on Task A, tasks
edit the same file, or scopes overlap.

Sweet spot: 3-5 parallel agents. Beyond 5, coordination overhead usually
exceeds gains; batch into waves of 3-5.

#### Spawn prompt template

A good spawn prompt is self-contained:

```
Task: <one-line goal>

Files:
- <path>: <what changes>

Spec:
<concrete behavior to implement; include parameters, edge cases, format>

Constraints:
- <project conventions, existing patterns to follow>
- <validation command to run>

Acceptance:
- <observable check that confirms the task is done>
```

## Reviewers
- Run code-reviewer / security-reviewer proactively after writing code
- Code-reviewer applies language-specific skills for Go, TypeScript, React, Python, SQL, Docker, and related domains
- For substantial changes, use cross-provider independent review when it improves confidence
- Findings should lead with severity, file:line, impact, trigger, and suggested fix

## Session Boundaries
- Compact at logical phase boundaries; clear between unrelated tasks
- Preserve across compactions: modified files, test commands and results, current task scope, user corrections from this session
