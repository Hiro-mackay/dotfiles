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

### Orchestrator-Executor
For mechanical tasks where the spec is clear and files are identified, delegate to sonnet-executor. The subagent does not see this conversation or CLAUDE.md, so include file paths, spec, and validation commands in the spawn prompt.

When the executor returns BLOCKED, read Progress / Blocker / Branches and handle directly. Do not re-delegate.

#### Parallel spawning
Identify task independence before delegating. 2+ [EXEC] tasks that do not share files or dependencies should spawn in parallel -- per Anthropic agent guidance, parallel spawning of 3-5 subagents cuts wall time by up to 90% on suitable workloads.

How to spawn concurrently: send a SINGLE message with multiple Agent tool_use blocks. Sequential Agent calls (one per turn) are NOT concurrent -- they wait for each completion.

Sweet spot: 3-5 parallel agents. Beyond ~5 the coordination overhead exceeds gains -- batch into waves of 3-5 instead.

Sequential is correct when: Task B uses Task A's output, tasks edit the same file, or task scopes overlap.

#### Spawn prompt template
A good spawn prompt is self-contained. Use this structure:

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

Example:
```
Task: Add email validation to user creation

Files:
- src/api/users.ts: validateUser() function

Spec:
Reject emails not matching RFC 5322 simple regex. Return 400 with
{"error": "invalid_email"} on invalid input.

Constraints:
- Use Zod schema (matches existing validation in src/api/)
- Run: npm test src/api/users.test.ts

Acceptance:
- Existing tests pass; new test for invalid email returns 400
```

### Reviewers
- Run code-reviewer / security-reviewer proactively after writing code

## Compaction
- Preserve across compactions: modified files, test commands & results, current task scope, user corrections from this session
