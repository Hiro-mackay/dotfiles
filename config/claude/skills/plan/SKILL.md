---
name: plan
description: Create an implementation plan for a feature or task
disable-model-invocation: true
argument-hint: "[feature or task description]"
context: fork
agent: planner
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch
---

## Plan: $ARGUMENTS

## Process

1. **Read**: Read input completely -- every section, no skipping
2. **Extract**: Extract all requirements into a checklist
3. **Explore**: Find existing code patterns, conventions, and related code
4. **Check state**: For each requirement: done / partial / missing
5. **Plan**: Create steps for ALL missing/partial work

NEVER narrow scope. If the input has 10 sections, the plan covers all 10.

## Output Format

### Coverage Checklist
Every input section -> status (done/partial/missing)

### Patterns Found
Conventions to follow (file:line refs)

### Implementation Steps
Ordered list. Each step is a self-contained unit of work:
- File path to create/modify
- What to change and why
- Acceptance criteria
- Complexity: small (<30 lines) / medium (30-200 lines or 1-3 files) / large (>200 lines or architectural)

### Testing Strategy
What tests to write and where

### Risks
Potential issues and how to mitigate them
