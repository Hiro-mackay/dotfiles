# -----------------
#  filesystem
# -----------------
mkcd() { mkdir -p "$1" && cd "$1" }

bigfiles() {
  du -ah "${1:-.}" 2>/dev/null | sort -rh | head -20
}

# -----------------
#  network
# -----------------
killport() {
  if [[ -z "$1" ]]; then
    echo "Usage: killport <port>"
    return 1
  fi
  local pids=$(lsof -t -i:"$1")
  if [[ -z "$pids" ]]; then
    echo "No process found on port $1"
    return 1
  fi
  kill $pids && echo "Killed processes on port $1: $pids"
}

ports() {
  lsof -iTCP -sTCP:LISTEN -n -P | awk 'NR>1 {printf "%-8s %-6s %s\n", $1, $2, $9}'
}

# -----------------
#  container: disposable environments
# -----------------
ubuntu() {
  local rt
  if command -v podman &>/dev/null; then
    rt=podman
  elif command -v docker &>/dev/null; then
    rt=docker
  else
    echo "Error: podman or docker required"
    return 1
  fi
  "$rt" run --rm -it ubuntu bash
}

# -----------------
#  clipboard
# -----------------
jc() {
  pbpaste | jq . | pbcopy && pbpaste
}

# -----------------
#  HTTP client
# -----------------
cget() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    cat <<'USAGE'
Usage: cget [option] <url>

Default behavior (no option): show status, timing, and size summary.

Options:
  -b, --body            show response body (auto-formats JSON/HTML)
  -I, --head            show response headers only
  -i, --show-headers    show headers + body

Examples:
  cget https://api.example.com/users        timing summary
  cget -b https://api.example.com/users     pretty-printed JSON body
  cget -I https://example.com               headers only
  cget -i https://example.com               headers + body
USAGE
    [[ -z "$1" ]] && return 1
    return 0
  fi

  local url=""
  local show_headers=false
  local show_body=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --head|-I) show_headers=true ;;
      --body|-b) show_body=true ;;
      --show-headers|-i)
        show_headers=true
        show_body=true
        ;;
      *)
        if [[ "$1" == "http"* ]]; then
          url="$1"
        else
          echo "cget: invalid option '$1'. Run 'cget -h' for usage." >&2
          return 1
        fi
    esac
    shift
  done

  local tmpfile=$(mktemp)
  local response_headers=""
  local response_body=""

  if $show_headers && $show_body; then
    response_body=$(curl -sL -D "$tmpfile" "$url")
  elif $show_headers; then
    curl -sL -D "$tmpfile" "$url" > /dev/null
  elif $show_body; then
    response_body=$(curl -sL "$url")
  else
    curl "$url" -o /dev/null -w '%{scheme}/%{http_version} %{response_code}\ntime_total: %{time_total}\nsize_header: %{size_header}\nsize_download: %{size_download}\n' -s
    rm -f "$tmpfile"
    return
  fi

  if $show_headers; then
    response_headers=$(<"$tmpfile")
    rm -f "$tmpfile"
    echo "$response_headers"
  else
    rm -f "$tmpfile"
  fi

  if $show_body; then
    if echo "$response_headers" | grep -q "application/json"; then
      echo "$response_body" | jq .
    elif echo "$response_headers" | grep -q "text/html"; then
      echo "$response_body" | htmlq --remove-nodes script,style,svg,link -p
      echo "\n\n ---"
      echo "Ignore <script>, <style>, <svg>, <link>"
    elif echo "$response_headers" | grep -q "text/.*"; then
      echo "$response_body"
    else
      echo "File Size: $(echo "$response_body" | wc -c) bytes"
    fi
  fi
}

# -----------------
#  random string
# -----------------
rndl() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'USAGE'
Usage: rndl [-s] [length]
  -s, --symbols   include symbols (default: alphanumeric only)
  length          string length (default: 32)

Examples:
  rndl            32-char alphanumeric
  rndl 16         16-char alphanumeric
  rndl -s         32-char with symbols
  rndl -s 16      16-char with symbols
USAGE
    return 0
  fi
  local chars='a-zA-Z0-9' len=32
  [[ "$1" == "-s" || "$1" == "--symbols" ]] && { chars='a-zA-Z0-9!@#$%^&*()_+'; shift; }
  if [[ -n "$1" ]]; then
    [[ "$1" =~ ^[0-9]+$ ]] || { echo "rndl: length must be a positive integer (got '$1'). Run 'rndl -h' for usage." >&2; return 1; }
    len=$1
  fi
  LC_ALL=C tr -dc "$chars" < /dev/urandom | head -c "$len"
  echo
}

# -----------------
#  claude remote control
# -----------------
# Start a Remote Control session in the current dir for lid-closed mobile
# use: keep the Mac awake (lid closed too) and pause Power Nap for the
# session. Low Power Mode is left to the global "on battery" setting. Both
# are restored on exit (incl. Ctrl-C / kill, but not a hard power loss), so
# verify when idle with:
#   pmset -g | grep -i sleep   # SleepDisabled should be 0
#
# SECURITY: --dangerously-skip-permissions bypasses every approval prompt
# because a lid-closed mobile session cannot answer them. The agent then runs
# with full, unattended permissions. Launch ccgo only from a trusted working
# directory -- never anywhere a destructive command (rm -rf, etc.) or a prompt
# injection could do real damage without anyone watching.
ccgo() {
  trap 'sudo pmset -a disablesleep 0; sudo pmset -b powernap 1' EXIT INT TERM
  sudo pmset -a disablesleep 1   # stay awake lid-closed
  sudo pmset -b powernap 0       # no background wake during the session
  claude --remote-control "${PWD:t}" --dangerously-skip-permissions
}
