#!/bin/bash
# PreToolUse hook: Block dev server commands outside tmux
input=$(cat)
cmd=$(echo "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);console.log(i.tool_input?.command||'')}catch{}})")
if [ -z "$TMUX" ] && echo "$cmd" | grep -qE '(npm run dev|pnpm dev|yarn dev|bun run dev)\b'; then
  echo "[Hook] BLOCKED: Dev server must run in tmux" >&2
  echo "[Hook] Use: tmux new-session -d -s dev \"$cmd\"" >&2
  exit 2
fi
