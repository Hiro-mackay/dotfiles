# Zsh Configuration

A modular zsh environment for macOS. Provides shorthand aliases for Git, Docker, Python, and common tasks, with fzf-powered interactive selection throughout.

## Prerequisites

The following tools are installed via [Brewfile](../brew/Brewfile) during `install.sh`:

| Tool | Role |
|------|------|
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement (icons, tree, git-aware) |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting and paging |
| [fd](https://github.com/sharkdp/fd) | Fast file finder (used by fzf as default source) |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder for files, history, branches, containers |
| [ghq](https://github.com/x-motemen/ghq) | Git repository manager (`ghq get`, `ghq list`) |
| [jq](https://github.com/jqlang/jq) | JSON processor |
| [htmlq](https://github.com/mgdm/htmlq) | HTML processor (like jq for HTML) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` that learns from usage |
| [starship](https://starship.rs) | Prompt showing git/language/duration info (non-Warp) |
| [direnv](https://github.com/direnv/direnv) | Per-directory environment variables |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | Terminal UI for docker |
| [mise](https://github.com/jdx/mise) | Runtime version manager (node, python, go, etc.) |
| [uv](https://github.com/astral-sh/uv) | Fast Python package manager |

## Structure

```
zsh/
├── .zshenv              # Env vars, history, fzf config (loaded first)
├── .zshrc               # PATH, shell options, completion, sources rc.d/
└── rc.d/                # Modular configs (sourced in alphabetical order)
    ├── aliases.zsh      # ls, cat, editor, directory shortcuts
    ├── cheat.zsh        # In-terminal quick reference (cheat command)
    ├── dev.zsh          # Python, Rust, k8s, package manager
    ├── docker.zsh       # Docker Compose, container management
    ├── functions.zsh    # Utility functions (HTTP, network, filesystem)
    ├── git.zsh          # Git aliases, worktree, rebase
    └── plugins.zsh      # Plugin init (fzf, zoxide, starship, etc.)
```

To edit: `edzsh` opens this directory in Cursor.
To reload after editing: `sozsh`.

---

## Shell Plugins

Plugins are initialized in `rc.d/plugins.zsh`. Each is guarded with a `command -v` check and skipped silently if not installed.

### fzf - Fuzzy finder

fzf powers interactive selection in many commands throughout this config:

| Command | What it selects |
|---------|----------------|
| `g` | Repository (ghq) |
| `gfb` | Git branch (with log preview) |
| `glz` | Git commit (with diff preview) |
| `gwaf` | Git branch for worktree |
| `gws` | Git worktree |
| `dexec` | Docker container to exec into |
| `dclz` | Docker Compose service for logs |
| `dlz` | Docker container for logs |

**Controls inside fzf:**

| Key | Action |
|-----|--------|
| Type | Filter results |
| `Enter` | Select |
| `Esc` | Cancel |
| `Ctrl+D` / `Ctrl+U` | Scroll preview pane |
| `Tab` | Multi-select (when supported) |

**Query syntax:**

| Pattern | Meaning | Example |
|---------|---------|---------|
| `foo` | Fuzzy match | `btn` matches `Button.tsx` |
| `foo bar` | Multiple fragments (AND) | `btn comp` matches `components/Button.tsx` |
| `'foo` | Exact match | `'button` matches literal "button" only |
| `!foo` | Negation | `!test` excludes results with "test" |
| `^foo` | Prefix | `^src` matches paths starting with "src" |
| `foo$` | Suffix | `.tsx$` matches paths ending with ".tsx" |

### zoxide - Smart directory navigation

Learns which directories you visit and lets you jump to them by name.

```sh
z github        # -> ~/Repository/github.com (if visited)
z dotfiles      # -> ~/.dotfiles
z myproject     # -> wherever myproject/ is
zi              # interactive mode: fzf list of all known dirs
```

Matching rules:
- Matches against **directory name components**, not substrings
- `z github` works because "github.com" is a directory name
- `z repo` does **not** match "Repository" (partial prefix)
- Frecency: directories visited more often and more recently rank higher

zoxide learns automatically from normal `cd` usage. The more you use it, the smarter it gets.

### starship - Prompt

Displays contextual information in the command prompt:

- Current directory (abbreviated)
- Git branch and status (dirty, staged, ahead/behind)
- Language versions (node, python, rust, go) when a project file is detected
- Command duration (shown when a command takes longer than 3 seconds)

Works out of the box. Customize with `~/.config/starship.toml` ([docs](https://starship.rs/config/)).

### direnv - Per-directory environment variables

Automatically loads/unloads environment variables when you enter/leave a directory.

```sh
cd myproject
echo 'export DATABASE_URL=postgres://localhost/mydb' > .envrc
direnv allow    # required once per .envrc change
# DATABASE_URL is now set

cd ~
# DATABASE_URL is now unset
```

Add `.envrc` to `.gitignore` in your projects.

### zsh-autosuggestions

As you type, a gray suggestion appears based on your command history. Press the right arrow key (`->`) to accept the full suggestion, or `Ctrl+F` to accept one word at a time.

### zsh-syntax-highlighting

Commands are colored in real-time as you type:
- Green: valid command
- Red: command not found
- Underline: valid file path

---

## Navigation

### Directory aliases

Fixed shortcuts to common locations:

| Command | Destination |
|---------|-------------|
| `repo` | `~/Repository/github.com` |
| `mackay` | `~/Repository/github.com/Hiro-mackay` |
| `ac` | `~/Repository/github.com/acompany-develop` |
| `dl` / `dt` / `doc` | `~/Downloads` / `~/Desktop` / `~/Documents` |
| `dotfiles` | `~/.dotfiles` |
| `dotconf` | `~/.config` |
| `drive` | `~/Google Drive/My Drive` |
| `ob` | ObsidianVault |

### Repository jump (`g`)

Opens fzf with all repositories managed by [ghq](https://github.com/x-motemen/ghq):

```sh
g
# -> type a few characters to filter, Enter to cd into the selected repo
```

Requires repos to be cloned via `ghq get <repo-url>`.

### Zoxide (`z` / `zi`)

See [zoxide section](#zoxide---smart-directory-navigation) above.

### Directory stack

zsh `auto_pushd` is enabled, so every `cd` pushes the previous directory onto a stack:

```sh
cd ~/foo
cd ~/bar
cd -          # back to ~/foo
dirs -v       # show the stack with indices
cd ~2         # jump to stack entry 2
```

---

## Git

All git aliases use short prefixes: `g` + action initial(s).

### Stage and commit

| Command | Equivalent | Description |
|---------|-----------|-------------|
| `ga <file>` | `git add <file>` | Stage a specific file |
| `gaa` | `git add .` | Stage all changes |
| `gc` | `git commit` | Commit (opens editor) |
| `gcm "msg"` | `git commit -m "msg"` | Commit with inline message |
| `gcamend` | `git commit --amend --no-edit` | Add staged changes to last commit |
| `gundo` | `git reset --soft HEAD^` | Undo last commit, keep changes staged |

### Diff

| Command | Equivalent | Description |
|---------|-----------|-------------|
| `gd` | `git diff` | Unstaged changes |
| `gds` | `git diff --staged` | Staged changes (what will be committed) |
| `gdw` | `git diff --word-diff` | Inline word-level diff |

### Stash

| Command | Equivalent | Description |
|---------|-----------|-------------|
| `gst` | `git stash` | Stash current changes |
| `gstp` | `git stash pop` | Apply and remove top stash |
| `gstl` | `git stash list` | List all stashes |
| `gsts` | `git stash show -p` | Show stash contents as a diff |

### Log

| Command | Description |
|---------|-------------|
| `gl` | One-line graph log of all branches |
| `gll` | Detailed graph with author and relative date |
| `gln [N]` | Last N commits (default: 10) |
| `glme` | Commits by the current `user.name` |
| `glt` | Commits since midnight |
| `today` | Commits since midnight across all branches |
| `gls` | Log with per-file change stats |
| `glnum` | Log with insertion/deletion counts |
| `glg "text"` | Search commit messages for "text" |
| `glS "text"` | Search diffs for "text" (pickaxe: finds when a string was added/removed) |
| `glz` | **Interactive**: fzf log browser with commit preview |

`glz` opens fzf over `git log --graph`. Select a commit to see its full diff. The selected commit hash is output to stdout, so you can pipe it:

```sh
glz | pbcopy    # copy a commit hash to clipboard
```

### Branch

| Command | Description |
|---------|-------------|
| `gco <branch>` | Switch to branch |
| `gcb <branch>` | Create and switch to a new tracking branch |
| `gcom` | Switch to `main` |
| `gb` | List branches |
| `gbm <name>` | Rename current branch |
| `gbclean` | Delete local branches whose remote tracking branch is gone |
| `gfb` | **Interactive**: fzf branch switcher with log preview |

`gfb` lists all local and remote branches. Select one to switch to it. Remote branches are automatically checked out as local tracking branches.

### Discard changes

These commands are **safety-guarded** with a confirmation prompt:

| Command | What it does |
|---------|-------------|
| `gca` | Restore all tracked files (`git restore .`) -- no prompt |
| `gcd` | Restore all + delete untracked files. Shows `git status -s` and asks for confirmation |
| `greset` | Hard reset to HEAD. Shows `git diff --stat` and asks for confirmation |

### Remote

| Command | Description |
|---------|-------------|
| `push` / `pull` | `git push` / `git pull` |
| `gurl` | Show remote URLs |
| `gseturl <url>` | Change origin URL |
| `gaddurl <url>` | Add origin remote |
| `ghopen` | Open the GitHub repository page in the default browser |

### Rebase

```sh
rebase
```

Automates the common rebase-on-main workflow:

1. `git fetch origin -p`
2. Switch to `main`, pull with `--ff-only`
3. Switch back to your branch
4. `git rebase main`

If any step fails, the function aborts and returns you to your original branch.

### Worktree

Git worktrees let you work on multiple branches simultaneously in separate directories.

| Command | Description |
|---------|-------------|
| `gwa <branch>` | Create a worktree for `<branch>` in a sibling directory |
| `gwaf` | Same, but select the branch with fzf |
| `gws` | Switch between existing worktrees with fzf |
| `gwr [branch]` | Remove a worktree (default: current branch) |

How it works:
- `gwa feat/login` in `~/code/myapp` creates `~/code/myapp_login/`
- `.env*` files are automatically copied from the main worktree
- If the branch already exists locally, it links to it. Otherwise, creates a new branch
- `gwr` safely moves you to the main worktree before removing

---

## Docker

All Docker aliases are prefixed with `d`. Compose commands start with `dc`.

### Compose lifecycle

| Command | Equivalent | Description |
|---------|-----------|-------------|
| `dc` | `docker compose` | Base command |
| `dcu` | `docker compose up` | Start services |
| `dcud` | `docker compose up -d` | Start detached |
| `dcw` | `docker compose up --watch` | Start with file watching |
| `dcd` | `docker compose down` | Stop and remove |
| `dcdv` | `docker compose down --volumes` | Stop, remove, and delete volumes |
| `dcr` | `docker compose restart` | Restart services |
| `dce` | `docker compose exec` | Execute command in service |
| `dcdry` | `docker compose up --dry-run` | Preview what would happen |

### Logs

| Command | Description |
|---------|-------------|
| `dcl` | Show last 50 lines of compose logs |
| `dclf` | Follow compose logs (tail 50) |
| `dclz` | **Interactive**: fzf pick a compose service, then follow its logs |

### Container status

| Command | Description |
|---------|-------------|
| `dp` | Running containers: name, status, ports |
| `dpa` | All containers (including stopped): name, status, image |
| `dstats` | Live resource usage: CPU, memory, network I/O |

### Interactive tools (fzf)

| Command | Description |
|---------|-------------|
| `dexec` | Pick a running container with fzf, then exec into it (auto-detects bash/sh) |
| `dlz` | Pick any running container with fzf, then follow its logs |
| `ddebug [name]` | Debug a distroless/scratch container (uses `docker debug`) |

### Build and security

| Command | Description |
|---------|-------------|
| `dlint` | Lint the Dockerfile in the current directory |
| `dscout` | Scan for critical/high CVEs using Docker Scout |

### Cleanup

| Command | Description |
|---------|-------------|
| `dprune` | Remove stopped containers, unused networks, dangling images |
| `dprunea` | Remove **everything** unused, including volumes. Use with caution |

---

## Development Tools

### Python (uv)

| Command | Equivalent | Description |
|---------|-----------|-------------|
| `pyinit` | `uv init` | Create a new Python project |
| `pyadd <pkg>` | `uv add <pkg>` | Add a dependency |
| `pyin` | `uv sync` | Install/sync all dependencies |
| `pyrun <cmd>` | `uv run <cmd>` | Run a command inside the virtualenv |
| `pyshell` | `uv shell` | Activate the virtualenv shell |
| `pyrm` | `rm -rf .venv` | Delete the virtualenv |
| `pyfreeze` | `uv pip freeze > requirements.txt` | Export dependencies |

### Other

| Command | Description |
|---------|-------------|
| `compete` | `cargo compete` (Rust competitive programming) |
| `k` | `kubectl` |
| `lg` | Open lazygit (interactive git TUI) |
| `lzd` | Open lazydocker (interactive docker TUI) |
| `cc` | Start Claude Code |
| `ccdev` / `ccreview` / `ccsearch` | Claude Code with context-specific system prompts |

---

## Utility Functions

### Filesystem

| Command | Description |
|---------|-------------|
| `mkcd <dir>` | Create a directory and cd into it. If it exists, just cd |
| `bigfiles [dir]` | Show the 20 largest files under the given directory (default: `.`) |
| `op` | Open the current directory in Finder |
| `pwdcp` | Copy the current working directory path to clipboard |

### Network

| Command | Description |
|---------|-------------|
| `killport <port>` | Kill whatever process is listening on the given port |
| `ports` | List all processes listening on TCP ports |

### Clipboard

| Command | Description |
|---------|-------------|
| `cpb` | Pipe stdout to clipboard. Example: `echo foo \| cpb` |
| `jc` | Read JSON from clipboard, pretty-print with jq, write back to clipboard |

### HTTP client (`cget`)

A curl wrapper for quick GET requests with automatic response formatting:

```sh
cget https://api.example.com/health
# -> HTTP/2 200
#    time_total: 0.142
#    size_download: 27

cget -b https://api.example.com/users
# -> auto-formats: JSON through jq, HTML through htmlq, text as-is

cget -I https://api.example.com/users
# -> response headers only

cget -i https://api.example.com/users
# -> headers + formatted body
```

| Flag | Description |
|------|-------------|
| (none) | Show status code, timing, and size |
| `-b` / `--body` | Show response body (auto-formatted) |
| `-I` / `--head` | Show response headers |
| `-i` / `--show-headers` | Show headers + body |

### Random string (`rndl`)

Generate cryptographically random strings:

```sh
rndl              # 32-character alphanumeric
rndl 64           # 64-character alphanumeric
rndl -s           # 32-character with symbols (!@#$%^&*()_+)
rndl -s 16        # 16-character with symbols
```

### Other

| Command | Description |
|---------|-------------|
| `howlong` | Show the timestamp and duration of the last command |
| `c` / `e` | `clear` / `exit` |
| `cat` | Aliased to `bat` (syntax-highlighted, with paging for long files) |

---

## Quick Reference (`cheat`)

A built-in terminal cheatsheet. Run `cheat` for the topic list:

```sh
cheat            # overview + most useful commands
cheat git        # git aliases, stash, log, worktree
cheat docker     # compose, logs, exec, cleanup
cheat fzf        # fzf-powered commands, query syntax
cheat nav        # directory aliases, zoxide, ghq
cheat util       # killport, ports, rndl, cget
cheat dev        # python, rust, claude, lazygit, direnv
```

---

## Customization

### Adding aliases or functions

Create a new file in `rc.d/` with a `.zsh` extension. It will be sourced automatically on the next shell start or `sozsh`:

```sh
# rc.d/myaliases.zsh
alias myalias="my-command --with-flags"
```

Files are sourced in alphabetical order. If load order matters, prefix with a number (e.g., `00-early.zsh`).

### Shell options

Options are set in `.zshrc`. Current options:

| Option | Effect |
|--------|--------|
| `auto_cd` | Type a directory name to cd into it |
| `auto_pushd` | Every cd pushes the previous dir onto the stack |
| `share_history` | History is shared across all shell sessions |
| `inc_append_history` | Commands are saved to history immediately (crash-safe) |
| `hist_ignore_space` | Commands starting with a space are not saved to history |
| `hist_ignore_all_dups` | Duplicate commands are removed from history |
| `hist_verify` | `!!` and `!$` expansions are shown before executing |

### History

History is stored at `$XDG_STATE_HOME/zsh/history` with 100,000 entries. `inc_append_history` is enabled, so commands are saved immediately (crash-safe).

### Environment variables

Global environment variables are set in `.zshenv` (loaded before `.zshrc`). Per-directory variables should use direnv (`.envrc` files).
