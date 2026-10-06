# gh-setup: set up one GitHub account on this machine, asking which one.
#
# git and gh both use gh's token, over HTTPS (programs/git rewrites SSH URLs). The base
# account (github.login in programs/git) serves every GitHub repository. Another
# account gets ~/.gitconfig.<owner>, named after the first owner whose repositories it
# serves, holding its identity and its login (for git's credential helper), and
# included for those owners' remotes. Both switch together, so a commit and the push always belong to the same
# account; gh follows the same choice (gh-wrapper.sh).

# Switch gh's accounts by hand here, not by the current repository (gh-wrapper.sh).
export GH_NO_AUTO_ACCOUNT=1
accounts="$HOME/.gitconfig.accounts"
# The URL forms a remote can name GitHub with; each owner gets a condition per form.
forms='https://github.com/ git@github.com: ssh://git@github.com/'

die() {
    echo "error: $*" >&2
    exit 1
}
title() { printf '\n\033[1m== %s ==\033[0m\n' "$1" >&2; }
ask() { # ask <label> [default] -> answer on stdout; Enter takes the default
    if [ -n "${2:-}" ]; then printf '%s [%s]: ' "$1" "$2" >&2; else printf '%s: ' "$1" >&2; fi
    read -r reply || reply=
    printf '%s\n' "${reply:-${2:-}}"
}
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
active() { gh api user --jq .login 2>/dev/null; }
signed_in=$(active || true)
canonical() { # canonical <login>: as GitHub spells it, when gh can ask; else unchanged
    # The account's own organizations first: an organization with SAML SSO or an
    # OAuth app policy can refuse the lookup below.
    for k in ${known:-}; do
        [ "$(lower "$k")" != "$(lower "$1")" ] || { printf '%s\n' "$k" && return; }
    done
    [ -n "$signed_in" ] || { printf '%s\n' "$1" && return; }
    if out=$(gh api "users/$1" --jq .login 2>&1); then
        printf '%s\n' "$out"
    else
        case "$out" in *"HTTP 404"*) die "no GitHub user or organization named $1" ;; esac
        echo "warning: GitHub did not confirm $1 ($out); using it as typed" >&2
        printf '%s\n' "$1"
    fi
}
sign_in() { # sign_in <login>: make that account active in gh, adding it if needed
    if ! gh auth switch -h github.com -u "$1" >/dev/null 2>&1; then
        echo "Signing in as $1 in the browser..." >&2
        # With https, gh would offer to set itself up as git's credential helper and
        # override the per-account ones; ssh skips that, then the protocol goes back.
        gh auth login -h github.com -p ssh --skip-ssh-key -w -s workflow
        gh config set -h github.com git_protocol https
    fi
    signed_in=$(active || true)
    [ "$(lower "$signed_in")" = "$(lower "$1")" ] || die "gh is signed in as $signed_in, not $1"
    # Pushing changes under .github/workflows needs the workflow scope.
    gh api -i user 2>/dev/null | grep -i '^x-oauth-scopes:' | grep -q workflow ||
        gh auth refresh -h github.com -s workflow
}
# The base account, from the shared settings (--global skips the accounts file).
base=$(git config --global github.login 2>/dev/null) || die "no github.login in the git settings"

title "GitHub account"
acct=$(ask "Login" "$base")
[ -n "$acct" ] || die "a GitHub login is required"
acct=$(canonical "$acct")
# gh stays signed in to the base account afterwards, also when this stops early.
trap 'gh auth switch -h github.com -u "$base" >/dev/null 2>&1 || true' EXIT

if [ "$(lower "$acct")" = "$(lower "$base")" ]; then
    sign_in "$acct"
    echo "Done: $acct, the base account, for all of GitHub" >&2
    exit
fi

# Another account: sign in first, so its organizations and profile can be offered.
sign_in "$acct"
acct=$signed_in
file=''
for f in "$HOME"/.gitconfig.*; do
    [ "$(git config --file "$f" github.login 2>/dev/null)" = "$acct" ] && file=$f
done
prev() { [ -z "$file" ] || git config --file "$file" "$1" 2>/dev/null || true; }
known=$(gh api user/orgs --jq '.[].login' 2>/dev/null | tr '\n' ' ' || true)
orgs=$(printf '%s' "$known" | sed 's/ *$//; s/ /, /g')
echo "  member of: ${orgs:-none}" >&2
earlier=''
for o in $(prev github.owners); do [ "$(lower "$o")" = "$(lower "$acct")" ] || earlier="$earlier $o"; done
answer=$(ask "Organizations" "${earlier# }")
# Defaults: the earlier answers, else its GitHub profile name and noreply address.
IFS='	' read -r profile_name noreply <<EOF
$(gh api user --jq '[.name // .login, "\(.id)+\(.login)@users.noreply.github.com"] | @tsv')
EOF
pn=$(prev user.name) pe=$(prev user.email)
name=$(ask "Commit name" "${pn:-$profile_name}")
email=$(ask "Commit email" "${pe:-$noreply}")
[ -n "$name" ] && [ -n "$email" ] || die "a name and an email are required"

# Owners as GitHub spells them, plus lowercase: git matches URLs case-sensitively.
# The file is named after the first organization given, or the account itself.
owners='' patterns=''
for o in $answer $acct; do
    [ "$o" = "$acct" ] || o=$(canonical "$o")
    [ "$(lower "$o")" != "$(lower "$base")" ] ||
        die "$o is the base account's own; its repositories stay with $base"
    case " $owners " in *" $o "*) continue ;; esac
    owners="$owners $o"
    patterns="$patterns $o"
    [ "$(lower "$o")" = "$o" ] || patterns="$patterns $(lower "$o")"
done
owners=${owners# }
# An account set up before keeps its file; a new one is named after its first owner.
if [ -n "$file" ]; then label=${file#"$HOME/.gitconfig."}; else label=$(lower "${owners%% *}"); fi
[ "$label" != accounts ] || die "an owner named accounts would clash with ~/.gitconfig.accounts"
file="$HOME/.gitconfig.$label"
owner_of=$(git config --file "$file" github.login 2>/dev/null || true)
[ -z "$owner_of" ] || [ "$owner_of" = "$acct" ] ||
    die "$file already belongs to $owner_of; list a different organization first"
# An owner already tied to another account would make the two fight over its repos.
for p in $patterns; do
    other=$(git config --file "$accounts" --get "includeIf.hasconfig:remote.*.url:https://github.com/$p/**.path" 2>/dev/null || true)
    # shellcheck disable=SC2088 # compared as written in the file, not expanded
    [ -z "$other" ] || [ "$other" = "~/.gitconfig.$label" ] ||
        die "$p already uses $other; remove its lines from $accounts first"
done

git config --file "$file" github.login "$acct"
git config --file "$file" github.owners "$owners"
git config --file "$file" user.name "$name"
git config --file "$file" user.email "$email"
git config --file "$file" credential.https://github.com.username "$acct"
touch "$accounts"
# This account's conditions are rewritten from scratch, so dropped owners go away.
# Only the form written here is touched; hand-written conditions stay.
{ git config --file "$accounts" --get-regexp '^includeif\.hasconfig:remote\.\*\.url:.*/\*\*\.path$' 2>/dev/null || true; } |
    while read -r k v; do
        # shellcheck disable=SC2088 # compared as written in the file, not expanded
        [ "$v" != "~/.gitconfig.$label" ] || git config --file "$accounts" --unset-all "$k"
    done
for p in $patterns; do
    for form in $forms; do
        # shellcheck disable=SC2088 # git expands ~ in include paths
        git config --file "$accounts" "includeIf.hasconfig:remote.*.url:$form$p/**.path" "~/.gitconfig.$label"
    done
done
echo "Done: $acct for $owners (~/.gitconfig.$label)" >&2
echo "  SAML SSO organizations: authorize GitHub CLI at https://github.com/settings/applications" >&2
