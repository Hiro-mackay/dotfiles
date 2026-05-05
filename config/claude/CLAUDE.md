# Global Instructions

## Voice
- Match the user's language: 日本語 in -> 日本語 out
- Code, comments, and commit messages: English
- Be concise; skip filler and trailing summaries

## Workflow
- Explore -> Plan -> Code -> Verify -> Commit
- 3+ steps or architectural decisions: EnterPlanMode before coding
- Re-plan as soon as the plan diverges from reality
- Bug reports: investigate the root cause; don't patch symptoms
- Non-trivial changes: pause once and ask "is there a simpler shape?"

## Code constraints
- IMPORTANT: Keep files under 500 lines
- IMPORTANT: Secrets live in environment variables -- never hardcoded

## Git
- Conventional commits: `type(scope): description` (feat/fix/refactor/docs/test/chore)
- Atomic commits, imperative mood, no period
- Review the diff before each commit
- Never `--no-verify`, `--force`, or `reset --hard` without explicit user request

## Fixing errors
- Run the project's own tools to diagnose
- Keep linter rules and tool configs as-is
- Stay within the scope of the failing change
- Escalate to the user after 3 failed attempts or when the fix needs architectural changes

## Subagent Delegation

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
- For substantial changes, invoke `/codex:review` for cross-provider independent review

## Session Boundaries
- /compact at logical phase boundaries; /clear between unrelated tasks
- Preserve across compactions: modified files, test commands & results, current task scope, user corrections from this session
