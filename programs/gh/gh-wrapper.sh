#!/bin/sh
# gh, signed in as the account for the repository it acts on: the one named on the
# command line (-R/--repo, a github.com URL, or `gh repo <cmd> owner/name`), else the
# current repository. ~/.gitconfig.<owner> sets github.login for its owners'
# repositories (gh-setup), the shared git settings for the rest. Passed through
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

account=''
if [ -n "$target" ]; then
    # [https://]github.com/OWNER/REPO, OWNER/REPO
    owner=${target#https://}
    owner=${owner#github.com/}
    owner=$(printf '%s' "${owner%%/*}" | tr '[:upper:]' '[:lower:]')
    file=$(git config --file "$HOME/.gitconfig.accounts" \
        --get "includeIf.hasconfig:remote.*.url:https://github.com/$owner/**.path" 2>/dev/null) &&
        account=$(git config --file "$HOME/${file#\~/}" github.login 2>/dev/null)
    # An owner without an account of its own belongs to the base account.
    [ -n "$account" ] || account=$(git config --global github.login 2>/dev/null)
fi
[ -n "$account" ] || account=$(git config --get github.login 2>/dev/null) || exec "$gh" "$@"
token=$("$gh" auth token -h github.com -u "$account" 2>/dev/null) || {
    echo "gh: not signed in as $account, the account for this repository; run gh-setup" >&2
    exit 1
}
GH_TOKEN=$token exec "$gh" "$@"
