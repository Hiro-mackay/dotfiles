---
allowed-tools: Read, Glob, Grep, Edit, Write, Bash, Task, TeamCreate, TeamDelete, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage
description: Run phased workflows mixing single/team and serial/parallel execution
---

## Orchestrate

Phased workflow execution. Each phase uses the optimal execution mode.
Usage: `/orchestrate <workflow> <target>`

**Read agents/team-protocol.md before starting.**

## Required Agents (Guardrails)

These agents MUST run for each workflow. Never skip them.

| Workflow | Required Agents | Purpose |
|----------|----------------|---------|
| **feature** | `planner`, `tdd-guide`, `security-reviewer`, `code-reviewer` | Security + quality always checked |
| **bugfix** | `planner`, `tdd-guide`, `code-reviewer` | Regression test always written first |
| **refactor** | `planner`, `refactor-cleaner`, `code-reviewer` | Dead code always removed first |
| **security** | `security-reviewer`, `code-reviewer`, `planner` | Dual review always performed |

Additional agents may be added based on the task, but required agents cannot be removed.

## Phased Execution

### Phase 1: Plan -- single, serial

One `planner` agent produces a coherent plan. Do NOT parallelize planning.

Output:
- Sub-tasks with acceptance criteria
- File ownership per sub-task (one file = one owner)
- Dependencies between sub-tasks

### Phase 2: Implement -- team, parallel

`TeamCreate` -> `TaskCreate` per sub-task -> spawn teammates in parallel.

| Workflow | Teammates |
|----------|-----------|
| **feature** | `tdd-guide` per sub-task (split by file ownership) |
| **bugfix** | `tdd-guide` per sub-task |
| **refactor** | `refactor-cleaner` per sub-task |
| **security** | `tdd-guide` per remediation item |

- Each teammate owns a set of files -- no overlap
- Follow spawn prompt template from team-protocol.md (Role, Files, Context, Steps, Boundary, Done)
- All impl teammates run in parallel

### Phase 3: Review -- team, parallel (blocked by all Phase 2)

Start ONLY after all Phase 2 tasks are completed.

| Workflow | Teammates |
|----------|-----------|
| **feature** | `code-reviewer` + `security-reviewer` (parallel, split by file groups) |
| **bugfix** | `code-reviewer` |
| **refactor** | `code-reviewer` |
| **security** | `security-reviewer` + `code-reviewer` (parallel, split by file groups) |

- Reviewers can split files among themselves for parallel review
- Each reviewer reports findings -> fix loop if needed (assign back to impl teammate)

### Phase 4: Finalize -- single, serial

1. All reviews pass -> run `/verify`
2. Report changes grouped by phase and teammate
3. `shutdown_request` to all teammates
4. `TeamDelete`

## Execution Mode Summary

| Phase | Mode | Why |
|-------|------|-----|
| Plan | single, serial | Coherent plan needs one mind |
| Implement | team, parallel | Independent files, max throughput |
| Review | team, parallel | Independent reviews, blocked by impl |
| Finalize | single, serial | Verification needs full picture |

## Monitoring

- On idle: check task completion or assist blocked agents
- On file conflict: stop immediately, reassign ownership
- On 3 consecutive failures: investigate and reassign
