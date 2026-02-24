#!/bin/bash
# Claude Code status line: model, context usage, cost
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Color thresholds
RED='\033[31m'; YELLOW='\033[33m'; GREEN='\033[32m'; DIM='\033[2m'; RESET='\033[0m'
if [ "$PCT" -ge 80 ]; then COLOR="$RED"
elif [ "$PCT" -ge 60 ]; then COLOR="$YELLOW"
else COLOR="$GREEN"; fi

# Progress bar (10 chars)
FILLED=$((PCT / 10))
EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%${EMPTY}s" | tr ' ' '░')

echo -e "${DIM}${MODEL}${RESET} ${COLOR}${BAR} ${PCT}%${RESET} ${DIM}\$$(printf '%.2f' "$COST")${RESET}"
