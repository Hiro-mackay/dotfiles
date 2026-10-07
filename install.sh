#!/bin/sh
# Bootstrap: install Determinate Nix, clone this repo to ~/.dotfiles, then apply
# the configuration with `nix run .#switch`. Safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
set -eu

DOTFILES="${HOME}/.dotfiles"
OS="$(uname -s)"

log() { printf '==> %s\n' "$*"; }

if [ "$OS" = Darwin ] && ! xcode-select -p >/dev/null 2>&1; then
    log "Installing the Xcode Command Line Tools"
    # softwareupdate lists the Command Line Tools only while this file exists (as
    # Homebrew's installer does). Without a listing, fall back to the dialog and wait.
    placeholder=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    touch "$placeholder"
    label="$(softwareupdate -l 2>/dev/null | sed -n 's/^\* Label: \(Command Line Tools.*\)$/\1/p' | sort -V | tail -n 1)"
    if [ -n "$label" ]; then
        sudo softwareupdate -i "$label"
        sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi
    rm -f "$placeholder"
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install || true
        log "Finish the Command Line Tools dialog; waiting for it"
        until xcode-select -p >/dev/null 2>&1; do sleep 5; done
    fi
fi

if [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
    log "Installing Determinate Nix"
    # The numtide binary cache serves Codex prebuilt; without it Nix compiles Codex from
    # source. On macOS nix-darwin keeps it in determinateNix.customSettings afterwards.
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
        sh -s -- install --no-confirm --extra-conf "extra-substituters = https://cache.numtide.com
extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
fi
# shellcheck disable=SC1091
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

[ -d "$DOTFILES/.git" ] || nix run nixpkgs#git -- clone https://github.com/Hiro-mackay/dotfiles.git "$DOTFILES"

# GitHub: the base account first (Enter takes it), then any others this machine needs.
# Before applying, so every question comes first and mise installs with a token.
# Interactive, so only with a terminal (stdin is the curl pipe); gh-setup repeats it.
if [ -t 1 ] && (: </dev/tty) 2>/dev/null; then
    while :; do
        nix run "$DOTFILES#gh-setup" </dev/tty || log "Run 'gh-setup' to retry"
        printf '\nAnother GitHub account? [y/N]: '
        read -r answer </dev/tty || answer=
        case "$answer" in [yY]*) ;; *) break ;; esac
    done
fi

if [ "$OS" = Linux ] && ! command -v docker >/dev/null 2>&1; then
    log "Installing Docker Engine"
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$(id -un)"
fi

if [ "$OS" = Darwin ] && [ -f /etc/nix/nix.custom.conf ] && [ ! -L /etc/nix/nix.custom.conf ]; then
    # The installer writes this file and the determinate module manages it, so
    # nix-darwin would stop with "Unexpected files in /etc". The file also holds the
    # numtide cache settings, which stop applying once it moves, so build first while
    # they apply (nothing gets compiled); determinateNix.customSettings writes them back.
    log "Building the configuration"
    nix build --impure --no-link "$DOTFILES#darwinConfigurations.default.system"
    log "Moving the installer's /etc/nix/nix.custom.conf aside for nix-darwin"
    sudo mv /etc/nix/nix.custom.conf /etc/nix/nix.custom.conf.before-nix-darwin
fi

log "Applying the configuration"
cd "$DOTFILES"
# --force: activate even when nothing changed, so a rerun repairs a half-applied setup.
nix run .#switch -- --force

if [ "$OS" = Linux ] && [ "$(basename "${SHELL:-}")" != zsh ]; then
    log "To make zsh the login shell:"
    # shellcheck disable=SC2016 # printed literally for the user to run
    printf '  command -v zsh | sudo tee -a /etc/shells && chsh -s "$(command -v zsh)"\n'
fi

log "Done. Open a new terminal. Remaining steps: docs/cookbook.md, After installing."

# Trackpad, appearance and other macOS settings take effect only after a restart.
# Ask first (work may be open) and restart the normal way, so apps can ask to save.
# stdin is the curl pipe, so the answer comes from the terminal.
if [ "$OS" = Darwin ] && [ -t 1 ]; then
    printf '==> Restart now to apply the macOS settings? [y/N] '
    read -r answer </dev/tty || answer=
    case "$answer" in
    [yY]*) osascript -e 'tell application "loginwindow" to «event aevtrrst»' ;;
    esac
fi
