#!/bin/bash
# Claude Code status line: model | context bar | $session | 5h/7d remaining as battery
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

RED='\033[31m'; YELLOW='\033[33m'; GREEN='\033[32m'; DIM='\033[2m'; RESET='\033[0m'

# color by how much is used (context) or how little is left (battery)
color_used() {
  if [ "$1" -ge 80 ]; then printf '%b' "$RED"
  elif [ "$1" -ge 60 ]; then printf '%b' "$YELLOW"
  else printf '%b' "$GREEN"; fi
}

FILLED=$((PCT / 10))
BAR=$(printf "%${FILLED}s" | tr ' ' '█')$(printf "%$((10 - FILLED))s" | tr ' ' '░')
LINE=$(printf "${DIM}%s${RESET} %b%s %d%%${RESET} ${DIM}\$%.2f${RESET}" \
              "$MODEL" "$(color_used "$PCT")" "$BAR" "$PCT" "$COST")

# rate_limits is absent for API-key users and before the first response.
# Battery shows what is LEFT: 5 cells, filled = remaining, plus reset time.
battery() {
  local label=$1 key=$2 used left cells resets
  used=$(echo "$input" | jq -r ".rate_limits.$key.used_percentage // empty" | cut -d. -f1)
  [ -z "$used" ] && return
  left=$((100 - used)); [ "$left" -lt 0 ] && left=0
  cells=$(((left + 10) / 20))
  resets=$(echo "$input" | jq -r ".rate_limits.$key.resets_at // empty")
  [ -n "$resets" ] && resets=" ${DIM}$(date -r "$resets" +%m/%d\ %H:%M)${RESET}"
  printf " ${DIM}|${RESET} %s %b[%s%s] %d%%${RESET}%b" "$label" "$(color_used "$used")" \
    "$(printf "%${cells}s" | tr ' ' '▮')" "$(printf "%$((5 - cells))s" | tr ' ' '▯')" "$left" "$resets"
}

echo -e "${LINE}$(battery 5h five_hour)$(battery 7d seven_day)"
