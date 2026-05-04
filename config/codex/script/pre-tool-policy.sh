#!/bin/bash
# Codex PreToolUse hook (Bash matcher). Defense in depth: pattern-based denies
# of obviously destructive commands. Not a security boundary -- the boundary is
# sandbox_mode + approval_policy. Many bypasses exist (env indirection, $(),
# split tokens, etc); if you need a real guarantee, tighten the sandbox.
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

[ -z "$cmd" ] && exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
}

case "$cmd" in
  sudo\ * | *'; sudo '* | *'&& sudo '* | *'|| sudo '* | *'| sudo '*)
    deny "sudo is blocked in Codex. Run the exact command manually if needed."
    exit 0
    ;;
esac

if printf '%s\n' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+reset([[:space:]]|$)'; then
  deny "git reset is blocked because it can discard user work."
  exit 0
fi

if printf '%s\n' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+clean([[:space:]]|$)'; then
  deny "git clean is blocked because it can delete untracked user work."
  exit 0
fi

if printf '%s\n' "$cmd" | grep -Eq '(^|[;&|[:space:]])rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f|(^|[;&|[:space:]])rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r'; then
  deny "rm -rf is blocked because it is destructive."
  exit 0
fi

exit 0
