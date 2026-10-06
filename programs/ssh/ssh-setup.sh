# ssh-setup: add one host to ~/.ssh/config, creating its key if needed.
# ~/.ssh/config is not managed by Nix; this only adds a block for a new Host, at the
# top, because ssh takes the first value it finds and a later `Host *` must not win.
#
#   ssh-setup [-u user] [-p port] [-i keyfile] [-A] [host [hostname]]
#
# Asks for the host name and the server if not given. The rest has defaults,
# shown for confirmation, and can be edited there or set with the options.

usage() {
    echo "usage: ssh-setup [-u user] [-p port] [-i keyfile] [-A] [host [hostname]]" >&2
    exit 2
}
die() {
    echo "error: $*" >&2
    exit 1
}
ask() { # ask <prompt> <default> -> answer on stdout
    printf '%s [%s]: ' "$1" "$2" >&2
    read -r reply || reply=
    printf '%s\n' "${reply:-$2}"
}
expand() { # expand <path>: a leading ~/ becomes $HOME/, as a shell would
    case "$1" in \~/*) printf '%s\n' "$HOME/${1#\~/}" ;; *) printf '%s\n' "$1" ;; esac
}

hostname='' user='' port='' key='' forward=no
while getopts 'u:p:i:Ah' opt; do
    case "$opt" in
    u) user=$OPTARG ;;
    p) port=$OPTARG ;;
    i) key=$OPTARG ;;
    A) forward=yes ;;
    *) usage ;;
    esac
done
shift $((OPTIND - 1))
alias=${1:-} hostname=${2:-}
[ -n "$alias" ] || alias=$(ask "Host name, used as 'ssh <name>' (e.g. devbox)" "")
[ -n "$alias" ] || usage
case "$alias" in *[!A-Za-z0-9._-]*) die "use letters, digits, '.', '-' or '_' in a host name" ;; esac

config="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$config"
chmod 600 "$config"
# Every name on every Host line, compared as plain text.
if grep -iE '^[[:space:]]*Host[[:space:]]' "$config" | tr -s ' \t' '\n' | grep -qixF "$alias"; then
    die "Host $alias is already in $config; edit it there"
fi

[ -n "$hostname" ] || hostname=$(ask "Server address (e.g. 10.0.0.5)" "")
[ -n "$hostname" ] || usage
user=${user:-$(id -un)}
port=${port:-22}
key=$(expand "${key:-$HOME/.ssh/id_ed25519_$alias}")

show() {
    printf '\nHost %s\n  HostName %s\n  User %s\n' "$alias" "$hostname" "$user" >&2
    [ "$port" = 22 ] || printf '  Port %s\n' "$port" >&2
    printf '  IdentityFile %s%s\n' "$key" "$([ -f "$key" ] && echo ' (existing key)' || echo ' (new key)')" >&2
    [ "$forward" = no ] || printf '  ForwardAgent yes\n' >&2
}
while show; do
    case "$(ask "Write this? (y/n/e to edit)" y)" in
    [yY]*) break ;;
    [eE]*)
        hostname=$(ask "HostName" "$hostname")
        user=$(ask "User" "$user")
        port=$(ask "Port" "$port")
        key=$(expand "$(ask "Key file" "$key")")
        case "$(ask "Forward your SSH agent (only for hosts you trust)? (y/n)" "$forward")" in
        [yY]*) forward=yes ;;
        *) forward=no ;;
        esac
        ;;
    *) exit 1 ;;
    esac
done

if [ ! -f "$key" ]; then
    echo "Creating $key; choose a passphrase (macOS keeps it in the Keychain)" >&2
    ssh-keygen -q -t ed25519 -f "$key" -C "$(id -un)@$(hostname -s) $alias"
fi

new=$(mktemp "$config.XXXXXX")
{
    printf 'Host %s\n  HostName %s\n  User %s\n' "$alias" "$hostname" "$user"
    [ "$port" = 22 ] || printf '  Port %s\n' "$port"
    printf '  IdentityFile %s\n  IdentitiesOnly yes\n  AddKeysToAgent yes\n' "$key"
    [ "$(uname -s)" != Darwin ] || printf '  UseKeychain yes\n'
    [ "$forward" = no ] || printf '  ForwardAgent yes\n'
    printf '\n'
    cat "$config"
} >"$new"
# Written through, so a symlinked config keeps its link and its permissions.
cat "$new" >"$config"
rm -f "$new"
echo "Added Host $alias to $config" >&2

cat "$key.pub"
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"$key.pub"
    echo "(public key copied to the clipboard)" >&2
fi
echo "Connect with: ssh $alias" >&2
