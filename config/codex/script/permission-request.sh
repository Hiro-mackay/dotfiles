#!/bin/bash
# Codex PermissionRequest hook (Bash matcher). Pre-approves common dev
# commands and short-circuits user prompts. Defense in depth: regex matching,
# not a security boundary. Complex/multi-statement commands fall through to
# the default approval flow (exit 0 with no decision).
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

[ -z "$cmd" ] && exit 0

respond() {
  local behavior=$1
  local message=${2:-}
  if [ -n "$message" ]; then
    jq -n --arg behavior "$behavior" --arg message "$message" '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: $behavior, message: $message }
      }
    }'
  else
    jq -n --arg behavior "$behavior" '{
      hookSpecificOutput: {
        hookEventName: "PermissionRequest",
        decision: { behavior: $behavior }
      }
    }'
  fi
}

deny_patterns=(
  '(^|[;&|[:space:]])sudo([[:space:]]|$)'
  '(^|[;&|[:space:]])git[[:space:]]+reset([[:space:]]|$)'
  '(^|[;&|[:space:]])git[[:space:]]+clean([[:space:]]|$)'
  '(^|[;&|[:space:]])rm[[:space:]]+-[^[:space:]]*r[^[:space:]]*f'
  '(^|[;&|[:space:]])rm[[:space:]]+-[^[:space:]]*f[^[:space:]]*r'
)

for pattern in "${deny_patterns[@]}"; do
  if printf '%s\n' "$cmd" | grep -Eq "$pattern"; then
    respond "deny" "Blocked by Codex command policy."
    exit 0
  fi
done

case "$cmd" in
  *$'\n'*)
    exit 0
    ;;
esac

if printf '%s\n' "$cmd" | grep -Eq '[;&|`]|[$][(]'; then
  exit 0
fi

allow_patterns=(
  '^(mkdir|touch|ls|tree|mv|cp|which|wc|diff|chmod)([[:space:]]|$)'
  '^(rg|npm|npx|pnpm|go|docker|stow|gh)([[:space:]]|$)'
  '^(python|python3|pip|pip3|bun|brew|pkill)([[:space:]]|$)'
  '^uv[[:space:]]+run[[:space:]]+python[[:space:]]+-c([[:space:]]|$)'
  '^git[[:space:]]+(status|diff|log|show|branch|add|stash|worktree|checkout|switch|fetch|commit|rebase)([[:space:]]|$)'
  '^codex[[:space:]]+debug[[:space:]]+prompt-input([[:space:]]|$)'
)

for pattern in "${allow_patterns[@]}"; do
  if printf '%s\n' "$cmd" | grep -Eq "$pattern"; then
    respond "allow"
    exit 0
  fi
done

exit 0
