#!/bin/bash
set -euo pipefail

# Codex skill bridge.
#
# Layout (set up by setup-link.sh):
#   ~/.codex -> ~/.config/codex -> ~/.dotfiles/config/codex
#
# This script populates ~/.dotfiles/config/codex/skills/ with dir-symlinks to
# every Claude skill (~/.config/claude/skills/<name>). Path-filtered skills
# (go-principles, sql-implementation, etc.) are unified into the same skills/
# tree as on-demand skills, so a single dir-symlink per skill suffices.
#
# skills/ is gitignored: it is fully reconstructible from this script.

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
claude_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/claude"
claude_skills_dir="${claude_dir}/skills"
codex_skills_dir="$dotfiles_dir/skills"

mkdir -p "$codex_skills_dir"

shopt -s nullglob

# Sweep orphans: symlinks whose Claude source no longer exists.
# Skip dot-prefixed entries (.system is Codex-managed, .DS_Store etc are noise).
# Real directories are left in place to avoid clobbering user-created skills.
for entry in "$codex_skills_dir"/*; do
  [[ -e "$entry" || -L "$entry" ]] || continue
  name="$(basename "$entry")"
  [[ "$name" == .* ]] && continue
  [[ -d "$claude_skills_dir/$name" ]] && continue
  if [[ -L "$entry" ]]; then
    rm "$entry"
    echo "cleaned orphan symlink: $name" >&2
  fi
done

if [[ -d "$claude_skills_dir" ]]; then
  for skill_path in "$claude_skills_dir"/*/; do
    ln -sfn "${skill_path%/}" "$codex_skills_dir/$(basename "$skill_path")"
  done
else
  echo "warn: $claude_skills_dir missing; skipping skill symlinks" >&2
fi

shopt -u nullglob
