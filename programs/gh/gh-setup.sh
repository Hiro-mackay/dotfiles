# gh-setup: set up one GitHub account on this machine, asking which one.
#
# git and gh both use gh's token, over HTTPS (programs/git rewrites SSH URLs). The base
# account (github.login in programs/git) serves every GitHub repository. Another
# account gets ~/.gitconfig.<owner>, named after the first owner whose repositories it
# serves, holding its identity and its credential, and included for those owners'
# remotes. Both switch together, so a commit and the push always belong to the same
# account; gh follows the same choice (gh-wrapper.sh).

# Switch gh's accounts by hand here, not by the current repository (gh-wrapper.sh).
export GH_NO_AUTO_ACCOUNT=1
accounts="$HOME/.gitconfig.accounts"
cred='credential.https://github.com.helper'

die() {
    echo "error: $*" >&2
    exit 1
}
title() { printf '\n\033[1m== %s ==\033[0m\n' "$1" >&2; }
ask() { # ask <prompt> [default] -> answer on stdout, like ssh-keygen's prompts
    if [ -n "${2:-}" ]; then printf 'Enter %s (%s): ' "$1" "$2" >&2; else printf 'Enter %s: ' "$1" >&2; fi
    read -r reply || reply=
    printf '%s\n' "${reply:-${2:-}}"
}
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
active() { gh api user --jq .login 2>/dev/null; }
canonical() { # canonical <login>: as GitHub spells it, when gh can ask; else unchanged
    if active >/dev/null; then
        gh api "users/$1" --jq .login 2>/dev/null || die "no GitHub user or organization named $1"
    else
        printf '%s\n' "$1"
    fi
}
sign_in() { # sign_in <login>: make that account active in gh, adding it if needed
    if ! gh auth switch -h github.com -u "$1" >/dev/null 2>&1; then
        echo "Sign in to GitHub as $1 in the browser" >&2
        gh auth login -h github.com -p https --skip-ssh-key -w -s workflow
    fi
    [ "$(lower "$(active)")" = "$(lower "$1")" ] || die "gh is signed in as $(active), not $1"
    # Pushing changes under .github/workflows needs the workflow scope.
    gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -q workflow ||
        gh auth refresh -h github.com -s workflow
}
use_token() { # use_token <config file> <login>: git gets that account's token from gh
    # gh by the path it has now: in PATH from the profile, so it survives updates.
    ghbin=$(command -v gh)
    git config --file "$1" --unset-all "$cred" 2>/dev/null || true
    git config --file "$1" --add "$cred" ''
    git config --file "$1" --add "$cred" \
        "!f() { test \"\$1\" = get || exit 0; t=\$($ghbin auth token -h github.com -u $2) || { echo \"git: gh is not signed in as $2; run gh-setup\" >&2; exit 1; }; echo username=$2; echo password=\$t; }; f"
}

# The base account, from the shared settings (--global skips the accounts file).
base=$(git config --global github.login 2>/dev/null) || die "no github.login in the git settings"

title "GitHub account setup"
acct=$(ask "the GitHub login of the account to set up" "$base")
[ -n "$acct" ] || die "a GitHub login is required"
acct=$(canonical "$acct")
# gh stays signed in to the base account afterwards, also when this stops early.
trap 'gh auth switch -h github.com -u "$base" >/dev/null 2>&1 || true' EXIT

if [ "$(lower "$acct")" = "$(lower "$base")" ]; then
    echo "$acct is the base account, used for all of GitHub" >&2
    sign_in "$acct"
    echo "OK: git and gh use $acct" >&2
    exit
fi

# Another account. Earlier answers for it are the defaults.
file=''
for f in "$HOME"/.gitconfig.*; do
    [ "$(git config --file "$f" github.login 2>/dev/null)" = "$acct" ] && file=$f
done
prev() { [ -z "$file" ] || git config --file "$file" "$1" 2>/dev/null || true; }
answer=$(ask "the users or organizations whose repositories it is for" "$(prev github.owners)")
answer=${answer:-$acct}
name=$(ask "the name for its commits" "$(prev user.name)")
email=$(ask "the email for its commits" "$(prev user.email)")
[ -n "$name" ] && [ -n "$email" ] || die "a name and an email are required"

# Owners as GitHub spells them, plus lowercase: git matches URLs case-sensitively.
owners='' patterns=''
for o in $answer; do
    o=$(canonical "$o")
    owners="$owners $o"
    patterns="$patterns $o"
    [ "$(lower "$o")" = "$o" ] || patterns="$patterns $(lower "$o")"
done
owners=${owners# }
for p in $patterns; do
    [ "$(lower "$p")" != "$(lower "$base")" ] ||
        die "$p is the base account's own; its repositories stay with $base"
done
label=$(lower "${owners%% *}")
[ "$label" != accounts ] || die "an owner named accounts would clash with ~/.gitconfig.accounts"
file="$HOME/.gitconfig.$label"
owner_of=$(git config --file "$file" github.login 2>/dev/null || true)
[ -z "$owner_of" ] || [ "$owner_of" = "$acct" ] ||
    die "$file already belongs to $owner_of; list a different owner first"
# An owner already tied to another account would make the two fight over its repos.
for p in $patterns; do
    other=$(git config --file "$accounts" --get "includeIf.hasconfig:remote.*.url:https://github.com/$p/**.path" 2>/dev/null || true)
    # shellcheck disable=SC2088 # compared as written in the file, not expanded
    [ -z "$other" ] || [ "$other" = "~/.gitconfig.$label" ] ||
        die "$p already uses $other; remove its lines from $accounts first"
done

sign_in "$acct"

git config --file "$file" github.login "$acct"
git config --file "$file" github.owners "$owners"
git config --file "$file" user.name "$name"
git config --file "$file" user.email "$email"
use_token "$file" "$acct"
touch "$accounts"
for p in $patterns; do
    for url in "https://github.com/$p/**" "git@github.com:$p/**" "ssh://git@github.com/$p/**"; do
        k="includeIf.hasconfig:remote.*.url:$url.path"
        # shellcheck disable=SC2088 # git expands ~ in include paths
        git config --file "$accounts" --get "$k" >/dev/null ||
            git config --file "$accounts" "$k" "~/.gitconfig.$label"
    done
done
echo "OK: repositories of $owners use $acct ($email), ~/.gitconfig.$label" >&2
echo "If an organization uses SAML single sign-on, authorize GitHub CLI for it:" \
    "https://github.com/settings/applications" >&2
