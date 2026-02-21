#!/bin/bash
# PostToolUse hook: Run go vet after editing Go files
input=$(cat)
file=$(echo "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);console.log(i.tool_input?.file_path||i.tool_input?.path||'')}catch{}})")
if [ -n "$file" ] && echo "$file" | grep -qE '\.go$'; then
  dir=$(dirname "$file")
  output=$(cd "$dir" && go vet ./... 2>&1) || true
  if [ -n "$output" ]; then
    echo "[Hook] go vet issues:" >&2
    echo "$output" >&2
  fi
fi
