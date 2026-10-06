# ssh-setup: add one host to ~/.ssh/config, creating its key if needed.
# ~/.ssh/config is not managed by Nix; this only appends a block for a new Host.
#
#   ssh-setup [-H hostname] [-u user] [-p port] [-i keyfile] [-A] [host]
#
# Only the host name is required. The rest is derived from it, shown for
# confirmation, and can be edited there or set with the options.

usage() {
    echo "usage: ssh-setup [-H hostname] [-u user] [-p port] [-i keyfile] [-A] [host]" >&2
    exit 2
}
ask() { # ask <prompt> <default> -> answer on stdout
    printf '%s [%s]: ' "$1" "$2" >&2
    read -r reply || reply=
    printf '%s\n' "${reply:-$2}"
}

hostname='' user='' port='' key='' forward=no
while getopts 'H:u:p:i:Ah' opt; do
    case "$opt" in
    H) hostname=$OPTARG ;;
    u) user=$OPTARG ;;
    p) port=$OPTARG ;;
    i) key=$OPTARG ;;
    A) forward=yes ;;
    *) usage ;;
    esac
done
shift $((OPTIND - 1))
alias=${1:-}
[ -n "$alias" ] || alias=$(ask "Host name (used as 'ssh <name>')" "")
[ -n "$alias" ] || usage

config="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$config"
chmod 600 "$config"
if grep -qiE "^[[:space:]]*Host([[:space:]].*)?[[:space:]]$alias([[:space:]]|$)" "$config"; then
    echo "error: Host $alias is already in $config; edit it there" >&2
    exit 1
fi

# Defaults derived from the host name: github.com-work -> github.com, user git.
if [ -z "$hostname" ]; then
    case "$alias" in
    github.com*) hostname=github.com ;;
    gitlab.com*) hostname=gitlab.com ;;
    bitbucket.org*) hostname=bitbucket.org ;;
    *) hostname=$alias ;;
    esac
fi
if [ -z "$user" ]; then
    case "$hostname" in
    github.com | gitlab.com | bitbucket.org) user=git ;;
    *) user=$(id -un) ;;
    esac
fi
port=${port:-22}
key=${key:-$HOME/.ssh/$alias}

show() {
    printf '\nHost %s\n  HostName %s\n  User %s\n' "$alias" "$hostname" "$user" >&2
    [ "$port" = 22 ] || printf '  Port %s\n' "$port" >&2
    printf '  IdentityFile %s%s\n' "$key" "$([ -f "$key" ] && echo ' (existing key)' || echo ' (new key)')" >&2
    [ "$forward" = no ] || printf '  ForwardAgent yes\n' >&2
}
show
case "$(ask "Write this? (y/n/e to edit)" y)" in
[yY]*) ;;
[eE]*)
    hostname=$(ask "HostName" "$hostname")
    user=$(ask "User" "$user")
    port=$(ask "Port" "$port")
    key=$(ask "Key file" "$key")
    case "$(ask "Forward your SSH agent (only for hosts you trust)? (y/n)" "$forward")" in
    [yY]*) forward=yes ;;
    *) forward=no ;;
    esac
    show
    ;;
*) exit 1 ;;
esac

if [ ! -f "$key" ]; then
    echo "Creating $key; choose a passphrase (macOS keeps it in the Keychain)" >&2
    ssh-keygen -q -t ed25519 -f "$key" -C "$(id -un)@$(hostname -s) $alias"
fi

{
    printf '\nHost %s\n  HostName %s\n  User %s\n' "$alias" "$hostname" "$user"
    [ "$port" = 22 ] || printf '  Port %s\n' "$port"
    printf '  IdentityFile %s\n  IdentitiesOnly yes\n  AddKeysToAgent yes\n' "$key"
    [ "$(uname -s)" != Darwin ] || printf '  UseKeychain yes\n'
    [ "$forward" = no ] || printf '  ForwardAgent yes\n'
} >>"$config"
echo "Added Host $alias to $config" >&2

cat "$key.pub"
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"$key.pub"
    echo "(public key copied to the clipboard)" >&2
fi

if [ "$hostname" = github.com ] && command -v gh >/dev/null 2>&1 &&
    login=$(gh api user --jq .login 2>/dev/null); then
    case "$(ask "Add this key to the GitHub account $login? ('gh auth switch' first if not) (y/n)" y)" in
    [yY]*) gh ssh-key add "$key.pub" --title "$(hostname -s) $alias" ;;
    esac
fi

# Git hosts answer `ssh -T` with a greeting; other servers would open a shell.
case "$hostname" in
github.com | gitlab.com | bitbucket.org) ssh -T "$alias" || true ;;
*) echo "Connect with: ssh $alias" >&2 ;;
esac
