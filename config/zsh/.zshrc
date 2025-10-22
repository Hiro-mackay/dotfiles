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
    # ヘッダーをファイルから読み込む
    response_headers=$(cat /tmp/headers.txt)
    # 一時ファイルを削除
    rm /tmp/headers.txt

    echo "$response_headers"
  fi

  if $show_body; then
    # JSONの場合 jqを使用、htmlの場合はhtmlqを使用、textの場合そのまま出力、それ以外はcontent typeとファイルサイズを出力
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
# -----------------
#  password generation function
# -----------------
function rand() {
  local length=32
  local include_symbols=false
  local charset=""
  
  # 引数の解析
  while [[ $# -gt 0 ]]; do
    case $1 in
      -l|--length)
        length="$2"
        shift 2
        ;;
      -s|--symbols)
        include_symbols=true
        shift
        ;;
      -h|--help)
        echo "Usage: genpass [OPTIONS]"
        echo "Options:"
        echo "  -l, --length NUM    パスワードの文字数 (デフォルト: 32)"
        echo "  -s, --symbols       記号を含める"
        echo "  -h, --help          このヘルプを表示"
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Use -h or --help for usage information"
        return 1
        ;;
    esac
  done
  
  # 文字数が正の整数かチェック
  if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -le 0 ]; then
    echo "Error: 文字数は正の整数である必要があります"
    return 1
  fi
  
  # 文字セットの設定
  charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  if $include_symbols; then
    charset="${charset}!@#$%^&*()"
  fi
  
  # 暗号学的に安全なランダムなパスワードを生成
  local password=""
  local charset_length=${#charset}
  
  # /dev/urandomを使用して暗号学的に安全なランダムバイトを生成
  for ((i=0; i<length; i++)); do
    # 1バイトのランダムデータを読み取り、文字セットの長さでモジュロ演算
    local random_byte=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
    local index=$((random_byte % charset_length))
    password="${password}${charset:$index:1}"
  done
  
  echo "$password"
}

# pnpm
export PNPM_HOME="/Users/mackay/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
