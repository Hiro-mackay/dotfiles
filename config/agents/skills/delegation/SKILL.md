---
name: delegation
description: When and how to delegate to subagents for parallelism -- fan-out triggers, parallel spawning, spawn-prompt template, handoff, and escalation format. Apply when deciding whether to delegate work or spawn parallel agents.
---

# Delegation

Delegate to reduce wall-time through parallelism, not to "use a cheaper model." When there is no parallelism to capture, inline is faster -- spec-writing, round-trip latency, and verifying the summary cost more than a 1-2 file edit.

## When to delegate
- 3+ independent file edits with non-overlapping scope -> parallel spawn
- 10+ uniform mechanical operations (mass rename, fixture regen, port bumps) -> bulk offload
- Large-output investigation (reading many files) -> investigation subagent, so the main context stays clean

Do NOT delegate:
- 1-2 file edits
- Sequential edit -> test -> fix loops
- Work where design decisions surface mid-implementation

When unsure, inline is the correct default. If a session never hits these triggers, zero delegations is the right outcome -- measure parallelism captured, not delegation count.

## Parallel spawning
Send one batch of independent tasks in a single message (multiple agent calls). Sequential calls are not parallel; use them only when Task B depends on Task A, tasks edit the same file, or scopes overlap. Sweet spot: 3-5 agents; beyond that coordination cost usually exceeds gains -- batch into waves.

## Spawn prompt template
A good spawn prompt is self-contained:

```
Task: <one-line goal>

Files:
- <path>: <what changes>

Spec:
<concrete behavior; parameters, edge cases, format>

Constraints:
- <conventions to follow; validation command to run>

Acceptance:
- <observable check that confirms the task is done>
```

## Handoff
When handing work between agents, preserve scope, modified files, validation results, and unresolved risks.

## Escalation
When blocked, return:
- **Progress**: what was completed before the block
- **Blocker**: the specific ambiguity
- **Branches**: 2-3 candidate interpretations to choose from

Do not re-delegate the same ambiguity -- surface it and let the orchestrator decide.
