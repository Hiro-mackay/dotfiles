# -----------------
#  filesystem
# -----------------
mkcd() {
  if [[ -d "$1" ]]; then
    echo "$1 already exists!"
    cd "$1"
  else
    mkdir -p "$1" && cd "$1"
  fi
}

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
#  clipboard
# -----------------
jc() {
  pbpaste | jq . | pbcopy && pbpaste
}

# -----------------
#  HTTP client
# -----------------
cget() {
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
          echo "Invalid option: $1"
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
    echo "Usage: rndl [OPTIONS] [LENGTH]"
    echo ""
    echo "Options:"
    echo "  -s, --symbols    Include symbols in the string"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  rndl             # Generate 32-character alphanumeric string (default)"
    echo "  rndl 20          # Generate 20-character alphanumeric string"
    echo "  rndl -s          # Generate 32-character alphanumeric + symbols string"
    echo "  rndl -s 20       # Generate 20-character alphanumeric + symbols string"
    return 0
  fi

  local length=32
  local include_symbols=false
  local base_charset='a-zA-Z0-9'
  local symbols='!@#$%^&*()_+'

  while [[ $# -gt 0 ]]; do
    case $1 in
      -s|--symbols)
        include_symbols=true
        shift
        ;;
      *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
          length=$1
        else
          echo "Error: Invalid argument '$1'. Use -h for help"
          return 1
        fi
        shift
        ;;
    esac
  done

  local charset="$base_charset"
  if $include_symbols; then
    charset="${charset}${symbols}"
  fi

  echo "$(LC_ALL=C tr -dc "$charset" < /dev/urandom | head -c "$length")"
}
