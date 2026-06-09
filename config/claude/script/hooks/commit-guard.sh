#!/usr/bin/env bash
# PreToolUse(Bash) guard: require explicit confirmation for commits.
# Targets the reflex of committing without an explicit request. Works even in
# bypassPermissions because PreToolUse fires before the permission-mode check.
# Errs toward asking: a missed commit is the dangerous failure, an extra prompt
# is harmless. Push and PR creation are left to the normal permission flow.

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"

if printf '%s' "$cmd" | grep -Eq 'git[[:space:]].*commit'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "git commit -- approve only if you explicitly asked for it."
    }
  }'
fi
exit 0
