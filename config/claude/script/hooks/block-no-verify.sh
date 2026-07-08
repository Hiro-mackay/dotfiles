#!/bin/bash
# PreToolUse(Bash) hook: hard-block `git ... --no-verify` on hook-bearing
# subcommands (global AGENTS.md § Git). The rule exists as prose; this makes it
# mechanical -- the moment hooks fail is exactly when a bypass gets rationalized.
# Limitations: `git commit -n` (the shorthand) is not matched (collides with too
# many innocent flags), and quoting is not parsed -- a command that merely quotes
# the flag next to a mutating git subcommand (e.g. a commit message containing
# the literal string) also trips; reword it. Read-only git (log/diff/show) never
# trips, even with the flag string elsewhere on the line.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# git + up to a few global flags (-C <path>, -c k=v, ...) + a subcommand that
# runs hooks.
git_mutating='(^|[;&|([:space:]])git([[:space:]]+[^[:space:]]+){0,4}[[:space:]]+(commit|push|merge|rebase|am|cherry-pick|revert)([[:space:]]|$)'
if printf '%s' "$cmd" | grep -qE "$git_mutating" \
  && printf '%s' "$cmd" | grep -qE '(^|[[:space:]])--no-verify([[:space:]]|$)'; then
  echo "Blocked: 'git --no-verify' bypasses the commit/push hooks (global AGENTS.md, Git rules). Run the hooks and fix what fails; if a bypass is genuinely required, the user must run the command in their own terminal." >&2
  exit 2
fi
exit 0
