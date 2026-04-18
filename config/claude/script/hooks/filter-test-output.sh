#!/bin/bash
# PreToolUse hook: Filter test command output to show only failures
# Reduces context token consumption by removing passing test noise
input=$(cat)
cmd=$(echo "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);console.log(i.tool_input?.command||'')}catch{}})")

if echo "$cmd" | grep -qE '^(npm test|npx jest|npx vitest|pnpm test|pytest|go test)\b'; then
  filtered_cmd="$cmd 2>&1 | tail -80"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$filtered_cmd\"}}}"
else
  echo "{}"
fi
