#!/usr/bin/env bash
set -euo pipefail

# Tool-neutral projector for the shared agents SSoT.
# Runs regardless of which agent CLIs are installed -- it only manipulates the
# dotfiles tree. Idempotent and safe to re-run.
#
# SSoT: config/agents/  (AGENTS.md + skills/<name>/)
# Projections (one-directional, source -> agent dirs):
#   - config/agents/AGENTS.md -> config/codex/AGENTS.md (real-file copy; Codex
#     does not follow file-symlinks). Claude reads the source via @import.
#   - config/agents/skills/<name> -> dir-symlink in config/claude/skills/ and
#     config/codex/skills/ (both agents follow directory symlinks).
# Projected skill symlinks are gitignored and fully reconstructible from here.

dotfiles_dir="${HOME}/.dotfiles"
agents_dir="${dotfiles_dir}/config/agents"
agents_skills="${agents_dir}/skills"
claude_skills="${dotfiles_dir}/config/claude/skills"
codex_skills="${dotfiles_dir}/config/codex/skills"

# 1. Keep the Codex real-file AGENTS.md copy in sync with the source.
if [[ -f "${agents_dir}/AGENTS.md" ]]; then
  cp "${agents_dir}/AGENTS.md" "${dotfiles_dir}/config/codex/AGENTS.md"
fi

mkdir -p "$claude_skills" "$codex_skills"
shopt -s nullglob

# 2. Sweep orphan skill symlinks whose source no longer exists.
for dir in "$claude_skills" "$codex_skills"; do
  for entry in "$dir"/*; do
    [[ -L "$entry" ]] || continue
    name="$(basename "$entry")"
    [[ "$name" == .* ]] && continue
    [[ -d "$agents_skills/$name" ]] && continue
    rm "$entry"
    echo "cleaned orphan skill symlink: $(basename "$dir")/$name" >&2
  done
done

# 3. Project each skill into both agent dirs (dir-symlink).
if [[ -d "$agents_skills" ]]; then
  for skill_path in "$agents_skills"/*/; do
    name="$(basename "$skill_path")"
    for dst in "$claude_skills/$name" "$codex_skills/$name"; do
      # Guard: never project into a real directory (a tool-native skill of the
      # same name). ln -sfn would otherwise create the link inside it.
      if [[ -d "$dst" && ! -L "$dst" ]]; then
        echo "skip: $dst is a real dir (name collides with a native skill); not projecting" >&2
        continue
      fi
      ln -sfn "${skill_path%/}" "$dst"
    done
  done
else
  echo "warn: $agents_skills missing; skipping skill projection" >&2
fi

shopt -u nullglob
echo "agents SSoT projected (skills -> claude+codex, AGENTS.md -> codex copy)"
