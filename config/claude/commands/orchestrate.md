---
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Task, TeamCreate, TeamDelete, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage
description: Run phased workflows mixing single/team and serial/parallel execution
---

## Orchestrate

Phased workflow execution. Usage: `/orchestrate <workflow> <target>`

Read `~/.claude/agents/team-protocol.md` before starting.

## Required Agents

Never skip these. Additional agents may be added per task.

| Workflow | Required Agents |
|----------|----------------|
| **feature** | `planner`, `tdd-guide`, `security-reviewer`, `code-reviewer` |
| **bugfix** | `planner`, `tdd-guide`, `code-reviewer` |
| **refactor** | `planner`, `refactor-cleaner`, `code-reviewer` |
| **security** | `security-reviewer`, `code-reviewer`, `planner` |

## Phases

### 1. Plan -- single, serial
Spawn `planner` with the target file. Wait for completion.

### 2. Implement -- team, parallel
`TeamCreate` -> `TaskCreate` per sub-task -> spawn teammates in parallel.
Each teammate gets: assigned files, requirements, and boundary (what NOT to touch).

Impl agents per workflow:
- feature / bugfix: `tdd-guide` per sub-task
- refactor: `refactor-cleaner` per sub-task
- security: `tdd-guide` per remediation item

### 3. Review -- team, parallel (after all Phase 2)
Spawn reviewers with assigned file groups. Split files for parallel review.
Findings that need fixes -> assign back to impl teammates.

### 4. Finalize -- single, serial
All reviews pass -> `/verify` -> report -> shutdown teammates -> `TeamDelete`.

## Monitoring
- On idle: check task completion or assist blocked agents
- On file conflict: stop, reassign ownership
- On 3 consecutive failures: investigate and reassign
