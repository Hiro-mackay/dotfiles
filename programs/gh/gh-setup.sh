# gh-setup: set up one GitHub account on this machine, asking which one.
#
# The base account (the one in ~/.gitconfig.accounts) gets the key
# ~/.ssh/id_ed25519_github, which git uses for every github.com remote (programs/git).
# Another account gets ~/.gitconfig.<owner>, named after the first owner whose
# repositories it serves, holding its identity and its key, and included for those
# owners' remotes. Both switch together, so a commit and the key that pushes it always
# belong to the same account.

# Switch gh's accounts by hand here, not by the current repository (gh-wrapper.sh).
export GH_NO_AUTO_ACCOUNT=1
accounts="$HOME/.gitconfig.accounts"
host=$(hostname -s)
ssh_opts='-o IdentitiesOnly=yes -o AddKeysToAgent=yes -o IgnoreUnknown=UseKeychain -o UseKeychain=yes'

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
    gh auth switch -h github.com -u "$1" >/dev/null 2>&1 && return
    echo "Sign in to GitHub as $1 in the browser" >&2
    gh auth login -h github.com -p ssh --skip-ssh-key -w -s write:public_key
    [ "$(lower "$(active)")" = "$(lower "$1")" ] || die "gh is signed in as $(active), not $1"
}
make_key() { # make_key <file> <login>
    [ -f "$1" ] && return
    echo "Creating $1; choose a passphrase (macOS keeps it in the Keychain)" >&2
    ssh-keygen -q -t ed25519 -f "$1" -C "$2@$host"
}
register() { # register <public key file>: add it to the active account unless it is there
    body=$(cut -d ' ' -f 1,2 "$1")
    keys=$(gh api user/keys --jq '.[].key' 2>/dev/null || true)
    printf '%s\n' "$keys" | grep -qxF "$body" && return
    gh ssh-key add "$1" --title "$host" 2>/dev/null ||
        { gh auth refresh -h github.com -s write:public_key && gh ssh-key add "$1" --title "$host"; }
}
check() { # check <key> <login>: the key signs in to GitHub as that account
    # shellcheck disable=SC2086 # $ssh_opts is a list of options
    greeting=$(ssh -i "$1" $ssh_opts -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 || true)
    # ssh -T always exits 1 on GitHub; the greeting names the account.
    printf '%s\n' "$greeting" | grep -qi "Hi $2!" ||
        die "this key does not sign in to GitHub as $2; check it at https://github.com/settings/keys"
    echo "OK: this key signs in to GitHub as $2" >&2
}

# The base account: recorded in the accounts file, or read from its noreply email.
base=$(git config --file "$accounts" github.login 2>/dev/null || true)
[ -n "$base" ] || base=$(git config --file "$accounts" user.email 2>/dev/null |
    sed -n 's/^[0-9]*+\(.*\)@users\.noreply\.github\.com$/\1/p' || true)

title "GitHub account setup"
acct=$(ask "the GitHub login of the account to set up" "$base")
[ -n "$acct" ] || die "a GitHub login is required"
acct=$(canonical "$acct")
# With no base account known yet, this one becomes it once it works.
[ -n "$base" ] || base=$acct
# gh stays signed in to the base account afterwards, also when this stops early.
trap 'gh auth switch -h github.com -u "$base" >/dev/null 2>&1 || true' EXIT

if [ "$(lower "$acct")" = "$(lower "$base")" ]; then
    echo "$acct is the base account: key ~/.ssh/id_ed25519_github, used for all of GitHub" >&2
    sign_in "$acct"
    make_key "$HOME/.ssh/id_ed25519_github" "$acct"
    register "$HOME/.ssh/id_ed25519_github.pub"
    check "$HOME/.ssh/id_ed25519_github" "$acct"
    git config --file "$accounts" github.login >/dev/null 2>&1 ||
        git config --file "$accounts" github.login "$acct"
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
label=$(lower "${owners%% *}")
[ "$label" != accounts ] || die "an owner named accounts would clash with ~/.gitconfig.accounts"
file="$HOME/.gitconfig.$label"
key="$HOME/.ssh/id_ed25519_github_$label"
owner_of=$(git config --file "$file" github.login 2>/dev/null || true)
[ -z "$owner_of" ] || [ "$owner_of" = "$acct" ] ||
    die "$file already belongs to $owner_of; list a different owner first"
# An owner already tied to another account would make the two fight over its repos.
for p in $patterns; do
    other=$(git config --file "$accounts" --get "includeIf.hasconfig:remote.*.url:git@github.com:$p/**.path" 2>/dev/null || true)
    # shellcheck disable=SC2088 # compared as written in the file, not expanded
    [ -z "$other" ] || [ "$other" = "~/.gitconfig.$label" ] ||
        die "$p already uses $other; remove its lines from $accounts first"
done

sign_in "$acct"
make_key "$key" "$acct"
register "$key.pub"

git config --file "$file" github.login "$acct"
git config --file "$file" github.owners "$owners"
git config --file "$file" user.name "$name"
git config --file "$file" user.email "$email"
git config --file "$file" core.sshCommand "ssh -i ~/.ssh/id_ed25519_github_$label $ssh_opts"
touch "$accounts"
for p in $patterns; do
    # HTTPS remotes would push with gh's token for the base account; send them over SSH.
    git config --file "$file" --get-all "url.git@github.com:$p/.insteadOf" >/dev/null ||
        git config --file "$file" --add "url.git@github.com:$p/.insteadOf" "https://github.com/$p/"
    for url in "git@github.com:$p/**" "ssh://git@github.com/$p/**" "https://github.com/$p/**"; do
        k="includeIf.hasconfig:remote.*.url:$url.path"
        # shellcheck disable=SC2088 # git expands ~ in include paths
        git config --file "$accounts" --get "$k" >/dev/null ||
            git config --file "$accounts" "$k" "~/.gitconfig.$label"
    done
done
echo "Repositories of $owners now use $acct ($email) and its key, ~/.gitconfig.$label" >&2
check "$key" "$acct"
echo "If an organization uses SAML single sign-on, authorize this key for it:" \
    "https://github.com/settings/keys > Configure SSO" >&2
