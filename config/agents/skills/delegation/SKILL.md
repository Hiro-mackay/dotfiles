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
- Anything you can finish yourself in a handful of tool calls
- 1-2 file edits
- Sequential edit -> test -> fix loops
- Work where design decisions surface mid-implementation

When unsure, inline is the correct default. If a session never hits these triggers, zero delegations is the right outcome -- measure parallelism captured, not delegation count.

## Model per spawn
Pass the model on the Agent tool's `model` parameter; default is inherit (main model).
- Exploration, broad search, mechanical batch work -> `sonnet`. Speed dominates these tasks and quality differences don't surface; inheriting the main model buys nothing
- Hardest design work (architecture with unclear shape, multi-system trade-offs) -> `fable`, only when I explicitly ask for it. My explicit request overrides the delegation gate above -- never pick fable as your own choice. In plan mode, the harness's own Plan-agent phase counts as an explicit route
- Review agents forked via `/review-local` / `/security-audit` / `/critique` keep the model declared in their agent definition

## Script, agent, or inline
Before spawning an agent for a sweep, pick the cheapest reliable tool:
- Mechanical checks (existence, cross-references, counts, format validation) -> write a deterministic script. Agent comprehension misreports exactly this class of work; a script is rerunnable, diffable, and does not hallucinate
- Full-corpus scan where only a semantic judgment can decide -> agent
- Transforming one to a few known files -> inline
If a check can be expressed as a script, the script IS the deliverable -- do not delegate it to agent reading.

## Batch reliability contract
When delegating batch work over N items:
- The agent reports counts: N given, K skipped (named), M processed, and M = N - K must hold. Silently narrowing scope is a defect, not a judgment call
- A "done" claim requires passing a mechanical check (script, test, grep) after the work; the agent's own completion report is not verification

## Parallel spawning
Send one batch of independent tasks in a single message (multiple agent calls). Sequential calls are not parallel; use them only when Task B depends on Task A, tasks edit the same file, or scopes overlap. Sweet spot: 3-5 agents; beyond that coordination cost usually exceeds gains -- batch into waves.

If one agent can do the whole task, spawn one rather than several. Splitting work that isn't genuinely independent doubles cost and wall-time instead of halving it.

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
