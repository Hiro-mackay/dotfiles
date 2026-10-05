# dotfiles

Development environment for macOS (nix-darwin + home-manager) and Linux dev
servers (home-manager), built from one flake. Each tool has a directory under
`programs/` holding its Nix module and plain config files; home-manager places
them read-only in `~`, so every machine gets the same result.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
```

`install.sh` installs Determinate Nix, clones this repo to `~/.dotfiles`, and
runs `nix run .#switch`. macOS needs the Xcode Command Line Tools; Linux needs
systemd and sudo.

## Update

```sh
nix run ~/.dotfiles#switch                        # apply after editing anything here
DOTFILES_HOST=minimal nix run ~/.dotfiles#switch  # restricted Mac: essential casks only
nix flake update --flake ~/.dotfiles              # bump inputs (also a weekly PR)
mise upgrade                                      # languages and dev tools
```

Manual steps after the first install: [docs/additional-setup.md](docs/additional-setup.md).
Design and decisions: [docs/nix-plan.md](docs/nix-plan.md).
