# Additional setup

Manual steps around `install.sh` (see the README for running it), in order.

## 1. Before install — machine-local Git identity (optional)

To use a different Git identity for repos under `~/Repository/` without
committing it to this public repo, create `~/.gitconfig.local` (untracked,
outside the repo tree):

```gitconfig
[user]
    name  = <name>
    email = <email>
```

`install.sh` registers these values as git-secrets prohibited patterns during
the `setup-secrets` step (which runs after Homebrew installs git-secrets). If
you add the file *after* installing, register them with:

```sh
~/.dotfiles/bootstrap/setup-secrets.sh
```

Verify: `git -C ~/Repository/<repo> config user.email`

## 2. Install flags (optional)

Set before running `install.sh`:

| Flag | Effect |
|------|--------|
| `DOTFILES_SKIP_CASKS=1` | Skip optional GUI casks; essential casks (Hammerspoon, Warp) still install |
| `DOTFILES_DISABLE_QUARANTINE=1` | Disable the Gatekeeper "downloaded from the internet" check |

On a restricted machine, set `DOTFILES_SKIP_CASKS=1` and install the essential
casks by hand: `brew install --cask hammerspoon warp`.

## 3. After install — Hammerspoon accessibility (required for 英数/かな)

`install.sh` installs Hammerspoon and links its config. Grant it Accessibility
so it can send key events:

```sh
open -a Hammerspoon
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

Enable Hammerspoon in the list, then use its menu-bar icon → Reload Config.

Verify: left ⌘ → 英数, right ⌘ → かな.
