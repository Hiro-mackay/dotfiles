#!/bin/bash
set -euo pipefail

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null || printf '.')
tool_input=$(printf '%s' "$input" | jq -r '
  if (.tool_input | type) == "string" then .tool_input
  else (.tool_input.command // .tool_input.patch // .tool_input.diff // "")
  end
' 2>/dev/null || true)

tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.gopkgs"' EXIT

printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null >> "$tmp" || true
printf '%s\n' "$tool_input" | awk '
  /^\*\*\* (Update|Add) File: / {
    sub(/^\*\*\* (Update|Add) File: /, "")
    print
  }
' >> "$tmp"

sort -u "$tmp" | while IFS= read -r file; do
  [ -z "$file" ] && continue
  case "$file" in
    /*) path="$file" ;;
    *) path="$cwd/$file" ;;
  esac
  [ -f "$path" ] || continue

  case "$path" in
    *.js | *.jsx | *.ts | *.tsx)
      matches=$(grep -n 'console\.log' "$path" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        printf '[Hook] console.log detected in %s:\n%s\n' "$path" "$matches" >&2
      fi
      ;;
    *.go)
      matches=$(grep -En 'fmt\.Print(ln|f)?' "$path" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        printf '[Hook] fmt.Print* detected in %s:\n%s\n' "$path" "$matches" >&2
      fi
      dirname "$path" >> "$tmp.gopkgs"
      ;;
    *.py)
      matches=$(grep -n '^[[:space:]]*print(' "$path" 2>/dev/null || true)
      if [ -n "$matches" ]; then
        printf '[Hook] print() detected in %s:\n%s\n' "$path" "$matches" >&2
      fi
      ;;
  esac
done

if [ -f "$tmp.gopkgs" ] && command -v go >/dev/null 2>&1; then
  sort -u "$tmp.gopkgs" | while IFS= read -r pkg_dir; do
    [ -d "$pkg_dir" ] || continue
    output=$(cd "$pkg_dir" && go vet . 2>&1) || true
    if [ -n "$output" ]; then
      printf '[Hook] go vet issues in %s:\n%s\n' "$pkg_dir" "$output" >&2
    fi
  done
fi
