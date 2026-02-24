#!/bin/bash
# PostToolUse hook: Detect debug statements in JS/TS/Go/Python files after edits
input=$(cat)
file=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[ -z "$file" ] && exit 0
[ ! -f "$file" ] && exit 0

# JS/TS: console.log
if echo "$file" | grep -qE '\.(js|ts|jsx|tsx)$'; then
  matches=$(grep -n 'console\.log' "$file" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "[Hook] console.log detected in $file:" >&2
    echo "$matches" >&2
  fi
fi

# Go: fmt.Print/Println/Printf (debug statements)
if echo "$file" | grep -qE '\.go$'; then
  matches=$(grep -n 'fmt\.Print\(ln\|f\)\?' "$file" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "[Hook] fmt.Print* detected in $file:" >&2
    echo "$matches" >&2
  fi
fi

# Python: print() (debug prints, not logging)
if echo "$file" | grep -qE '\.py$'; then
  matches=$(grep -n '^[[:space:]]*print(' "$file" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "[Hook] print() detected in $file:" >&2
    echo "$matches" >&2
  fi
fi
