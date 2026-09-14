#!/usr/bin/env zsh
set -eu

bootstrap_dir="${0:a:h}"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/claude-setup.XXXXXX")"
trap 'rm -r -- "$fixture"' EXIT
export XDG_CONFIG_HOME="$fixture/config"
mkdir -p "$XDG_CONFIG_HOME/claude/script"
statusline="$XDG_CONFIG_HOME/claude/script/statusline.sh"
print -r -- '#!/bin/sh' > "$statusline"
calls="$fixture/calls"

claude() {
    print -r -- "$*" >> "$calls"
    case "$*" in
        --version) print -r -- 'Claude Code test' ;;
        'mcp get codebase-memory-mcp') [[ "$registered" == yes ]] ;;
        'mcp add -s user codebase-memory-mcp -- codebase-memory-mcp') ;;
        *) return 1 ;;
    esac
}

codebase-memory-mcp() { return 0; }
curl() { return 99; }

for registered in yes no; do
    : > "$calls"
    chmod 600 "$statusline"
    (source "$bootstrap_dir/setup-claude.sh")
    [[ -x "$statusline" ]] || exit 1
    {
        print -r -- '--version'
        print -r -- 'mcp get codebase-memory-mcp'
        if [[ "$registered" == no ]]; then
            print -r -- 'mcp add -s user codebase-memory-mcp -- codebase-memory-mcp'
        fi
    } > "$fixture/expected"
    diff -u "$fixture/expected" "$calls"
done

print -r -- 'PASS: one version check, statusline permissions, existing and new MCP registration'
