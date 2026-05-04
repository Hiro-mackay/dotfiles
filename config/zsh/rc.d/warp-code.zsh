# Spawn N parallel coding-agent sessions in a new Warp tab (current window) with split layout.
# Uses AppleScript / System Events keystrokes — requires Accessibility permission
# (granted on first run via macOS dialog).
#
# Layouts:
#   c2: left | right
#   c3: left | (right top / right bottom)
#   c4: 2x2 grid
#   c5+: N tabs each with a single agent session (no split)

_warp_agent_n() {
  local n=$1
  local command=$2
  local usage=$3

  if [[ ! "$n" =~ ^[1-9]$ ]]; then
    echo "usage: ${usage} where N is 1-9" >&2
    return 1
  fi

  if (( n == 1 )); then
    eval "$command"
    return
  fi

  local script=""

  case $n in
    2)
      script='
        keystroke "t" using {command down}
        delay 0.5
        keystroke "d" using {command down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
        keystroke "[" using {command down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
      '
      ;;
    3)
      # split right, then split-down on the right pane
      script='
        keystroke "t" using {command down}
        delay 0.5
        keystroke "d" using {command down}
        delay 0.3
        keystroke "d" using {command down, shift down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
        key code 126 using {command down, option down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
        key code 123 using {command down, option down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
      '
      ;;
    4)
      # split right, split-down right, focus left, split-down left → 2x2
      script='
        keystroke "t" using {command down}
        delay 0.5
        keystroke "d" using {command down}
        delay 0.3
        keystroke "d" using {command down, shift down}
        delay 0.3
        key code 123 using {command down, option down}
        delay 0.3
        keystroke "d" using {command down, shift down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
        key code 126 using {command down, option down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
        key code 124 using {command down, option down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
        key code 125 using {command down, option down}
        delay 0.3
        keystroke "'"${command}"'"
        delay 0.15
        key code 36
        delay 0.3
      '
      ;;
    *)
      # N >= 5: open N separate tabs (no split)
      for ((i=1; i<=n; i++)); do
        script+='
          keystroke "t" using {command down}
          delay 0.5
          keystroke "'"${command}"'"
          key code 36
          delay 0.2
        '
      done
      ;;
  esac

  osascript <<APPLE
tell application "Warp" to activate
delay 0.1
tell application "System Events"
  tell process "Warp"
    ${script}
  end tell
end tell
APPLE
}

_code_n() {
  _warp_agent_n "$1" ccode cN
}

alias c1='_code_n 1'
alias c2='_code_n 2'
alias c3='_code_n 3'
alias c4='_code_n 4'
alias c5='_code_n 5'
alias c6='_code_n 6'

_codex_n() {
  _warp_agent_n "$1" cx cxN
}

alias cx1='_codex_n 1'
alias cx2='_codex_n 2'
alias cx3='_codex_n 3'
alias cx4='_codex_n 4'
alias cx5='_codex_n 5'
alias cx6='_codex_n 6'
