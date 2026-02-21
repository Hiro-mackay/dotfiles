#!/bin/bash
# PreToolUse hook: Block creation of arbitrary .md files
input=$(cat)
file=$(echo "$input" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const i=JSON.parse(d);console.log(i.tool_input?.file_path||'')}catch{}})")
if [ -n "$file" ] && echo "$file" | grep -qiE '\.md$'; then
  if ! echo "$file" | grep -qiE '/(README|CLAUDE|AGENTS|CONTRIBUTING|CHANGELOG|MEMORY)\.md$' && \
     ! echo "$file" | grep -qiE '/(rules|agents|commands|contexts|skills|plans)/'; then
    echo "[Hook] BLOCKED: Creating arbitrary .md files is not allowed." >&2
    echo "[Hook] Allowed: README.md, CLAUDE.md, AGENTS.md, or files in rules/agents/commands/contexts/skills/plans/" >&2
    exit 2
  fi
fi
