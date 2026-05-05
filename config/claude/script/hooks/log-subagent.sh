#!/bin/bash
# Subagent observability hook.
#
# Fires on SubagentStart and SubagentStop. Schema discovered empirically
# (see subagent-raw.log for examples). Key fields:
#   - agent_id: stable across Start/Stop -- use as correlation key
#   - agent_type: the subagent type name (Explore, sonnet-executor, etc.)
#   - session_id: the parent Claude Code session
#   - last_assistant_message (Stop only): final response text -- detect BLOCKED here
#   - agent_transcript_path (Stop only): full subagent JSONL transcript
#
# Outputs:
#   ~/.claude/logs/subagent.log       structured JSONL for analysis
#   ~/.claude/logs/subagent-raw.log   raw input dumps (dev only, can drop later)
#
# Failures are silent: hooks must never break the harness.
set -euo pipefail

LOG_DIR="${HOME}/.claude/logs"
LOG_FILE="${LOG_DIR}/subagent.log"
RAW_FILE="${LOG_DIR}/subagent-raw.log"

mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

input=$(cat 2>/dev/null || true)
[ -z "$input" ] && exit 0

ts="$(date -u +%FT%TZ)"
event=$(printf '%s' "$input" | jq -r '.hook_event_name // "unknown"' 2>/dev/null || echo "unknown")
agent=$(printf '%s' "$input" | jq -r '.agent_type // "unknown"' 2>/dev/null || echo "unknown")
agent_id=$(printf '%s' "$input" | jq -r '.agent_id // "unknown"' 2>/dev/null || echo "unknown")
session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")

# Stop-only fields
last_msg=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || echo "")
transcript=$(printf '%s' "$input" | jq -r '.agent_transcript_path // empty' 2>/dev/null || echo "")

# BLOCKED detection: scan last message for "BLOCKED" prefix
blocked=""
if [ -n "$last_msg" ] && printf '%s' "$last_msg" | head -c 200 | grep -q "BLOCKED"; then
  blocked="true"
fi

# Raw dump for ongoing schema visibility
printf '{"ts":%s,"input":%s}\n' \
  "$(printf '%s' "$ts" | jq -R '.')" \
  "$input" \
  >> "$RAW_FILE" 2>/dev/null || true

# Structured log
jq -nc \
  --arg ts "$ts" \
  --arg event "$event" \
  --arg agent "$agent" \
  --arg agent_id "$agent_id" \
  --arg session "$session" \
  --arg transcript "$transcript" \
  --arg blocked "$blocked" \
  '{ts: $ts, event: $event, agent: $agent, agent_id: $agent_id, session: $session}
   + (if $transcript != "" then {transcript: $transcript} else {} end)
   + (if $blocked != "" then {blocked: ($blocked == "true")} else {} end)' \
  >> "$LOG_FILE" 2>/dev/null || true

exit 0
