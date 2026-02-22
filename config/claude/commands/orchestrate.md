---
allowed-tools: Read, Glob, Grep, Bash
description: Run sequential agent workflows for features, bugfixes, refactors, and security audits
---

## Agent Orchestration

Coordinate multiple agents in predefined workflows. Usage: `/orchestrate <workflow> <target>`

### Workflows

**feature** -- Build a new feature end-to-end:
1. `planner` -- Decompose into tasks and create implementation plan
2. `tdd-guide` -- Implement with red-green-refactor cycle
3. `code-reviewer` -- Review for quality and maintainability
4. `security-reviewer` -- Check for vulnerabilities

**bugfix** -- Diagnose and fix a bug:
1. `planner` -- Analyze root cause and plan the fix
2. `tdd-guide` -- Write regression test, then fix
3. `code-reviewer` -- Review the fix

**refactor** -- Clean up existing code:
1. `planner` -- Identify refactoring targets and plan
2. `refactor-cleaner` -- Remove dead code first
3. `code-reviewer` -- Review refactored code

**security** -- Full security audit:
1. `security-reviewer` -- Vulnerability scan (OWASP Top 10)
2. `code-reviewer` -- General quality review
3. `planner` -- Prioritize and plan remediation

### Handoff Protocol
After each agent completes, create a handoff document:
- **Findings**: Key results from the agent
- **Files touched**: List of modified or reviewed files
- **Open items**: Issues for the next agent to address
- **Status**: PASS / WARN / FAIL

### Stop Conditions
- **Critical finding**: Stop workflow, report immediately
- **Tests failing**: Stop, do not proceed to review
- **Agent blocked**: Report blocker, skip to next agent if independent
