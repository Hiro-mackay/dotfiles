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

# The numtide binary cache serves Codex prebuilt; without it Nix compiles Codex from
# source. On macOS nix-darwin keeps it in determinateNix.customSettings afterwards.
CACHE_CONF="extra-substituters = $NUMTIDE_CACHE
extra-trusted-public-keys = $NUMTIDE_KEY"

if [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
    log "Installing Determinate Nix"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
        sh -s -- install --no-confirm --extra-conf "$CACHE_CONF"
elif [ "$OS" = Linux ] && ! grep -qs "$NUMTIDE_CACHE" /etc/nix/nix.conf /etc/nix/nix.custom.conf; then
    log "Adding the numtide binary cache to /etc/nix/nix.custom.conf"
    printf '%s\n' "$CACHE_CONF" | sudo tee -a /etc/nix/nix.custom.conf >/dev/null
    # The daemon reads its configuration only at startup.
    sudo systemctl restart nix-daemon.service determinate-nixd.service 2>/dev/null || true
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

if [ ! -d "$DOTFILES/.git" ]; then
    [ ! -e "$DOTFILES" ] || die "$DOTFILES exists but is not a git checkout; move it away first"
    log "Cloning $REPO_URL to $DOTFILES"
    nix run nixpkgs#git -- clone "$REPO_URL" "$DOTFILES"
fi

if [ "$OS" = Linux ] && ! command -v docker >/dev/null 2>&1; then
    log "Installing Docker Engine"
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$(id -un)"
fi

if [ "$OS" = Darwin ] && [ -f /etc/nix/nix.custom.conf ] && [ ! -L /etc/nix/nix.custom.conf ]; then
    # The installer writes this file and the determinate module manages it, so
    # nix-darwin would stop with "Unexpected files in /etc". The running daemon keeps
    # the cache settings, and determinateNix.customSettings writes them back.
    log "Moving the installer's /etc/nix/nix.custom.conf aside for nix-darwin"
    sudo mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin
fi

log "Applying the configuration"
cd "$DOTFILES"
nix run .#switch

if [ "$OS" = Linux ] && [ "$(basename "${SHELL:-}")" != zsh ]; then
    log "To make zsh the login shell:"
    # shellcheck disable=SC2016 # printed literally for the user to run
    printf '  command -v zsh | sudo tee -a /etc/shells && chsh -s "$(command -v zsh)"\n'
fi
log "Done. Open a new terminal. Manual steps: docs/additional-setup.md"
