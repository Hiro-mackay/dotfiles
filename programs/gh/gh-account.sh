# gh-account: set up a GitHub account's SSH key and the git settings that use it.
#
#   gh-account              the base account: its key ~/.ssh/id_ed25519_github, once per machine
#   gh-account <owner>...   another account, for the repositories of these owners
#
# git picks the base account's key for every github.com remote (programs/git). Another
# account gets a name (e.g. work) and a file ~/.gitconfig.<name> holding its identity
# and its key, included for its owners' remotes. Both switch together, so a commit and
# the key that pushes it always belong to the same account.

accounts="$HOME/.gitconfig.accounts"
host=$(hostname -s)

die() {
    echo "error: $*" >&2
    exit 1
}
ask() { # ask <prompt> <default> -> answer on stdout
    printf '%s [%s]: ' "$1" "$2" >&2
    read -r reply || reply=
    printf '%s\n' "${reply:-$2}"
}
login() { gh api user --jq .login 2>/dev/null; }
sign_in() { # sign_in [login]: make that account active in gh, adding it if needed
    if [ -n "${1:-}" ] && gh auth switch -h github.com -u "$1" >/dev/null 2>&1; then
        return
    fi
    echo "Sign in to GitHub${1:+ as $1} in the browser" >&2
    gh auth login -h github.com -p ssh --skip-ssh-key -w -s admin:public_key
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
        { gh auth refresh -h github.com -s admin:public_key && gh ssh-key add "$1" --title "$host"; }
}
check() { # check <key> <login>: the key signs in to GitHub as that account
    # ssh -T always exits 1 on GitHub; the greeting names the account.
    greeting=$(ssh -i "$1" -o IdentitiesOnly=yes -T git@github.com 2>&1 || true)
    if printf '%s\n' "$greeting" | grep -q "Hi $2!"; then
        echo "OK: this key signs in to GitHub as $2" >&2
    else
        die "this key does not sign in to GitHub as $2; check the key on github.com/settings/keys"
    fi
}

if [ $# -eq 0 ]; then
    me=$(login) || { sign_in && me=$(login); } || die "could not sign in with gh"
    key="$HOME/.ssh/id_ed25519_github"
    make_key "$key" "$me"
    register "$key.pub"
    check "$key" "$me"
    exit
fi

base=$(login) || die "set up the base account first: run gh-account"
# Owners as GitHub spells them; git matches URLs case-sensitively, GitHub does not.
owners=''
for o in "$@"; do
    canonical=$(gh api "users/$o" --jq .login 2>/dev/null) || die "no GitHub user or organization named $o"
    owners="$owners $canonical"
    lower=$(printf '%s' "$canonical" | tr '[:upper:]' '[:lower:]')
    [ "$lower" = "$canonical" ] || owners="$owners $lower"
done

label=$(ask "Short name for this account, for ~/.gitconfig.<name> (e.g. work)" "")
case "$label" in accounts | *[!a-z0-9_-]* | '') die "use lowercase letters, digits, - or _ (not 'accounts')" ;; esac
file="$HOME/.gitconfig.$label"
key="$HOME/.ssh/id_ed25519_github_$label"
# An owner already tied to another account would make the two fight over its repos.
for owner in $owners; do
    k="includeIf.hasconfig:remote.*.url:git@github.com:$owner/**.path"
    other=$(git config --file "$accounts" --get "$k" 2>/dev/null || true)
    # shellcheck disable=SC2088 # compared as written in the file, not expanded
    [ -z "$other" ] || [ "$other" = "~/.gitconfig.$label" ] ||
        die "$owner already uses $other; remove its lines from $accounts first"
done

acct=$(ask "GitHub login of that account" "")
# gh stays signed in to the base account afterwards, also when this stops early.
trap 'gh auth switch -h github.com -u "$base" >/dev/null 2>&1 || true' EXIT
sign_in "$acct"
acct=$(login) || die "could not sign in with gh"
[ "$acct" != "$base" ] || die "that is the base account ($base); sign in to the other one"
name=$(ask "Name for its commits" "$(git config --file "$file" user.name || gh api user --jq '.name // ""')")
email=$(ask "Email for its commits" "$(git config --file "$file" user.email || gh api user --jq '.email // ""')")
make_key "$key" "$acct"
register "$key.pub"

git config --file "$file" user.name "$name"
git config --file "$file" user.email "$email"
git config --file "$file" core.sshCommand \
    "ssh -i ~/.ssh/id_ed25519_github_$label -o IdentitiesOnly=yes -o AddKeysToAgent=yes -o IgnoreUnknown=UseKeychain -o UseKeychain=yes"

touch "$accounts"
for owner in $owners; do
    for url in "git@github.com:$owner/**" "ssh://git@github.com/$owner/**" "https://github.com/$owner/**"; do
        k="includeIf.hasconfig:remote.*.url:$url.path"
        # shellcheck disable=SC2088 # git expands ~ in include paths
        git config --file "$accounts" --get "$k" >/dev/null ||
            git config --file "$accounts" "$k" "~/.gitconfig.$label"
    done
done
echo "Repositories of$owners now use $acct ($email) and its key" >&2
check "$key" "$acct"
