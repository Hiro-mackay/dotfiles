#!/usr/bin/env bash
set -euo pipefail

bootstrap_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/agent-setup.XXXXXX")"
fixture="$(cd -- "$fixture" && pwd)"
trap 'rm -r -- "$fixture"' EXIT
repo="$fixture/repo with spaces"
mkdir -p "$repo/bootstrap" "$repo/config/agents/skills/shared" \
  "$repo/config/agents/skills/native" "$repo/config/codex/skills/native" \
  "$repo/config/claude/skills" "$fixture/external"
cp "$bootstrap_dir/setup-agents.sh" "$repo/bootstrap/"
ln -s "$repo" "$fixture/repo-alias"
printf 'Shared instructions\n' > "$repo/config/agents/AGENTS.md"
printf 'Native skill\n' > "$repo/config/codex/skills/native/SKILL.md"
ln -s "$fixture/repo-alias/config/agents/skills/deleted" "$repo/config/codex/skills/deleted"
ln -s "$fixture/external" "$repo/config/codex/skills/external"
ln -s "$fixture/missing" "$repo/config/claude/skills/external-missing"

for run in 1 2; do
  bash "$repo/bootstrap/setup-agents.sh"
  cmp "$repo/config/agents/AGENTS.md" "$repo/config/codex/AGENTS.md"
  for host in claude codex; do
    [[ "$(readlink "$repo/config/$host/skills/shared")" == "../../agents/skills/shared" ]] || exit 1
  done
  [[ ! -L "$repo/config/codex/skills/deleted" ]] || exit 1
  [[ -d "$repo/config/codex/skills/external" ]] || exit 1
  [[ -L "$repo/config/claude/skills/external-missing" ]] || exit 1
  [[ ! -L "$repo/config/codex/skills/native" ]] || exit 1
  [[ "$(cat "$repo/config/codex/skills/native/SKILL.md")" == 'Native skill' ]] || exit 1
done

printf 'PASS: repeatable setup, alternate checkout, managed cleanup, external links, native skills\n'
