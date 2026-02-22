# -----------------
#  basic
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
alias howlong='fc -lDt "%Y-%m-%d %H:%M:%S" -1'

# -----------------
#  editor
# -----------------
alias co="cursor ."
alias em="emacs"
alias note="cursor '~/Google\ Drive/My\ Drive/ObsidianVault'"

# -----------------
#  Claude
# -----------------
alias cc="claude --dangerously-skip-permissions"
alias ccconfig="cd $XDG_CONFIG_HOME/claude"
alias ccdev='cc --system-prompt "$(cat ~/.claude/contexts/dev.md)"'
alias ccreview='cc --system-prompt "$(cat ~/.claude/contexts/review.md)"'
alias ccsearch='cc --system-prompt "$(cat ~/.claude/contexts/research.md)"'

# -----------------
#  zsh config
# -----------------
alias edzsh="cursor $ZDOTDIR"
alias sozsh="source $ZDOTDIR/.zshrc"

# -----------------
#  directory navigation
# -----------------
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias doc="cd ~/Documents"
alias ob="cd ~/Google\ Drive/My\ Drive/ObsidianVault"
alias repo="cd ~/Repository/github.com"
alias ac="cd ~/Repository/github.com/acompany-develop"
alias mackay="cd ~/Repository/github.com/Hiro-mackay"
alias g='cd $(ghq list -p | fzf)'
alias dotconf="cd $XDG_CONFIG_HOME"
alias dotfiles="cd $DOTFILES_DIR"
alias drive="cd ~/Google\ Drive/My\ Drive"
