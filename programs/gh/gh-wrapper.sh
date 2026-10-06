#!/bin/sh
# gh, signed in as the account set for the current repository: ~/.gitconfig.<owner>
# sets github.login for its owners' repositories (gh-setup), ~/.gitconfig.accounts for
# the rest. `gh auth` (git's credential helper too) and an explicit GH_TOKEN pass
# through, as does GH_NO_AUTO_ACCOUNT, which gh-setup sets while it switches accounts.
gh=@gh@
case "${1:-}" in auth) exec "$gh" "$@" ;; esac
if [ -z "${GH_TOKEN:-}${GH_NO_AUTO_ACCOUNT:-}" ] &&
    account=$(git config --get github.login 2>/dev/null) &&
    token=$("$gh" auth token -h github.com -u "$account" 2>/dev/null); then
    GH_TOKEN=$token exec "$gh" "$@"
fi
exec "$gh" "$@"
