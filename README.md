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
At the end it sets up GitHub: it signs you in with gh, creates
and registers the SSH key, and asks whether this machine needs other accounts. Running
it again is safe.

## After installing

1. Sign in: `claude` and `codex`.
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

The base account and its key (`~/.ssh/id_ed25519_github`) work for every GitHub
repository; install sets them up. Another account is tied to the owners of its
repositories, with its identity and its key switching together, so a commit and the
push never mix accounts. Install offers it; to add it later:

```sh
gh-account <owner>...    # e.g. gh-account my-org
```

It signs in to that account in the browser, asks for a short name (e.g. `work`) and
the name and email for its commits, creates and registers its key, and writes:

```
~/.gitconfig.accounts    the base account, and which owners use which other account
~/.gitconfig.<name>      one other account: [user] and its key (core.sshCommand)
```

It matches remotes of those owners in any directory, also while cloning. Check inside a
repository with `git config --show-origin user.email`.

## SSH

`~/.ssh/config` stays yours; nothing here manages it. GitHub needs nothing in it (see
Git accounts). To add a server:

```sh
ssh-setup <name> <server>    # e.g. ssh-setup devbox 10.0.0.5
```

It shows the Host block with defaults (key `~/.ssh/id_ed25519_<name>`); press Enter to
write it, or `e` to edit. It creates the key if missing (you choose the passphrase) and
prints the public key. Options set values up front: `-u` user, `-p` port, `-i` key
file, `-A` agent forwarding.

For a local container with sshd on a published port, e.g.
`ssh-setup -p 2222 -u dev sandbox 127.0.0.1`. Create the key before the container
copies your public keys into its `authorized_keys`.

## Updates

Every Monday, CI updates the pinned versions (`flake.lock`). Each update waits a week
on the `flake-update/pending` branch before it reaches `main`, so a bad upstream
release has time to surface; delete that branch to skip an update. Known critical
vulnerabilities (CVSS 9+) are reported in an issue.
