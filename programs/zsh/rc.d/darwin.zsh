# =================
#  macOS only (included by programs/zsh/default.nix on macOS)
# =================
alias op="open ."
alias pwdcp='printf %s "$PWD" | pbcopy'
alias cpb="tee >(ghead -c -1 | pbcopy)"
alias em="emacs"

# -----------------
#  clipboard
# -----------------
jc() {
  pbpaste | jq . | pbcopy && pbpaste
}

# -----------------
#  claude sandbox (sbx)
# -----------------
# Run `claude` inside an `sbx` sandbox named after the current directory, so
# re-running from the same dir reuses the same sandbox instead of spawning a
# new one each time. Warns (but doesn't block) if that name is already bound
# to a different directory. Set $SBX_TEMPLATE to pass a template to `sbx run`.
sbxc() {
  local slug
  slug=$(printf '%s' "${PWD:t}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  [[ -z $slug ]] && slug="sandbox-$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)"
  local name=claude-${slug[1,56]%%-}

  local bound
  bound=$(sbx ls 2>/dev/null | awk -v n="$name" '$1 == n { print $NF }')
  [[ -n $bound && $bound != $PWD ]] && print -u2 "sbxc: '$name' is bound to $bound, not $PWD"

  local -a cmd=(sbx run claude --name "$name")
  [[ -n $SBX_TEMPLATE ]] && cmd+=(-t "$SBX_TEMPLATE")

  "$cmd[@]" "$@"
}

# -----------------
#  claude remote control
# -----------------
# Start a Remote Control session in the current dir for lid-closed mobile
# use: keep the Mac awake (lid closed too) and pause Power Nap for the
# session. Low Power Mode is left to the global "on battery" setting. Both
# are restored on exit (incl. Ctrl-C / kill, but not a hard power loss), so
# verify when idle with:
#   pmset -g | grep -i sleep   # SleepDisabled should be 0
#
# SECURITY: --dangerously-skip-permissions bypasses every approval prompt
# because a lid-closed mobile session cannot answer them. The agent then runs
# with full, unattended permissions. Launch ccgo only from a trusted working
# directory -- never anywhere a destructive command (rm -rf, etc.) or a prompt
# injection could do real damage without anyone watching.
ccgo() {
  trap 'sudo pmset -a disablesleep 0; sudo pmset -b powernap 1' EXIT INT TERM
  sudo pmset -a disablesleep 1   # stay awake lid-closed
  sudo pmset -b powernap 0       # no background wake during the session
  claude --remote-control "${PWD:t}" --dangerously-skip-permissions
}
