# dotfiles

macOS development environment setup.

## What's Included

- **Shell** - zsh configuration (aliases, functions, PATH)
- **Homebrew** - packages, casks, and dependencies
- **Git** - global config and gitignore
- **macOS** - system preferences, Dock, Trackpad, Finder
- **Tools** - mise (runtime manager), Rust/Cargo, VS Code, Claude Code
- **Keyboard** - Karabiner-Elements key remapping

## Installation

### Prerequisites

```sh
xcode-select --install
```

### Setup

```sh
curl -fsSL https://raw.githubusercontent.com/Hiro-mackay/dotfiles/main/install.sh | zsh
```

### Re-apply

```sh
~/.dotfiles/install.sh
```

## Structure

```
.dotfiles/
├── install.sh            # Entry point
├── bootstrap/
│   ├── env.sh            # Environment variables
│   ├── setup.sh          # Orchestrator
│   ├── setup-dir.sh      # XDG / SSH directories
│   ├── setup-link.sh     # Symlinks (~/.config, ~/.zshenv, ~/.claude)
│   ├── setup-brew.sh     # Homebrew + Brewfile
│   ├── setup-lang.sh     # mise runtimes (node, python, rust, go, etc.)
│   ├── setup-macos.sh    # macOS system preferences
│   ├── setup-vscode.sh   # VS Code settings
│   └── setup-claude.sh   # Claude Code plugins + hooks
└── config/               # Symlinked to ~/.config
    ├── zsh/              # .zshrc, .zshenv
    ├── git/              # config, ignore
    ├── brew/             # Brewfile
    ├── mise/             # Runtime versions (node, python, go, etc.)
    ├── karabiner/        # Keyboard remapping
    ├── gh/               # GitHub CLI
    ├── vscode/           # Settings + extensions list
    └── claude/           # Claude Code settings + scripts
```
