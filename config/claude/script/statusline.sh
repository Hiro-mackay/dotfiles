#!/bin/bash
# Claude Code status line: model | bar | %context | $session | today/block/burn
# ccusage extension is failsafe: falls back to base display if unavailable.
export PATH="$HOME/.cache/.bun/bin:$PATH"
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

RED='\033[31m'; YELLOW='\033[33m'; GREEN='\033[32m'; DIM='\033[2m'; RESET='\033[0m'
if [ "$PCT" -ge 80 ]; then COLOR="$RED"
elif [ "$PCT" -ge 60 ]; then COLOR="$YELLOW"
else COLOR="$GREEN"; fi

FILLED=$((PCT / 10))
EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

LEFT=$(printf "${DIM}%s${RESET} ${COLOR}%s %d%%${RESET} ${DIM}\$%.2f${RESET}" \
              "$MODEL" "$BAR" "$PCT" "$COST")

if command -v ccusage >/dev/null 2>&1; then
  CCUSAGE=$(printf '%s' "$input" | ccusage statusline --offline 2>/dev/null)
  TODAY=$(echo "$CCUSAGE" | grep -oE '\$[0-9.]+ today' | head -1)
  BLOCK=$(echo "$CCUSAGE" | grep -oE '\$[0-9.]+ block \([^)]+\)' | head -1)
  BURN=$(echo "$CCUSAGE" | grep -oE '\$[0-9.]+/hr' | head -1)
  if [ -n "$TODAY" ]; then
    echo -e "${LEFT} ${DIM}| ${TODAY} / ${BLOCK} / ${BURN}${RESET}"
    exit 0
  fi
fi
echo -e "$LEFT"
