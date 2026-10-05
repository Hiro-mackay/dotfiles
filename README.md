# dotfiles

My development environment for macOS and Linux dev servers, built with Nix:
nix-darwin and home-manager on macOS, home-manager on Linux. Each tool's config
is in `programs/<tool>/`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | sh
```

Then:

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

CI updates `flake.lock` every Monday and pushes it to `main` once the checks pass.

Repos under `~/Repository/` use the git identity in `~/.gitconfig.local`
(untracked) if it exists.
