# Team Protocol

Read this before creating a team. Follow every rule.

## Task Decomposition
- Identify independent concerns (API, UI, tests, infra, etc.)
- TaskCreate for each with clear acceptance criteria in description
- Set blockedBy for dependencies (e.g., tests blocked by implementation)

## File Ownership
- Each file belongs to exactly one teammate -- no exceptions
- Shared types/interfaces: creator owns them, others use blockedBy to wait
- Include owned file list in each teammate's spawn prompt

## Spawn Prompt Template
Every teammate prompt MUST include all six sections:

1. **Role**: What this teammate is responsible for
2. **Files**: Exhaustive list of files to create/modify (this is their ownership)
3. **Context**: Relevant code snippets (not just paths -- actual code)
4. **Steps**: Ordered implementation steps
5. **Boundary**: Files and concerns that are OFF LIMITS
6. **Done**: "Mark task completed with TaskUpdate, then check TaskList for next task"

## Monitoring
- On idle notification: check if task is completed or blocked
- On file conflict: stop immediately, reassign ownership
- On 3 consecutive failures in same task: investigate, assist, or reassign

## Completion
- After all tasks complete: run /verify
- Report changes to user grouped by teammate
- Graceful shutdown all teammates via shutdown_request
- Clean up team with TeamDelete
