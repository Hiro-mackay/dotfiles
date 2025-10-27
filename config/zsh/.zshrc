#!/usr/bin/env zsh

# -----------------
#  PATH
# -----------------
typeset -U path
path=(
    ${BREW_HOME}/bin(N-/)
    ${BREW_HOME}/sbin(N-/)
    ${CARGO_HOME}/bin(N-/)
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

# Do not store duplicate commands in history
setopt hist_ignore_dups

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
alias ls="eza  --group-directories-first --icons"
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

# VS Code
alias co="cursor ."

# Note
alias note="cursor '~/Google\ Drive/My\ Drive/ObsidianVault'"

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
alias mackay="~/Repository/github.com/Hiro-mackay"
alias g='cd $(ghq list -p | fzf)'
alias dotconf="cd $XDG_CONFIG_HOME"
alias dotfiles="cd $DOTFILES_DIR"
alias drive="cd ~/Google\ Drive/My\ Drive"

# -----------------
#  autoload and initialize completion
# -----------------
autoload -U compinit; compinit


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
#  Node.js
# -----------------
# volta alias
alias v="volta"
alias vin="volta install"



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
alias push="git push origin $(git branch --show-current)"
alias pull="git pull origin $(git branch --show-current)"
alias gurl="git remote -v"
alias gseturl="git remote set-url origin"
alias gaddurl="git remote add origin"
alias rebase="git fetch origin -p && git checkout main && git reset --hard origin/main && git checkout - && git pull --rebase origin main"
alias greset="git reset --hard HEAD"


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

# kubectl
alias k="kubectl"


# -----------------
#  ni
# -----------------
export NI_DEFAULT_AGENT="pnpm"
export NI_GLOBAL_AGENT="pnpm"


# -----------------
#  utility function
# -----------------
function mkcd() {
  if [[ -d $1 ]]; then
    echo "$1 already exists!"
    cd $1
  else
    mkdir -p $1 && cd $1
  fi
}

function killport(){
    kill $(lsof -t -i:$1)
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
randal() {
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

# pnpm
export PNPM_HOME="/Users/mackay/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions