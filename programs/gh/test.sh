#!/bin/sh
# Account switching end to end, with a fake gh and a fake github.com over HTTPS that
# records which account git sends. Uses the installed gh-setup and git settings in a
# throwaway HOME; needs git, python3, openssl, and root or sudo (for /etc/hosts and
# port 443, both restored on exit).
#
#   sh programs/gh/test.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
setup=$(command -v gh-setup)
real_config=${XDG_CONFIG_HOME:-$HOME/.config}/git/config
SUDO=''
[ "$(id -u)" = 0 ] || SUDO=sudo
T=$(mktemp -d)
fails=0
check() { # check <what> <expected> <actual>
    if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected '$2', got '$3'" && fails=$((fails + 1)); fi
}

# A fake gh: accounts in $T/accts, the active one in $T/active, tokens token-<login>.
mkdir -p "$T/bin" "$T/home/.config/git"
cat >"$T/bin/gh" <<'EOF'
#!/bin/sh
st=$GH_FAKE; cur=$(cat $st/active 2>/dev/null)
case "$*" in
"api user --jq .login") if [ -n "${GH_TOKEN:-}" ]; then echo "${GH_TOKEN#token-}"; else [ -n "$cur" ] && echo "$cur"; fi ;;
"api users/"*" --jq .login")
    case "$(echo "${2#users/}" | tr A-Z a-z)" in
    acme) echo Acme ;; acme-labs) echo acme-labs ;; hiro-mackay) echo Hiro-mackay ;; work-me) echo work-me ;;
    ssoorg) echo "HTTP 403: Resource protected by organization SAML enforcement" >&2 && exit 1 ;;
    *) echo "HTTP 404: Not Found" >&2 && exit 1 ;;
    esac ;;
"api user/orgs --jq "*) [ "$cur" = work-me ] && printf 'Acme\nacme-labs\nSsoOrg\n' ;;
"api user --jq "*@tsv*) printf '%s\t%s\n' "$cur" "7+$cur@users.noreply.github.com" ;;
"api -i user") echo "X-Oauth-Scopes: gist, read:org, repo, workflow" ;;
"auth switch -h github.com -u "*) for u in "$@"; do :; done; grep -qx "$u" $st/accts && echo "$u" >$st/active ;;
"auth login"*) cp $st/next $st/active && cat $st/next >>$st/accts ;;
"auth token -h github.com -u "*) for u in "$@"; do :; done; grep -qx "$u" $st/accts && echo "token-$u" ;;
"config set -h github.com git_protocol https") ;;
*) echo "as ${GH_TOKEN#token-}" ;;
esac
EOF
chmod +x "$T/bin/gh"
sed "s|@gh@|$T/bin/gh|" "$here/gh-wrapper.sh" >"$T/bin/ghw"
chmod +x "$T/bin/ghw"
# The installed git settings, with git's credential helper calling the fake gh.
helper=$(git config --file "$real_config" --get-all credential.https://github.com.helper | tail -n 1)
sed "s|[^ (]*/bin/gh auth token|$T/bin/gh auth token|" "$helper" >"$T/bin/git-credential-gh-account"
chmod +x "$T/bin/git-credential-gh-account"
sed "s|$helper|$T/bin/git-credential-gh-account|" "$real_config" >"$T/home/.config/git/config"
: >"$T/home/.gitconfig.accounts"

# XDG_CONFIG_HOME too: git and gh read their settings there (CI runners set it).
export HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" GH_FAKE="$T" PATH="$T/bin:$PATH" \
    GIT_TERMINAL_PROMPT=0 GIT_SSL_NO_VERIFY=1
unset GH_TOKEN GITHUB_TOKEN GH_HOST GH_CONFIG_DIR
: >"$T/accts"

echo Hiro-mackay >"$T/next"
printf '\n' | "$setup" >/dev/null 2>&1
check "base account signed in" Hiro-mackay "$(cat "$T/active")"
echo work-me >"$T/next"
printf 'work-me\nacme-labs acme\n\n\n' | "$setup" >/dev/null 2>&1
check "other account file" work-me "$(git config --file "$HOME/.gitconfig.acme-labs" github.login)"
check "noreply email by default" 7+work-me@users.noreply.github.com "$(git config --file "$HOME/.gitconfig.acme-labs" user.email)"
check "gh back on the base account" Hiro-mackay "$(cat "$T/active")"
check "conditions: acme-labs, Acme, acme, work-me x 3 URL forms" 12 "$(grep -c '^\[includeIf' "$HOME/.gitconfig.accounts")"
# A hand-written condition for the same file survives a rerun that drops an owner.
# shellcheck disable=SC2088 # written as gh-setup writes it, for git to expand
git config --file "$HOME/.gitconfig.accounts" 'includeIf.gitdir:~/work/.path' '~/.gitconfig.acme-labs'
printf 'work-me\nacme\n\n\n' | "$setup" >/dev/null 2>&1
check "file kept on rerun" "" "$(ls "$HOME/.gitconfig.acme" 2>/dev/null)"
check "dropped owner's conditions removed" 0 "$(grep -c 'acme-labs/' "$HOME/.gitconfig.accounts")"
check "hand-written condition kept" 1 "$(grep -c 'gitdir:~/work/' "$HOME/.gitconfig.accounts")"
printf 'work-me\nacme ssoorg\n\n\n' | "$setup" >/dev/null 2>&1
check "an organization refusing the lookup, spelled as a member" 1 "$(grep -c 'https://github.com/SsoOrg/' "$HOME/.gitconfig.accounts")"
check "a misspelled owner is refused" 1 "$(printf 'work-me\nnosuchorg\n\n\n' | "$setup" 2>&1 | grep -c 'no GitHub user or organization named nosuchorg')"
printf 'work-me\nacme\n\n\n' | "$setup" >/dev/null 2>&1
check "base login refused as an owner" 1 "$(printf 'work-me\nHiro-mackay\n\n\n' | "$setup" 2>&1 | grep -c "base account's own")"

# A fake github.com that records the account in each request's credentials.
cp /etc/hosts "$T/hosts.orig"
cleanup() {
    [ -z "${server:-}" ] || $SUDO kill "$server" 2>/dev/null || true
    $SUDO cp "$T/hosts.orig" /etc/hosts
}
trap cleanup EXIT
echo "127.0.0.1 github.com" | $SUDO tee -a /etc/hosts >/dev/null
openssl req -x509 -newkey rsa:2048 -nodes -keyout "$T/key.pem" -out "$T/cert.pem" -days 1 -subj /CN=github.com 2>/dev/null
cat >"$T/server.py" <<EOF
import base64, http.server, ssl
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        a = self.headers.get('Authorization')
        if not a:
            self.send_response(401); self.send_header('WWW-Authenticate', 'Basic realm="GitHub"'); self.end_headers(); return
        user = base64.b64decode(a.split()[1]).decode().partition(':')[0]
        open('$T/auth', 'a').write(self.path.split('/info')[0] + ' ' + user + '\n')
        self.send_response(404); self.end_headers()
    def log_message(self, *a): pass
s = http.server.HTTPServer(('127.0.0.1', 443), H)
c = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER); c.load_cert_chain('$T/cert.pem', '$T/key.pem')
s.socket = c.wrap_socket(s.socket, server_side=True)
open('$T/ready', 'w').close()
s.serve_forever()
EOF
$SUDO python3 "$T/server.py" &
server=$!
until [ -e "$T/ready" ]; do sleep 0.1; done
sent() { # sent <clone url>: the account git sends while cloning it
    : >"$T/auth"
    git clone -q "$1" "$T/clone/$(printf '%s' "$1" | tr ':/' '__')" 2>"$T/clone.err" || true
    [ -s "$T/auth" ] || sed 's/^/    | /' "$T/clone.err" >&2
    cut -d ' ' -f 2 "$T/auth" | sort -u
}
check "clone https acme" work-me "$(sent https://github.com/acme/a)"
check "clone git@ Acme" work-me "$(sent git@github.com:Acme/b)"
check "clone ssh:// acme" work-me "$(sent ssh://git@github.com/acme/c)"
check "clone the account's own repo" work-me "$(sent https://github.com/work-me/d)"
check "clone personal" Hiro-mackay "$(sent https://github.com/me/e)"
check "clone a look-alike owner" Hiro-mackay "$(sent https://github.com/acme-labs/f)"

repo() { git init -q "$T/r/$1" && git -C "$T/r/$1" remote add origin "$2" && mkdir -p "$T/r/$1/sub"; }
repo work git@github.com:Acme/w
repo own https://github.com/me/o
check "work repo email" 7+work-me@users.noreply.github.com "$(git -C "$T/r/work/sub" config user.email)"
check "own repo email" 43330841+Hiro-mackay@users.noreply.github.com "$(git -C "$T/r/own" config user.email)"
echo work-me >"$T/active"
check "gh in a work repo subdirectory" "as work-me" "$(cd "$T/r/work/sub" && ghw pr list)"
check "gh in an own repo" "as Hiro-mackay" "$(cd "$T/r/own" && ghw pr list)"
check "gh -R work outside" "as work-me" "$(cd "$T" && ghw pr list -R github.com/acme/x)"
check "gh repo clone work outside" "as work-me" "$(cd "$T" && ghw repo clone --upstream-remote-name up ACME/x)"
check "gh --body URL ignored" "as Hiro-mackay" "$(cd "$T/r/own" && ghw pr create --body https://github.com/acme/x/issues/1)"
check "gh --template ignored" "as Hiro-mackay" "$(cd "$T" && ghw repo create --template acme/t me/n)"
check "gh with GITHUB_TOKEN untouched" "as " "$(cd "$T/r/work" && GITHUB_TOKEN=x ghw pr list)"
check "gh auth token follows the repository" token-work-me "$(cd "$T/r/work" && ghw auth token)"
check "gh auth token elsewhere" token-Hiro-mackay "$(cd "$T/r/own" && ghw auth token)"
check "gh auth token -u as given" token-Hiro-mackay "$(cd "$T/r/work" && ghw auth token -h github.com -u Hiro-mackay)"
check "gh auth status names the account" 1 "$(cd "$T/r/work" && ghw auth status 2>&1 | grep -c 'for this repository: work-me')"
mkdir -p "$HOME/.config/gh"
printf 'github.com:\n    user: Hiro-mackay\n' >"$HOME/.config/gh/hosts.yml"
check "gh uses the active account as is" "as " "$(cd "$T/r/own" && ghw pr list)"
rm "$HOME/.config/gh/hosts.yml"
sed -i.bak '/^work-me$/d' "$T/accts"
check "local commands need no account" "as " "$(cd "$T/r/work" && ghw config get git_protocol)"
check "gh refuses a signed-out account" 1 "$(cd "$T/r/work" && ghw pr list 2>&1 | grep -c 'run gh-setup')"

if [ "$fails" != 0 ]; then echo "$fails failed" && exit 1; fi
echo "all passed"
