# Cookbook

## After installing

Sign in to `claude` and `codex`. On macOS, also allow Hammerspoon and Warp under
Accessibility, open Docker Desktop and run `sbx login`, and import
`programs/bettertouchtool/Default.bttpreset` in BetterTouchTool. On Linux, log in again
so the `docker` group applies.

## Update and apply

| To | Run |
|---|---|
| Get the latest config and tools | `dotup` (sudo only when the macOS configuration changed) |
| Apply your own edits in `~/.dotfiles` | `nix run ~/.dotfiles#switch`, then `mise install` if you changed tools |
| Run the whole install again | `sh ~/.dotfiles/install.sh` |
| List the shell shortcuts | `cheat` (topics: `git`, `docker`, `fzf`, `nav`, `util`, `dev`) |

Each tool's settings live in `programs/<tool>/`; edit them there and apply. The settings
screens of Claude Code and VS Code cannot save, because their files come from this repo.

## GitHub accounts

git and gh use gh's token over HTTPS (SSH URLs are rewritten), so no SSH key is needed.
The base account (`github.login` in `programs/git`) serves every repository.

Add another account with `gh-setup` (install runs it once): give its login, sign in in
the browser, pick the organizations it is for (its own repositories always are), and
press Enter for its GitHub name and noreply email. It writes:

```
~/.gitconfig.accounts    which owners use which other account
~/.gitconfig.<owner>     that account's name, email and login
```

In those owners' repositories, git commits and pushes, and gh runs, as that account;
elsewhere as the base one. `gh auth token` and `gh auth status` follow the same choice.
Check with `git config --show-origin user.email` or `gh api user --jq .login`.

Limits: a repository with remotes of both kinds takes the other account for all of them,
and a `pushurl` is not looked at.

## SSH hosts

`~/.ssh/config` is yours; nothing here manages it.

```sh
ssh-setup <name> <server>    # e.g. ssh-setup devbox 10.0.0.5
```

It shows the Host block (key `~/.ssh/id_ed25519_<name>`); Enter writes it, `e` edits.
It creates the key if missing and prints the public key. Options: `-u` user, `-p` port,
`-i` key file, `-A` agent forwarding. For a container with sshd on a published port:
`ssh-setup -p 2222 -u dev sandbox 127.0.0.1`.

## Sandboxes

`sbxc` runs Claude in an `sbx` sandbox named after the current directory and hands it
the GitHub token of the account this repository uses. Set `$SBX_TEMPLATE` to pass a
template.

## Pinned versions and security reports

Every Monday CI updates `flake.lock`; the update waits a week on the
`flake-update/pending` branch before reaching `main` (delete the branch to skip it).
Known CVSS 9+ vulnerabilities are reported in an issue; findings checked as false go in
`.github/vulnix-whitelist.toml`.
