#!/bin/sh
# gh, signed in as the account for the repository it acts on: the one named on the
# command line (-R/--repo, a github.com URL, or `gh repo <cmd> owner/name`), else the
# current repository. git's settings name it: github.login, which ~/.gitconfig.<owner>
# sets for its owners' repositories (gh-setup) and programs/git for the rest. Passed through
# untouched: `gh auth` (git's credential helper too), a token already given in
# GH_TOKEN or GITHUB_TOKEN, a host other than github.com, and GH_NO_AUTO_ACCOUNT (set
# by gh-setup while it switches accounts).
gh=@gh@
case "${1:-}" in auth) exec "$gh" "$@" ;; esac
[ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}${GH_NO_AUTO_ACCOUNT:-}" ] || exec "$gh" "$@"
case "${GH_HOST:-github.com}" in github.com) ;; *) exec "$gh" "$@" ;; esac

target='' prev=''
for a in "$@"; do
    case "$prev" in -R | --repo) target=$a ;; esac
    # Values of text and template flags are not the repository to act on.
    case "$prev" in -b | --body | -t | --title | -m | --message | -n | --notes | --template)
        prev='' && continue ;;
    esac
    case "$a" in
    --repo=*) target=${a#--repo=} ;;
    -R?*) target=${a#-R} ;;
    https://github.com/*/*) [ -n "$target" ] || target=$a ;;
    esac
    prev=$a
done
# `gh repo <cmd> owner/name`: the first argument after <cmd> that is not a flag.
if [ -z "$target" ] && [ "${1:-}" = repo ]; then
    i=0 prev=''
    for a in "$@"; do
        i=$((i + 1))
        p=$prev prev=$a
        [ "$i" -gt 2 ] || continue
        case "$p" in --template) continue ;; esac
        case "$a" in -*) ;; */*) target=$a && break ;; esac
    done
fi

if [ -n "$target" ]; then
    # [https://]github.com/OWNER/REPO or OWNER/REPO. git itself matches the owner
    # against the account conditions, outside any repository so its remotes stay out.
    owner=${target#https://}
    owner=${owner#github.com/}
    owner=$(printf '%s' "${owner%%/*}" | tr '[:upper:]' '[:lower:]')
    account=$(cd / && git -c "remote.gh-target.url=https://github.com/$owner/x" config github.login) ||
        exec "$gh" "$@"
else
    account=$(git config github.login) || exec "$gh" "$@"
fi

# Already the active account: no token to look up.
hosts=${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}/hosts.yml
if [ -r "$hosts" ]; then
    while IFS= read -r line; do
        case "$line" in "    user: $account") exec "$gh" "$@" ;; esac
    done <"$hosts"
fi
token=$("$gh" auth token -h github.com -u "$account" 2>/dev/null) || {
    echo "gh: not signed in as $account, the account for this repository; run gh-setup" >&2
    exit 1
}
GH_TOKEN=$token exec "$gh" "$@"
