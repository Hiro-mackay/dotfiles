#!/usr/bin/env zsh

# -----------------
#  PATH
# -----------------
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
typeset -U path
path=(
    ${BREW_HOME}/bin(N-/)
    ${BREW_HOME}/sbin(N-/)
    ${CARGO_HOME}/bin(N-/)
    ${PNPM_HOME}(N-/)
    $path
)

# -----------------
#  zsh option
# -----------------
# Automatically change to a directory when the name is entered
setopt auto_cd

# Disable the terminal bell sound
setopt no_beep

# Automatically push the current directory onto the directory stack
setopt auto_pushd

# Do not push duplicate directories onto the stack
setopt pushd_ignore_dups

# Share command history across all sessions
setopt share_history

# Ignore commands starting with a space in the command history
setopt hist_ignore_space

# Do not store all duplicate commands in history
setopt hist_ignore_all_dups

# Do not store the command in the history list
setopt hist_no_store

# Remove superfluous blanks from each command line being added to the history list
setopt hist_reduce_blanks

# Do not raise an error for non-matching patterns in globbing
setopt +o nomatch

# -----------------
#  basic alias
# -----------------
alias ls="eza --group-directories-first --icons"
alias l="ls"
alias la="ls -a"
alias ll="ls -l"
alias lla="ls -la"
alias lt="ls --tree"
alias lt1="ls --tree --level=1"
alias lt2="ls --tree --level=2"
alias lt3="ls --tree --level=3"
alias cat="bat"
alias c="clear"
alias e="exit"
alias op="open ."
alias pwdcp="pwd | tr -d '\n' | pbcopy"
alias cpb="tee >(ghead -c -1 | pbcopy)"

# VS Code
alias co="cursor ."

# Note
alias note="cursor '~/Google\ Drive/My\ Drive/ObsidianVault'"
alias ob="cd ~/Google\ Drive/My\ Drive/ObsidianVault"

# Claude
alias cc="claude --dangerously-skip-permissions"

# emacs
alias em="emacs"

# zsh
alias edzsh="cursor $ZDOTDIR"
alias sozsh="source $ZDOTDIR/.zshrc"

# Directory
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias doc="cd ~/Documents"
alias repo="cd ~/Repository/github.com"
alias ac="cd ~/Repository/github.com/acompany-develop"
alias mackay="cd ~/Repository/github.com/Hiro-mackay"
alias g='cd $(ghq list -p | fzf)'
alias dotconf="cd $XDG_CONFIG_HOME"
alias dotfiles="cd $DOTFILES_DIR"
alias drive="cd ~/Google\ Drive/My\ Drive"

# -----------------
#  autoload and initialize completion
# -----------------
# Docker CLI completions
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=($HOME/.docker/completions $fpath)
fi
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Google Cloud SDK completion
if [[ -f "$HOME/.google-cloud-sdk/completion.zsh.inc" ]]; then
  source "$HOME/.google-cloud-sdk/completion.zsh.inc"
fi

# -----------------
#  mise activate
# -----------------
eval "$(mise activate zsh)"

# -----------------
#  Python
# -----------------
# alias
alias pyrun="uv run"
alias pyadd="uv add"
alias pyinit="uv init"
alias pyin="uv sync"
alias pyshell="uv shell"
alias pyrm="uv rm .venv"
alias pyfreeze="uv pip freeze > requirements.txt"

# -----------------
#  Rust
# -----------------
# alias
alias compete="cargo compete"

# -----------------
#  Git
# -----------------
# alias
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gs="git status"
alias gst="git stash"
alias gcamend="git commit --amend --no-edit"
alias gl="git log --graph"
alias glo="git log --oneline"
alias gco="git checkout"
alias gca="git checkout ."
alias gcb="git checkout -t -b"
alias gcd="git checkout . && git clean -df ."
alias gcom="git checkout main"
alias gb="git branch"
alias gbm="git branch -m"
alias gurl="git remote -v"
alias gseturl="git remote set-url origin"
alias gaddurl="git remote add origin"
alias greset="git reset --hard HEAD"
alias gundo="git reset --soft HEAD^"
alias gwa="_gwt_create_core"
alias gwab="_gwt_create_core"
alias gwaf='_gwt_create_core "$(git branch --format="%(refname:short)" | fzf)"'
alias gwr="_gwt_remove_core"
alias gws="_gwt_switch"

push() { git push origin "$(git branch --show-current)" }
pull() { git pull origin "$(git branch --show-current)" }

rebase() {
  local current_branch=$(git branch --show-current)
  git fetch origin -p
  git checkout main
  git pull --ff-only origin main
  git checkout "$current_branch"
  git rebase main
}

# メインworktreeのパスを取得（git worktree listから正確に特定）
_gwt_main_path() {
  local main_path
  main_path=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
  if [[ -z "$main_path" ]]; then
    echo "❌ Not in a git repository." >&2
    return 1
  fi
  echo "$main_path"
}

_gwt_create_core() {
  local full_branch="${1%/}"
  if [[ -z "$full_branch" ]]; then
    echo "Usage: gwa <branch-name>"
    return 1
  fi

  local main_path
  main_path=$(_gwt_main_path) || return 1
  local base=$(basename "$main_path")
  local suffix="${full_branch##*/}"
  local worktree_path="../${base}_${suffix}"

  # 既に存在する場合は移動のみ
  if [[ -d "$worktree_path" ]]; then
    echo "📂 Worktree already exists. Moving there..."
    cd "$worktree_path"
    return 0
  fi

  # staleな登録を事前クリーンアップ
  git worktree prune 2>/dev/null

  echo "🚀 Creating worktree at $worktree_path ..."
  if git show-ref --verify --quiet "refs/heads/$full_branch"; then
    echo "🌿 Linking existing branch '$full_branch'..."
    git worktree add "$worktree_path" "$full_branch"
  else
    echo "✨ Creating new branch '$full_branch'..."
    git worktree add -b "$full_branch" "$worktree_path"
  fi

  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create worktree."
    return 1
  fi

  cd "$worktree_path"

  # .env系ファイルをメインworktreeから再帰的にコピー
  local env_files
  env_files=$(cd "$main_path" && find . -name '.env*' ! -name '*.sample' ! -name '*.example' -type f 2>/dev/null)
  if [[ -n "$env_files" ]]; then
    echo "$env_files" | rsync -a --files-from=- "$main_path/" "./" 2>/dev/null
    echo "📋 Copied .env files from main worktree"
  fi

  echo "----------------------------------------"
  echo "✅ Success! Moved to: $PWD"
  echo "🌿 Branch: $(git branch --show-current)"
  echo "----------------------------------------"
}

_gwt_remove_core() {
  local branch="${1:-$(git branch --show-current)}"
  local main_path
  main_path=$(_gwt_main_path) || return 1
  local base=$(basename "$main_path")

  # メインworktreeは削除対象外
  if [[ "$(realpath "$PWD")" == "$main_path" && -z "$1" ]]; then
    echo "⚠️  Cannot remove the main worktree."
    return 1
  fi

  local suffix="${branch##*/}"
  local worktree_dir="${base}_${suffix}"

  # ターゲットの特定（隣のディレクトリ or 子ディレクトリ）
  local abs_target
  if [[ -d "../${worktree_dir}" ]]; then
    abs_target=$(realpath "../${worktree_dir}")
  elif [[ -d "./${worktree_dir}" ]]; then
    abs_target=$(realpath "./${worktree_dir}")
  else
    # ディレクトリは消えているが登録が残っていれば掃除
    git worktree prune 2>/dev/null
    echo "✅ Worktree for '$branch' is already clean."
    return 0
  fi

  # 削除対象の中にいる場合はメインリポジトリへ退避
  if [[ "$(realpath "$PWD")" == "$abs_target"* ]]; then
    cd "../${base}"
  fi

  echo "🗑️  Removing worktree: $branch"
  git worktree remove "$abs_target" && echo "🏠 Current directory: $PWD"
}

_gwt_switch() {
  local line
  line=$(git worktree list 2>/dev/null | awk '{
    n = split($1, a, "/")
    branch = $3; gsub(/[\[\]]/, "", branch)
    printf "%-25s %s\t%s\n", branch, a[n], $1
  }' | fzf --prompt="worktree> " --delimiter='\t' --with-nth=1)

  if [[ -z "$line" ]]; then
    return 0
  fi

  cd "${line##*$'\t'}"
  echo "🔀 $(basename "$PWD") [$(git branch --show-current)]"
}

# -----------------
#  Docker
# -----------------
# alias
alias dc="docker compose"
alias dp="docker ps"
alias dcud="docker compose up -d"
alias dcd="docker compose down"
alias dcdv="docker compose down --volumes"
alias dce="docker compose exec"
alias dpip="docker ps -q | xargs -n 1 docker inspect --format '{{ .Name }}: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"

dexec() {
    docker exec -it "$1" bash
}

# kubectl
alias k="kubectl"

# -----------------
#  ni
# -----------------
export NI_DEFAULT_AGENT="pnpm"
export NI_GLOBAL_AGENT="pnpm"

# -----------------
# Gemini CLI
# -----------------
alias gem="gemini"


# -----------------
#  utility function
# -----------------
function mkcd() {
  if [[ -d "$1" ]]; then
    echo "$1 already exists!"
    cd "$1"
  else
    mkdir -p "$1" && cd "$1"
  fi
}

function killport() {
    if [[ -z "$1" ]]; then
        echo "Usage: killport <port>"
        return 1
    fi
    local pids=$(lsof -t -i:"$1")
    if [[ -z "$pids" ]]; then
        echo "No process found on port $1"
        return 1
    fi
    kill $pids && echo "Killed processes on port $1: $pids"
}

# curl wrapper for GET request
cget() {
  local url=""
  local show_headers=false
  local show_body=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --head|-I) show_headers=true ;;
      --body|-b) show_body=true ;;
      --show-headers|-i)
        show_headers=true
        show_body=true
        ;;
      *)
        if [[ "$1" == "http"* ]]; then
          url="$1"
        else
          echo "Invalid option: -$OPTARG"
          return 1
        fi
    esac
    shift
  done

  local headers=""
  local body=""

  if $show_headers && $show_body; then
    response_body=$(curl -sL -D /tmp/headers.txt "$url")
  elif $show_headers; then
    $(curl -sL -D /tmp/headers.txt "$url" > /dev/null)
  elif $show_body; then
    response_body=$(curl -sL "$url")
  else
    curl "$url" -o /dev/null -w '%{scheme}/%{http_version} %{response_code}\ntime_total: %{time_total}\nsize_header: %{size_header}\nsize_download: %{size_download}\n' -s
  fi

  if $show_headers; then
    # Read headers from file
    response_headers=$(cat /tmp/headers.txt)
    # Delete temporary file
    rm /tmp/headers.txt

    echo "$response_headers"
  fi

  if $show_body; then
    # If JSON, use jq, if HTML, use htmlq, if text, output as is, otherwise output content type and file size
    if echo "$response_headers" | grep -q "application/json"; then
      echo "$response_body" | jq .
    elif echo "$response_headers" | grep -q "text/html"; then
      echo "$response_body" | htmlq --remove-nodes script,style,svg,link -p
      echo "\n\n ---"
      echo "Ignore <script>, <style>, <svg>, <link>"
    elif echo "$response_headers" | grep -q "text/.*"; then
      echo "$response_body"
    else
      echo "File Size: $(echo "$response_body" | wc -c) bytes"
    fi
  fi
}

# Secure random string generation function
rndl() {
    # Help display
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: randal [OPTIONS] [LENGTH]"
        echo ""
        echo "Options:"
        echo "  -s, --symbols    Include symbols in the string"
        echo "  -h, --help       Show this help message"
        echo ""
        echo "Examples:"
        echo "  randal           # Generate 32-character alphanumeric string (default)"
        echo "  randal 20        # Generate 20-character alphanumeric string"
        echo "  randal -s        # Generate 32-character alphanumeric + symbols string"
        echo "  randal -s 20     # Generate 20-character alphanumeric + symbols string"
        return 0
    fi

    local length=32
    local include_symbols=false
    local base_charset='a-zA-Z0-9'
    local symbols='!@#$%^&*()_+'

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--symbols)
                include_symbols=true
                shift
                ;;
            *)
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    length=$1
                else
                    echo "Error: Invalid argument '$1'. Use -h for help"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Preparing character set
    local charset="$base_charset"
    if $include_symbols; then
        charset="${charset}${symbols}"
    fi

    # Read necessary bytes from /dev/urandom and generate string
    # LC_ALL=C is the magic incantation needed for macOS
    # If you are not using macOS, you can remove LC_ALL=C
    echo "$(LC_ALL=C tr -dc "$charset" < /dev/urandom | head -c "$length")"
}
