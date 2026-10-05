# Additional setup

Manual steps around `install.sh` (see the README).

## Before the first switch (macOS)

- Install the Xcode Command Line Tools: `xcode-select --install`. Homebrew needs them.

Apps already installed outside Homebrew (company MDM, a manual install) are left
alone: their casks are skipped and they keep their own updater.

## After the first switch

Both OSes:

- Machine-local Git identity (optional). To use a different identity for repos
  under `~/Repository/` without committing it to this public repo, create
  `~/.gitconfig.local` (untracked, outside the repo):

  ```gitconfig
  [user]
      name  = <name>
      email = <email>
  ```

  git-secrets then rejects commits to this repo that contain these values
  (the pattern provider is set in `programs/git/default.nix`).
- Sign in: `gh auth login`, `claude`, `codex`.

macOS:

- `sbx login`.
- Grant Accessibility to Hammerspoon (英数/かな on left/right ⌘) and Warp:
  `open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"`,
  then Hammerspoon's menu-bar icon → Reload Config.
- Start Docker Desktop once.
- Import the BetterTouchTool preset from `programs/bettertouchtool/`.
- After the first switch is verified, set `homebrew.onActivation.cleanup = "zap"`
  in `darwin/homebrew.nix` so undeclared apps get removed.

Linux:

- Forward your SSH agent from the Mac (`ssh -A`) to push from the server.
- Log out and back in once so the `docker` group applies.
- Optional: make zsh the login shell (install.sh prints the command).

## Install flags

| Flag | Effect |
|------|--------|
| `DOTFILES_DISABLE_QUARANTINE=1` | macOS: disable the Gatekeeper "downloaded from the internet" check |
