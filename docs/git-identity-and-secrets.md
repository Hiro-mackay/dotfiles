# Machine-local Git identity & secret guardrail

This repo is **public**. The default identity in `config/git/config` is a GitHub
noreply address so nothing private is tracked. Use this setup when a machine
needs a different identity for some repos, without committing it here.

## Per-directory identity

`config/git/config` includes a machine-local file for repos under the ghq root:

```gitconfig
[includeIf "gitdir:~/Repository/"]
    path = ~/.gitconfig.local
```

Create the file on the machine (it lives **outside** this repo's working tree,
so it can never be staged):

```gitconfig
# ~/.gitconfig.local  (never committed)
[user]
    name  = <name>
    email = <email>
```

Notes:

- A **directory** condition (`gitdir:~/Repository/`) is used on purpose, not
  `hasconfig:remote.*.url:...`, so no remote/host string ends up in the tracked
  config.
- It applies only under `~/Repository/`, and is **silently ignored** when the
  file is absent — the default `[user]` stays in effect, no error.
- Keep such overrides in `$HOME`, never under `config/`. Dirs like `git/*`,
  `mise/*`, `brew/*`, `vscode/*` are broadly allowlisted in `config/.gitignore`,
  so any file dropped there would be tracked.

## Secret guardrail (git-secrets)

[`git-secrets`](https://github.com/awslabs/git-secrets) (in the Brewfile) is
wired into this repo's `config/git/hooks/pre-commit`. `bootstrap/setup-link.sh`
registers the identity from `~/.gitconfig.local` as a prohibited pattern, so
those values can never be committed here. Patterns are stored in this repo's
local git config and are **not** tracked.

Add more patterns by hand if needed:

```sh
git -C ~/.dotfiles secrets --add '<private-identifier>'
```

## Setup

```sh
# 1. Drop in the machine-local identity.
printf '[user]\n\tname = <name>\n\temail = <email>\n' > ~/.gitconfig.local

# 2. Re-run the linker to register git-secrets patterns from it.
~/.dotfiles/bootstrap/setup-link.sh
```

## Verification

```sh
git -C ~/Repository/<some-repo> config user.email   # -> the local identity
git -C ~/.dotfiles secrets --list                    # -> registered patterns
git -C ~/.dotfiles secrets --scan                    # -> clean
git grep -nI -e '<private-identifier>'               # -> no matches in tracked files
```

## Optional: skip GUI casks

Casks are split into three files under `config/brew/`:

- `Brewfile` — CLI tools (critical; aborts setup on failure)
- `Brewfile.cask` — essential casks (always attempted, non-fatal; e.g. Hammerspoon)
- `Brewfile.cask.optional` — optional GUI apps (non-fatal, skippable)

Set `DOTFILES_SKIP_CASKS=1` before running setup to skip only the **optional**
GUI apps (headless/CI or restricted machines). Essential casks are still
attempted; if a restricted machine blocks even those, install them by hand
(`brew install --cask hammerspoon`).

## Optional: Gatekeeper quarantine

`bootstrap/setup-macos.sh` can disable the "downloaded from the internet" check
(`LSQuarantine -bool false`). It is **opt-in** — set `DOTFILES_DISABLE_QUARANTINE=1`
before running setup to apply it; otherwise the check is left enabled.
