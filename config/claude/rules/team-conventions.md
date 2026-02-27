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

1. **Role**: what this teammate is responsible for
2. **Files**: exhaustive list of files to create/modify (this is their ownership)
3. **Context**: relevant code snippets (not just paths -- actual code)
4. **Steps**: ordered implementation steps
5. **Boundary**: files and concerns that are OFF LIMITS
6. **Done**: "Mark task completed with TaskUpdate, then check TaskList for next task"

## Error Recovery
- If a teammate produces code that fails tests: reassign the fix to the SAME teammate (they have context)
- If a teammate is blocked by another's incomplete work: create a new task for the blocker, do not let the blocked teammate work around it
- If scope needs to change mid-flight: update the task description via TaskUpdate BEFORE reassigning

## Monitoring
- On idle notification: check if task is completed or blocked
- On file conflict: stop immediately, reassign ownership
- On 3 consecutive failures in same task: investigate root cause, assist, or reassign

## Completion
- After all tasks complete: verify (build, lint, test)
- Report changes to user grouped by teammate
- Graceful shutdown all teammates via shutdown_request
- Clean up team with TeamDelete
