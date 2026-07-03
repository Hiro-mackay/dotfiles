# dotfiles

macOS development environment setup

## Install

Prerequisite: `xcode-select --install`

```sh
# Remote (one-shot): download a snapshot and run setup
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | zsh

# Local (clone for git-based updates), then run setup
git clone https://github.com/Hiro-mackay/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh
```

Re-apply anytime with `~/.dotfiles/install.sh`.

## Docs

- [Git identity & secret guardrail](docs/git-identity-and-secrets.md)
- [英数/かな key switching (Hammerspoon)](docs/eisu-kana-key.md)
