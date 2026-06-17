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
gbclean() {
  git fetch -p

  local default_branch ref
  if ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null); then
    default_branch=${ref#refs/remotes/origin/}
  else
    default_branch=main
  fi

  local gone_branches
  gone_branches=$(git branch -vv | awk '/: gone\]/ {sub(/^\* /,""); print $1}')
  if [[ -z "$gone_branches" ]]; then
    echo "no gone branches"
    return 0
  fi

  local merged_prs
  merged_prs=$(gh pr list --state merged --limit 200 \
    --json headRefName --jq '.[].headRefName')

  local branch reply
  while IFS= read -r branch; do
    if git branch -d -q "$branch" 2>/dev/null; then
      echo "deleted: $branch"
      continue
    fi

    if grep -Fxq "$branch" <<< "$merged_prs"; then
      git branch -D -q "$branch"
      echo "deleted (merged via PR): $branch"
      continue
    fi

    echo ""
    echo "── $branch has unmerged commits:"
    git log --oneline --no-decorate "$default_branch..$branch" | head -10
    read "reply?delete? [y/N/s=skip all remaining] "
    case "$reply" in
      y|Y) git branch -D -q "$branch" && echo "deleted (forced): $branch" ;;
      s|S) echo "aborted"; return 0 ;;
      *)   echo "skipped: $branch" ;;
    esac
  done <<< "$gone_branches"
}

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
  echo "Untracked files to be removed:"
  git clean -nd .
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
alias ghopen='gh repo view --web'

gcreate() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    cat <<'USAGE'
Usage: gcreate [--private|--public] [--template <repo|owner/repo>] <repo-name>

Creates a GitHub repo, clones it via ghq, and cd's into it.

Options:
  --public        public repo (default)
  --private       private repo
  --template r    use own template (Hiro-mackay/r)
  --template o/r  use someone else's template (o/r)

Examples:
  gcreate my-app                          empty public repo
  gcreate --private secret-stuff          empty private repo
  gcreate --template ai-bootstrap myapp   from own template
  gcreate --template foo/bar myapp        from another's template
USAGE
    [[ -z "$1" ]] && return 1
    return 0
  fi

  local visibility="--public"
  local repo_name=""
  local template_repo=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --private)    visibility="--private" ;;
      --public)     visibility="--public" ;;
      --template)
        if [[ -z "$2" || "$2" == --* ]]; then
          echo "gcreate: --template requires a value. Run 'gcreate -h' for usage." >&2
          return 1
        fi
        template_repo="$2"; shift ;;
      *)            repo_name="$1" ;;
    esac
    shift
  done

  if [[ -z "$repo_name" ]]; then
    echo "gcreate: missing <repo-name>. Run 'gcreate -h' for usage." >&2
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

  # 2. Clone to ghq-managed path
  ghq get -p "${gh_user}/${repo_name}" || return 1

  # 3. Move into the repo
  local repo_path="$(ghq root)/github.com/${gh_user}/${repo_name}"
  cd "$repo_path" || return 1

  echo "----------------------------------------"
  echo "Created: $repo_path"
  echo "Remote:  $(git remote get-url origin)"
  [[ -n "$template_repo" ]] && echo "Template: $template_repo"
  echo "----------------------------------------"
}

# -----------------
#  Git: rebase
# -----------------
rebase() {
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
_gwt_main_path() {
  local main_path
  main_path=$(git worktree list --porcelain 2>/dev/null |
    awk '/^worktree / {print substr($0, 10); exit}')
  if [[ -z "$main_path" ]]; then
    echo "Not in a git repository." >&2
    return 1
  fi
  echo "$main_path"
}

_gwt_remote_ref() { git for-each-ref --format='%(refname)' "refs/remotes/*/${1}" 2>/dev/null | head -1 }

_gwt_open() {
  local full_branch="${1%/}"
  local start_point="${2%/}"
  local main_path
  main_path=$(_gwt_main_path) || return 1
  local base=$(basename "$main_path")
  local suffix="${full_branch##*/}"
  local worktree_path="$(dirname "$main_path")/${base}_${suffix}"

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
    if [[ -n "$start_point" ]]; then
      echo "Creating branch '$full_branch' tracking '$start_point'..."
      git worktree add -b "$full_branch" "$worktree_path" "$start_point"
    else
      echo "Creating new branch '$full_branch'..."
      git worktree add -b "$full_branch" "$worktree_path"
    fi
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

  printf '%s\nMoved to: %s\nBranch: %s\n%s\n' \
    "----------------------------------------" "$PWD" "$(git branch --show-current)" "----------------------------------------"
}

gwa() {
  local full_branch="${1%/}"
  [[ -z "$full_branch" ]] && { echo "Usage: gwa <new-branch-name>"; return 1; }
  git show-ref --verify --quiet "refs/heads/$full_branch" &&
    { echo "error: local branch already exists: $full_branch" >&2; return 1; }
  [[ -n "$(_gwt_remote_ref "$full_branch")" ]] &&
    { echo "error: remote branch already exists: $full_branch" >&2; return 1; }
  if git remote get-url origin >/dev/null 2>&1; then
    if git ls-remote --exit-code origin "refs/heads/$full_branch" >/dev/null 2>&1; then
      echo "error: origin branch already exists: $full_branch" >&2; return 1
    elif [[ $? -ne 2 ]]; then
      echo "error: cannot verify origin branch: $full_branch" >&2; return 1
    fi
  fi
  _gwt_open "$full_branch"
}

gwr() {
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
  local target_path="$(dirname "$main_path")/${worktree_dir}"

  local abs_target
  if [[ -d "$target_path" ]]; then
    abs_target=$(realpath "$target_path")
  else
    git worktree prune 2>/dev/null
    echo "Worktree for '$branch' is already clean."
    return 0
  fi

  if [[ "$(realpath "$PWD")/" == "$abs_target/"* ]]; then
    cd "$main_path"
  fi

  # Check for uncommitted changes before removal
  if [[ -n "$(git -C "$abs_target" status --porcelain 2>/dev/null)" ]]; then
    echo "error: '$branch' has uncommitted changes" >&2
    git -C "$abs_target" status --short >&2
    return 1
  fi

  echo "Removing worktree: $branch"
  if ! git worktree remove "$abs_target" 2>/dev/null; then
    echo "git worktree remove failed, forcing cleanup..."
    if ! rm -rf "$abs_target" 2>/dev/null; then
      echo "Directory contains files owned by another user (e.g. Docker). Using sudo..."
      if ! sudo rm -rf "$abs_target"; then
        echo "error: failed to remove $abs_target" >&2
        return 1
      fi
    fi
    git worktree prune 2>/dev/null
  fi
  echo "Removed: $branch"
  echo "Current directory: $PWD"
}

_gws_worktree_candidates() {
  git worktree list --porcelain 2>/dev/null | awk '
    /^worktree / {
      if (path != "") {
        n = split(path, a, "/")
        printf "%-30s %-25s %s\tcd\t%s\t\n", branch, a[n], path, path
      }
      path = substr($0, 10)
      branch = "(unknown)"
    }
    /^branch refs\/heads\// { branch = substr($0, 19) }
    /^detached$/            { branch = "(detached)" }
    /^bare$/                { branch = "(bare)" }
    END {
      if (path != "") {
        n = split(path, a, "/")
        printf "%-30s %-25s %s\tcd\t%s\t\n", branch, a[n], path, path
      }
    }
  '
}

_gws_worktree_branches() {
  git worktree list --porcelain 2>/dev/null |
    awk '/^branch / {sub(/^branch refs\/heads\//, ""); print}'
}

_gws_branch_candidates() {
  local existing="$1"
  {
    print -r -- "$existing" | awk 'NF { printf "E\t%s\n", $0 }'
    git branch --format='%(refname:short)' | awk 'NF { printf "L\t%s\n", $0 }'
    git for-each-ref --format='%(refname)' refs/remotes/ |
      awk '
        /^refs\/remotes\/[^\/]+\/HEAD$/ { next }
        /^refs\/remotes\// {
          s = substr($0, 14)
          b = s
          sub(/^[^\/]+\//, "", b)
          printf "R\t%s\t%s\n", b, s
        }
      '
  } | awk -F '\t' '
    $1 == "E" { existing[$2] = 1; next }
    $1 == "L" && !($2 in source) { order[++n] = $2; source[$2] = ""; next }
    $1 == "R" && !($2 in source) { order[++n] = $2; source[$2] = $3; next }
    END {
      for (i = 1; i <= n; i++) {
        branch = order[i]
        if (branch == "" || existing[branch]) continue
        start = source[branch]
        label = start == "" ? "(local branch)" : start
        printf "%-30s %-25s\tcreate\t%s\t%s\n", branch, label, branch, start
      }
    }
  '
}

_gws_fetch_start_point() {
  local branch="$1"
  local start_point="$2"
  [[ -z "$start_point" ]] && return 0
  git show-ref --verify --quiet "refs/remotes/$start_point" && return 0

  if [[ "$start_point" != origin/* ]]; then
    echo "error: missing remote ref '$start_point'. Run git fetch and retry." >&2
    return 1
  fi

  print -n "gws: fetching $start_point... " >&2
  if git fetch origin "refs/heads/${branch}:refs/remotes/${start_point}" 2>/dev/null; then
    print "done" >&2
    return 0
  fi

  print "failed" >&2
  return 1
}

_gws_open_branch() {
  local branch="${1%/}"
  local start_point
  [[ -z "$branch" ]] && return 1

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    _gwt_open "$branch"; return $?
  fi

  start_point=$(_gwt_remote_ref "$branch")
  start_point="${start_point#refs/remotes/}"
  [[ -z "$start_point" ]] && start_point="origin/$branch"

  _gws_fetch_start_point "$branch" "$start_point" || return 1
  _gwt_open "$branch" "$start_point"
}

gws() {
  _gwt_main_path >/dev/null || return 1
  local existing candidates selected label action arg start_point
  if [[ -n "$1" ]]; then
    _gws_open_branch "$1"
    return $?
  fi

  existing=$(_gws_worktree_branches)
  candidates=$(_gws_worktree_candidates)
  candidates+=$'\n'$(_gws_branch_candidates "$existing")

  selected=$(print -r -- "$candidates" |
    fzf --prompt="worktree> " --delimiter=$'\t' --with-nth=1) || return 0

  IFS=$'\t' read -r label action arg start_point <<< "$selected"
  if [[ "$action" == "cd" ]]; then
    cd "$arg" || return 1
    echo "$(basename "$PWD") [$(git branch --show-current)]"
    return 0
  fi

  _gws_fetch_start_point "$arg" "$start_point" || return 1
  _gwt_open "$arg" "$start_point"
}
