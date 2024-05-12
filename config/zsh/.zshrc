#!/usr/bin/env zsh

# -----------------
#  PATH
# -----------------
typeset -U path
path=(
    ${BREW_HOME}/bin(N-/)
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
alias ls="exa  --group-directories-first --icons"
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
alias sudo="sudo "
alias pwdcp="pwd | tr -d '\n' | pbcopy"

# VS Code
alias co="code ."

# emacs
alias em="emacs"

# zsh
alias edzsh="code $ZDOTDIR"
alias sozsh="source $ZDOTDIR/.zshrc"
alias re='exec $SHELL -l'

# Directory
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias doc="cd ~/Documents"
alias repo="cd ~/Repository/github.com"
alias ac="cd ~/Repository/github.com/acompany-develop"
alias mackay="~/Repository/github.com/Hiro-mackay"
alias g='cd $(ghq list -p | fzf)'
alias dotconf="cd $XDG_CONFIG_HOME"


# -----------------
#  autoload and initialize completion
# -----------------
autoload -U compinit; compinit


# -----------------
#  mise activate
# -----------------
eval "$(~/.local/bin/mise activate zsh)"

# -----------------
#  Python
# -----------------

# alias
alias pyp="pipenv run python"
alias pyin="pipenv install"
alias pyel="ls -d1 $XDG_DATA_HOME/virtualenvs/*"
alias pyshell="pipenv shell"
alias pyrm="pipenv --rm"
alias pyr="pipenv run"
alias pyfreeze="pipenv run pip freeze > requirements.txt"



# -----------------
#  Node.js
# -----------------
# volta alias
alias v="volta"
alias vin="volta install"

# npm alias
alias n="npm"
alias nin="npm init"
alias ni="npm install"
alias nid="npm install --save-dev"
alias nrm="npm uninstall"
alias nr="npm run"
alias nx="npx"

# pnpm alias
alias pn="pnpm"
alias pninit="pnpm init"
alias pna="pnpm add"
alias pnad="pnpm add -D"
alias pnrm="pnpm remove"
alias pnr="pnpm run"
alias pnx="pnpx"


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
alias pull="git pull origin"
alias gurl="git remote -v"
alias gseturl="git remote set-url origin"
alias gaddurl="git remote add origin"
alias rebase="git fetch origin -p && git checkout main && git reset --hard origin/main && git checkout - && git pull --rebase origin main"
alias greset="git reset --hard HEAD"




# -----------------
#  Starship
# -----------------
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship.toml"
eval "$(starship init zsh)"



# -----------------
#  Docker
# -----------------
# alias
alias dc="docker-compose"
alias dp="docker ps"
alias dcud="docker-compose up -d"
alias dcd="docker-compose down"
alias dcdv="docker-compose down --volumes"
alias dce="docker-compose exec"



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

function create-next-app(){
    if [ -z $1 ]; then
        echo "Please specify the project name"
    elif [[ -d $1 ]]; then
	echo "$1 already exists!"
    else
	npx create-next-app $1 --example https://github.com/Hiro-mackay/next-js-boilertemplate
	cd $1
	yarn
    fi
}

function create-vite-app(){
    if [ -z $1 ]; then
        echo "Please specify the project name"
    elif [[ -d $1 ]]; then
        echo "$1 already exists!"
    else
	npx degit Hiro-mackay/react-template $1
	cd $1
	yarn
    fi
}

function killport(){
    kill $(lsof -t -i:$1)
}