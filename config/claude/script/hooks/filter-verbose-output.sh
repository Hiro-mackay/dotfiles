#!/bin/bash
# PreToolUse hook: Cap output of read-only commands that flood the context
# Reduces context token consumption; truncation is announced so the agent can narrow the command
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

[ -z "$cmd" ] && { echo '{}'; exit 0; }

# Chained or already-redirected commands: appending a pipe would rebind to the last segment only
case "$cmd" in
  *'|'*|*'>'*|*'<'*|*'&&'*|*';'*) echo '{}'; exit 0 ;;
esac

case "$cmd" in
  'git diff '*|'git diff')  limit=400 ;;
  'git show '*|'git show')  limit=400 ;;
  'git log '*|'git log')    limit=100 ;;
  'find '*)                 limit=200 ;;
  'tree '*|'tree')          limit=200 ;;
  'ls -R'*|'ls -lR'*)       limit=200 ;;
  *) echo '{}'; exit 0 ;;
esac

wrapped="set -o pipefail; $cmd 2>&1 | awk -v n=$limit 'NR<=n{print} NR==n+1{print \"... [truncated at \" n \" lines by filter-verbose-output hook; narrow the command to see more]\"}'"

jq -nc --arg c "$wrapped" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",updatedInput:{command:$c}}}'
