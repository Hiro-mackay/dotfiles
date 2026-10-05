# dotfiles

My development environment for macOS and Linux dev servers, built with Nix:
nix-darwin and home-manager on macOS, home-manager on Linux. Each tool's config
is in `programs/<tool>/`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
```

Then:

- Git accounts live only in the untracked `~/.gitconfig.local`. On a personal
  machine, copy the sample as is; it lists optional settings in comments:
  `cp ~/.dotfiles/programs/git/gitconfig.local.sample ~/.gitconfig.local`
- Sign in: `gh auth login`, `claude`, `codex`.
- macOS: run `sbx login`, allow Hammerspoon and Warp under Accessibility, open
  Docker Desktop once, and import `programs/bettertouchtool/Default.bttpreset`.
- Linux: log in again so the `docker` group applies. Push from a server with
  `ssh -A`.

## Update

```sh
dotup                       # pull this repo, apply it, upgrade mise tools
nix run ~/.dotfiles#switch  # apply local edits without pulling
```

CI updates `flake.lock` every Monday. Each update waits a week on the
`flake-update/pending` branch, then reaches `main` if the checks pass; delete the
branch to drop it. Known CVSS 9+ vulnerabilities in the macOS closure are reported
in an issue.
