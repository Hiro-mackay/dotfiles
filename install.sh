#!/bin/sh
# Bootstrap: install Determinate Nix, clone this repo to ~/.dotfiles, then apply
# the configuration with `nix run .#switch`. Safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
set -eu

REPO_URL="https://github.com/Hiro-mackay/dotfiles.git"
DOTFILES="${HOME}/.dotfiles"
OS="$(uname -s)"
NUMTIDE_CACHE="https://cache.numtide.com"
NUMTIDE_KEY="niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="

log() { printf '==> %s\n' "$*"; }
die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

[ "$(id -u)" -ne 0 ] || die "run as your normal user, not root (sudo is used where needed)"

case "$OS" in
Darwin)
    xcode-select -p >/dev/null 2>&1 || {
        xcode-select --install || true
        die "install the Xcode Command Line Tools (dialog opened), then re-run"
    }
    ;;
Linux)
    # The Nix daemon needs systemd; without it only root could use Nix.
    [ -d /run/systemd/system ] || die "systemd is required (containers without systemd are not supported)"
    if ! command -v curl >/dev/null 2>&1; then
        log "Installing curl"
        sudo apt-get update -qq
        sudo apt-get install -y -qq curl ca-certificates
    fi
    ;;
*) die "unsupported OS: $OS" ;;
esac

if [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
    log "Installing Determinate Nix"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

if [ "$OS" = Linux ] && ! grep -qs "$NUMTIDE_CACHE" /etc/nix/nix.custom.conf; then
    # On macOS nix-darwin writes this through determinateNix.customSettings.
    log "Adding the numtide binary cache (Codex) to /etc/nix/nix.custom.conf"
    printf 'extra-substituters = %s\nextra-trusted-public-keys = %s\n' "$NUMTIDE_CACHE" "$NUMTIDE_KEY" |
        sudo tee -a /etc/nix/nix.custom.conf >/dev/null
    sudo systemctl restart nix-daemon.service || true
fi

if [ ! -d "$DOTFILES/.git" ]; then
    [ ! -e "$DOTFILES" ] || die "$DOTFILES exists but is not a git checkout; move it away first"
    log "Cloning $REPO_URL to $DOTFILES"
    nix run nixpkgs#git -- clone "$REPO_URL" "$DOTFILES"
fi

if [ "$OS" = Linux ]; then
    # Root-owned locations that point into the user's home-manager files, so later
    # edits need no sudo. Assumes one user per server.
    log "Linking /etc/codex and Claude Code managed settings"
    share="$HOME/.local/share/dotfiles/etc"
    sudo mkdir -p /etc/codex /etc/claude-code/managed-settings.d
    sudo ln -sfn "$share/codex/config.toml" /etc/codex/config.toml
    sudo ln -sfn "$share/claude-code/10-nix.json" /etc/claude-code/managed-settings.d/10-nix.json

    if ! command -v docker >/dev/null 2>&1; then
        log "Installing Docker Engine"
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker "$(id -un)"
    fi
fi

log "Applying the configuration"
cd "$DOTFILES"
nix run .#switch

if [ "$OS" = Linux ] && [ "$(basename "${SHELL:-}")" != zsh ]; then
    log "To make zsh the login shell:"
    printf '  command -v zsh | sudo tee -a /etc/shells && chsh -s "$(command -v zsh)"\n'
fi
log "Done. Open a new terminal. Manual steps: docs/additional-setup.md"
