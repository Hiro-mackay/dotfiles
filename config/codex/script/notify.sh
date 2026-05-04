#!/bin/bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')
project=$(basename "${cwd:-Codex}")
notification_type=$(echo "$input" | jq -r '.notification_type // .type // empty')

notify() {
  if command -v terminal-notifier >/dev/null 2>&1; then
    terminal-notifier "$@" >/dev/null 2>&1 &
  fi
}

case "$notification_type" in
  "permission_prompt" | "approval-requested")
    notify -title "Codex" -subtitle "$project" -message "許可待ち" -sound "Ping"
    ;;
  "idle_prompt")
    notify -title "Codex" -subtitle "$project" -message "入力待ち" -sound "Purr"
    ;;
  "stop" | "agent-turn-complete")
    notify -title "Codex" -subtitle "$project" -message "タスク完了" -sound "Glass"
    ;;
  *)
    notify -title "Codex" -subtitle "$project" -message "通知" -sound ""
    ;;
esac
