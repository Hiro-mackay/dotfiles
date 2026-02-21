#!/bin/bash
# PostToolUse hook: Detect console.log in JS/TS files after edits
input=$(cat)
file=$(echo "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);console.log(i.tool_input?.file_path||i.tool_input?.path||'')}catch{}})")
if [ -n "$file" ] && echo "$file" | grep -qE '\.(js|ts|jsx|tsx)$'; then
  matches=$(grep -n 'console\.log' "$file" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "[Hook] console.log detected in $file:" >&2
    echo "$matches" >&2
  fi
fi
