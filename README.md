# dotfiles

My development environment for macOS and Linux dev servers. One Nix flake sets up
both: nix-darwin and home-manager on macOS, home-manager on Linux.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
```

It installs the Xcode Command Line Tools (macOS) and Nix, clones this repo to
`~/.dotfiles`, and applies the configuration. It asks for your password when it
needs sudo, and on macOS it offers a restart at the end, which some settings need.
Running it again is safe.

## After installing

1. Sign in: `gh auth login`, then `claude` and `codex`.
2. macOS only:
   - Allow Hammerspoon and Warp in System Settings → Privacy & Security →
     Accessibility, then choose Reload Config in Hammerspoon's menu.
   - Open Docker Desktop once and run `sbx login`.
   - Import `programs/bettertouchtool/Default.bttpreset` in BetterTouchTool.
3. Linux only: log in again so the `docker` group applies. To push from a server,
   connect with `ssh -A`.

## Everyday use

| To | Run |
|---|---|
| Get the latest config and tool versions | `dotup` |
| Apply your own edits in `~/.dotfiles` | `nix run ~/.dotfiles#switch` |

Each tool's settings are in `programs/<tool>/`. Edit them there and apply them. The
settings screens of Claude Code and VS Code cannot save, because their files come
from this repo.

## Git accounts

The base account works with no setup. Each machine keeps its accounts in one file,
`~/.gitconfig.accounts`, which the first install creates and you can edit:

```
~/.config/git/config     shared settings from this repo; then reads the next file
~/.gitconfig.accounts    the base account, and which repositories use another one
~/.gitconfig.local       the other account, if any
```

To use another account for some repositories:

1. In `~/.gitconfig.accounts`, uncomment one condition (a directory or a remote URL)
   and fill it in.
2. Put that account's `[user]` in `~/.gitconfig.local`.
3. Check with `git config --show-origin user.email` inside one of those repositories.

## SSH

`~/.ssh/config` stays yours; nothing here manages it. To add a host, run `ssh-setup`.
It asks for the host name, server, user, port and key file (Enter accepts each
default), creates the key if needed, appends the Host block and prints the public key.
For GitHub it can also add the key to the account gh is signed in to.

For two GitHub accounts on one machine, run it once per account, for example
`github.com` for the base account and `github.com-work` for the other. Then point the
other account's repositories at its host in `~/.gitconfig.accounts` (the
`url ... insteadOf` example there).

## Updates

Every Monday, CI updates the pinned versions (`flake.lock`). Each update waits a week
on the `flake-update/pending` branch before it reaches `main`, so a bad upstream
release has time to surface; delete that branch to skip an update. Known critical
vulnerabilities (CVSS 9+) are reported in an issue.
