---
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
description: Systematically resolve build and type errors
---

## Build Error Resolution

### Process
1. **Detect**: Identify build system (go build, tsc, python, etc.)
2. **Run Build**: Execute build and capture all errors
3. **Triage**: Sort errors by dependency order (fix root causes first)
4. **Fix Loop**: For each error:
   a. Read the affected file and surrounding context
   b. Diagnose root cause (not just the symptom)
   c. Apply minimal surgical fix
   d. Re-run build to verify
5. **Report**: Summarize what was fixed and any remaining issues

### Safety Rules
- Fix ONE error at a time, rebuild after each
- Stop and ask the user if:
  - A fix creates more errors than it solves
  - Same error persists after 3 attempts
  - Fix requires architectural changes or new dependencies
- NEVER refactor unrelated code while fixing build errors
- Scope: build-blocking issues only

### Common Patterns
| Error Type | Strategy |
|-----------|----------|
| Missing import | Check exports, suggest install |
| Type mismatch | Compare definitions, fix types at source |
| Circular dependency | Map import graph, extract shared types |
| Version conflict | Check go.mod / package.json constraints |
| Missing method | Check interface requirements, add implementation |
