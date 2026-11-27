#!/bin/sh
# Links the phone's Termux and proot Debian setup to this checkout. Nix does not run
# there, so these links are how updates arrive: after a `git pull` they take effect.
# Run inside proot with the dotfiles at /root/dotfiles; safe to re-run.
set -eu
D=/root/dotfiles/programs
T=/data/data/com.termux/files
# The same checkout as Termux sees it from outside proot.
TD=$T/usr/var/lib/proot-distro/containers/debian/rootfs$D

mkdir -p /root/.claude /root/.config "$T/home/.shortcuts"
ln -sfn "$D/agents" /root/.config/agents
ln -sf "$D/termux/claude-settings.json" /root/.claude/settings.json
ln -sf "$D/termux/claude-CLAUDE.md" /root/.claude/CLAUDE.md
ln -sf "$D/claude/pstack-models.md" /root/.claude/pstack-models.md
ln -sf "$TD/termux/vault-session" "$T/usr/bin/vault-session"
# Termux:Widget runs only files whose real path is under ~/.shortcuts, so the
# shortcut is a stub instead of a link.
printf '#!%s/usr/bin/sh\nexec %s/termux/vault-widget "$@"\n' "$T" "$TD" >"$T/home/.shortcuts/vault"
chmod +x "$T/home/.shortcuts/vault"
