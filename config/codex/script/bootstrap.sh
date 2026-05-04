#!/bin/bash
set -euo pipefail

# Codex skill bridge.
#
# Layout (set up by setup-link.sh):
#   ~/.codex -> ~/.config/codex -> ~/.dotfiles/config/codex
#
# This script populates ~/.dotfiles/config/codex/skills/ with:
#   - dir-symlinks to every Claude skill (~/.config/claude/skills/<name>)
#   - hardlinked SKILL.md per Claude path-filtered rule, since Codex's skill
#     loader does not follow file-level symlinks. Hardlinks share an inode
#     so local edits flow both ways without re-bootstrapping. After a git
#     pull replaces a rule file (new inode), re-run.
#
# skills/ is gitignored: it is fully reconstructible from this script.

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
claude_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/claude"
claude_skills_dir="${claude_dir}/skills"
claude_rules_dir="${claude_dir}/rules"
codex_skills_dir="$dotfiles_dir/skills"

mkdir -p "$codex_skills_dir"

shopt -s nullglob

# Sweep orphans: entries whose Claude source no longer exists.
# Skip dot-prefixed entries (.system is Codex-managed, .DS_Store etc are noise).
# Symlinks are removed unconditionally; real directories are removed only if
# they look like a rule bridge (a single SKILL.md, no other content) so a
# user-created skill in skills/ never gets clobbered.
for entry in "$codex_skills_dir"/*; do
  [[ -e "$entry" || -L "$entry" ]] || continue
  name="$(basename "$entry")"
  [[ "$name" == .* ]] && continue
  if [[ -d "$claude_skills_dir/$name" || -f "$claude_rules_dir/$name.md" ]]; then
    continue
  fi
  if [[ -L "$entry" ]]; then
    rm "$entry"
    echo "cleaned orphan symlink: $name" >&2
  elif [[ -d "$entry" && -f "$entry/SKILL.md" ]]; then
    contents=( "$entry"/* )
    if [[ ${#contents[@]} -eq 1 && "$(basename "${contents[0]}")" == "SKILL.md" ]]; then
      rm -rf "$entry"
      echo "cleaned orphan rule-bridge: $name" >&2
    else
      echo "warn: $name has extra content; left in place" >&2
    fi
  fi
done

if [[ -d "$claude_skills_dir" ]]; then
  for skill_path in "$claude_skills_dir"/*/; do
    ln -sfn "${skill_path%/}" "$codex_skills_dir/$(basename "$skill_path")"
  done
else
  echo "warn: $claude_skills_dir missing; skipping skill symlinks" >&2
fi

if [[ -d "$claude_rules_dir" ]]; then
  for rule_path in "$claude_rules_dir"/*.md; do
    rule_name="$(basename "$rule_path" .md)"
    skill_dir="$codex_skills_dir/$rule_name"
    mkdir -p "$skill_dir"
    ln -f "$rule_path" "$skill_dir/SKILL.md"
  done
else
  echo "warn: $claude_rules_dir missing; skipping rule->skill bridge" >&2
fi
shopt -u nullglob
