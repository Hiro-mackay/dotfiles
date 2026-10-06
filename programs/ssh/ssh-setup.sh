# ssh-setup: add one host to ~/.ssh/config interactively, creating its key if needed.
# ~/.ssh/config is not managed by Nix; this only appends a block for a new Host.

ask() { # ask <prompt> <default> -> answer on stdout
    printf '%s [%s]: ' "$1" "$2" >&2
    read -r reply || reply=
    printf '%s\n' "${reply:-$2}"
}
yes_no() { # yes_no <prompt> <y|n>
    case "$(ask "$1 (y/n)" "$2")" in [yY]*) return 0 ;; *) return 1 ;; esac
}

config="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$config"
chmod 600 "$config"

alias=$(ask "Host name to use with 'ssh <name>'" "")
[ -n "$alias" ] || { echo "error: a host name is required" >&2; exit 1; }
if grep -qiE "^[[:space:]]*Host([[:space:]].*)?[[:space:]]$alias([[:space:]]|$)" "$config"; then
    echo "error: Host $alias is already in $config; edit it there" >&2
    exit 1
fi

case "$alias" in
github.com* | *.github.com) default_hostname=github.com ;;
gitlab.com* | *.gitlab.com) default_hostname=gitlab.com ;;
*) default_hostname=$alias ;;
esac
hostname=$(ask "HostName (the real server)" "$default_hostname")
case "$hostname" in
github.com | gitlab.com | bitbucket.org) default_user=git ;;
*) default_user=$(id -un) ;;
esac
user=$(ask "User" "$default_user")
port=$(ask "Port" "22")
key=$(ask "Key file" "$HOME/.ssh/id_ed25519_$(printf '%s' "$alias" | tr -c 'A-Za-z0-9._-' '_')")
forward=no
if yes_no "Forward your SSH agent to this host (only for hosts you trust)" n; then forward=yes; fi

if [ -f "$key" ]; then
    echo "Using the existing key $key" >&2
else
    echo "Creating $key; choose a passphrase (macOS keeps it in the Keychain)" >&2
    ssh-keygen -t ed25519 -f "$key" -C "$(id -un)@$(hostname -s) $alias"
fi

{
    printf '\nHost %s\n' "$alias"
    printf '  HostName %s\n  User %s\n' "$hostname" "$user"
    [ "$port" = 22 ] || printf '  Port %s\n' "$port"
    printf '  IdentityFile %s\n  IdentitiesOnly yes\n  AddKeysToAgent yes\n' "$key"
    [ "$(uname -s)" != Darwin ] || printf '  UseKeychain yes\n'
    [ "$forward" = no ] || printf '  ForwardAgent yes\n'
} >>"$config"
echo "Added Host $alias to $config" >&2

echo "Public key:" >&2
cat "$key.pub"
if command -v pbcopy >/dev/null 2>&1; then
    pbcopy <"$key.pub"
    echo "(copied to the clipboard)" >&2
fi

if [ "$hostname" = github.com ] && command -v gh >/dev/null 2>&1 &&
    login=$(gh api user --jq .login 2>/dev/null); then
    if yes_no "Add this key to the GitHub account $login with gh (switch first with 'gh auth switch' if that is not the account)" y; then
        gh ssh-key add "$key.pub" --title "$(hostname -s) $alias"
    fi
fi

if yes_no "Try connecting now" y; then
    ssh -T "$alias" || true
fi
