# dotfiles

Development environment for macOS (nix-darwin + home-manager) and Linux dev
servers (home-manager), built from one flake. Settings live in `config/`, and
`~/.config` is a symlink to it.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
```

`install.sh` installs Determinate Nix, clones this repo to `~/.dotfiles`, and
runs `nix run .#switch`. macOS needs the Xcode Command Line Tools; Linux needs
systemd and sudo.

## Update

```sh
nix run ~/.dotfiles#switch                        # apply after editing
DOTFILES_HOST=minimal nix run ~/.dotfiles#switch  # restricted Mac: essential casks only
nix flake update --flake ~/.dotfiles              # bump inputs (also a weekly PR)
mise upgrade                                      # languages and dev tools
```

Manual steps after the first install: [docs/additional-setup.md](docs/additional-setup.md).
Design and decisions: [docs/nix-plan.md](docs/nix-plan.md).
