# -----------------
#  Git: basic
# -----------------
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gs="git status"
alias gcamend="git commit --amend --no-edit"
alias push="git push"
alias pushf="git push --force-with-lease"
alias pull="git pull"
alias pullff="git pull --ff-only"

# -----------------
#  Git: diff
# -----------------
alias gd="git diff"
alias gds="git diff --staged"
alias gdw="git diff --word-diff"

# -----------------
#  Git: stash
# -----------------
alias gst="git stash"
alias gstp="git stash pop"
alias gstl="git stash list"
alias gsts="git stash show -p"

# -----------------
#  Git: log
# -----------------
# graph
alias gl="git log --graph --oneline --decorate --all"
alias gll="git log --graph --pretty=format:'%C(auto)%h%d %s %C(dim)(%ar) <%an>%C(reset)' --all"
# filter
alias glme='git log --oneline --author="$(git config user.name)"'
alias glf="git log --oneline --follow --"
alias glt="git log --oneline --since='midnight'"
alias today='git log --oneline --since="midnight" --author="$(git config user.name)" --all'
gln() { git log --oneline --graph -"${1:-10}"; }
# diff
alias gls="git log --oneline --stat"
alias glnum="git log --oneline --shortstat"
# search
glg() { git log --oneline --grep="$1"; }
glS() { git log --oneline -S "$1"; }
# fzf interactive
glz() {
  git log --oneline --graph --all --color=always |
    fzf --ansi --no-sort --reverse --preview \
      'echo {} | grep -o "[a-f0-9]\{7,\}" | head -1 | xargs git show --color=always' |
    grep -o "[a-f0-9]\{7,\}" | head -1
}

# -----------------
#  Git: branch & switch
# -----------------
alias gco="git switch"
alias gcb="git switch -c"
alias gcom="git switch main"
alias gb="git branch"
alias gbm="git branch -m"
alias gbclean='git fetch -p && git branch -vv | grep "gone]" | awk "{print \$1}" | xargs git branch -d'

gfb() {
  local branch
  branch=$(git branch --all --format='%(refname:short)' |
    fzf --height=40% --reverse --preview 'git log --oneline -10 {}') || return
  git switch "${branch#origin/}"
}

# -----------------
#  Git: restore (with safety)
# -----------------
alias gca="git restore ."

gcd() {
  echo "Will discard ALL uncommitted changes and untracked files:"
  git status -s
  echo ""
  read "reply?Proceed? [y/N] "
  [[ "$reply" =~ ^[Yy]$ ]] && git restore . && git clean -df .
}

greset() {
  echo "Will hard reset to HEAD:"
  git diff --stat
  echo ""
  read "reply?Proceed? [y/N] "
  [[ "$reply" =~ ^[Yy]$ ]] && git reset --hard HEAD
}

alias gundo="git reset --soft HEAD^"

# -----------------
#  Git: remote
# -----------------
alias gurl="git remote -v"
alias gseturl="git remote set-url origin"
alias gaddurl="git remote add origin"
alias ghopen='open $(git remote get-url origin | sed "s/git@github.com:/https:\/\/github.com\//" | sed "s/\.git$//")'

gcreate() {
  local visibility="--public"
  local repo_name=""
  local template_repo=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --private)    visibility="--private" ;;
      --public)     visibility="--public" ;;
      --template)   [[ -n "$2" && "$2" != --* ]] && { template_repo="$2"; shift; } ;;
      *)            repo_name="$1" ;;
    esac
    shift
  done

  if [[ -z "$repo_name" ]]; then
    echo "Usage: gcreate [--private] [--template <repo|owner/repo>] <repo-name>"
    echo "  (default)                empty repo"
    echo "  --template repo          own template (Hiro-mackay/repo)"
    echo "  --template owner/repo    other's template"
    return 1
  fi

  if ! gh auth status &>/dev/null; then
    echo "gh is not authenticated. Run: gh auth login"
    return 1
  fi

  local gh_user
  gh_user=$(gh api user --jq '.login') || return 1

  # 1. Create remote repository
  local gh_args=("$repo_name" "$visibility")
  if [[ -n "$template_repo" ]]; then
    # repo name only -> resolve to own account
    [[ "$template_repo" != */* ]] && template_repo="${gh_user}/${template_repo}"
    gh_args+=(--template "$template_repo")
  fi
  gh repo create "${gh_args[@]}" || return 1

  # 2. Clone to ghq-managed path (use full owner/repo to avoid user mismatch)
  ghq get -p "${gh_user}/${repo_name}" || return 1

  # 3. Move into the repo
  local repo_path
  repo_path=$(ghq list -p | grep "/${repo_name}$")
  cd "$repo_path" || return 1

  echo "----------------------------------------"
  echo "Created: $repo_path"
  echo "Remote:  $(git remote get-url origin)"
  [[ "$mode" == "template" ]] && echo "Template: $template_repo"
  echo "----------------------------------------"
}

# -----------------
#  Git: rebase
# -----------------
rebase() {
  local current_branch=$(git branch --show-current)
  if [[ "$current_branch" == "main" ]]; then
    echo "Already on main. Nothing to rebase."
    return 1
  fi
  git fetch origin -p || return 1
  git switch main || return 1
  git pull --ff-only origin main || {
    echo "Failed to fast-forward main"
    git switch "$current_branch"
    return 1
  }
  git switch "$current_branch" || return 1
  git rebase main
}

rebase-remote() {
  local current_branch=$(git branch --show-current)
  local target="${1:-main}"

  if [[ "$current_branch" == "$target" ]]; then
    echo "Already on $target. Nothing to rebase."
    return 1
  fi

  git fetch origin -p || return 1
  git rebase "origin/$target" || return 1
}

# -----------------
#  Git: worktree
# -----------------
alias gwa="_gwt_create_core"
alias gwaf='_gwt_create_core "$(git branch --format="%(refname:short)" | fzf)"'
alias gwr="_gwt_remove_core"
alias gws="_gwt_switch"

_gwt_main_path() {
  local main_path
  main_path=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
  if [[ -z "$main_path" ]]; then
    echo "Not in a git repository." >&2
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

  if [[ -d "$worktree_path" ]]; then
    echo "Worktree already exists. Moving there..."
    cd "$worktree_path"
    return 0
  fi

  git worktree prune 2>/dev/null

  echo "Creating worktree at $worktree_path ..."
  if git show-ref --verify --quiet "refs/heads/$full_branch"; then
    echo "Linking existing branch '$full_branch'..."
    git worktree add "$worktree_path" "$full_branch"
  else
    echo "Creating new branch '$full_branch'..."
    git worktree add -b "$full_branch" "$worktree_path"
  fi

  if [[ $? -ne 0 ]]; then
    echo "Failed to create worktree."
    return 1
  fi

  cd "$worktree_path"

  local env_files
  env_files=$(cd "$main_path" && find . -name '.env*' ! -name '*.sample' ! -name '*.example' -type f 2>/dev/null)
  if [[ -n "$env_files" ]]; then
    echo "$env_files" | rsync -a --files-from=- "$main_path/" "./" 2>/dev/null
    echo "Copied .env files from main worktree"
  fi

  echo "----------------------------------------"
  echo "Moved to: $PWD"
  echo "Branch: $(git branch --show-current)"
  echo "----------------------------------------"
}

_gwt_remove_core() {
  local branch="${1:-$(git branch --show-current)}"

  local main_path
  main_path=$(_gwt_main_path) || return 1
  local base=$(basename "$main_path")

  if [[ "$(realpath "$PWD")" == "$main_path" && -z "$1" ]]; then
    echo "Cannot remove the main worktree."
    return 1
  fi

  local suffix="${branch##*/}"
  local worktree_dir="${base}_${suffix}"

  local abs_target
  if [[ -d "../${worktree_dir}" ]]; then
    abs_target=$(realpath "../${worktree_dir}")
  elif [[ -d "./${worktree_dir}" ]]; then
    abs_target=$(realpath "./${worktree_dir}")
  else
    git worktree prune 2>/dev/null
    echo "Worktree for '$branch' is already clean."
    return 0
  fi

  if [[ "$(realpath "$PWD")/" == "$abs_target/"* ]]; then
    cd "../${base}"
  fi

  # Check for uncommitted changes before removal
  if [[ -n "$(git -C "$abs_target" status --porcelain 2>/dev/null)" ]]; then
    echo "error: '$branch' has uncommitted changes" >&2
    git -C "$abs_target" status --short >&2
    return 1
  fi

  echo "Removing worktree: $branch"
  local git_err
  git_err=$(git worktree remove "$abs_target" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "error: git worktree remove failed:" >&2
    echo "  $git_err" >&2
    echo "" >&2
    echo "To force removal (e.g. permission issues from Docker), run:" >&2
    echo "  rm -rf $abs_target && git worktree prune" >&2
    return 1
  fi
  echo "Current directory: $PWD"
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
  echo "$(basename "$PWD") [$(git branch --show-current)]"
}
