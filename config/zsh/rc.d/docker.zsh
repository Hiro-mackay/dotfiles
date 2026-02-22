# -----------------
#  Docker Compose: lifecycle
# -----------------
alias dc="docker compose"
alias dcu="dc up"
alias dcud="dcu -d"
alias dcw="dcu --watch"
alias dcd="dc down"
alias dcdv="dc down --volumes"
alias dcr="dc restart"
alias dce="dc exec"
alias dcdry="dcu --dry-run"

# -----------------
#  Docker Compose: logs
# -----------------
alias dcl="dc logs --tail=50"
alias dclf="dc logs -f --tail=50"

# -----------------
#  Container: status & monitoring
# -----------------
alias dp="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dpa="docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
alias dstats="docker stats --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"

# -----------------
#  Build & security
# -----------------
alias dlint="docker build --check ."
alias dscout="docker scout cves --only-severity critical,high"

# -----------------
#  Cleanup
# -----------------
alias dprune="docker system prune -f"
alias dprunea="docker system prune -af --volumes"

# -----------------
#  Docker fzf
# -----------------
dexec() {
  local cid
  cid=$(docker ps --format '{{.Names}}' | fzf --height=40% --reverse) || return
  docker exec -it "$cid" sh -c 'if command -v bash >/dev/null; then bash; else sh; fi'
}

dclz() {
  local svc
  svc=$(dc ps --format '{{.Service}}' | fzf --height=40% --reverse) || return
  dc logs -f --tail=100 "$svc"
}

dlz() {
  local cid
  cid=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
    column -t -s $'\t' |
    fzf --height=40% --reverse |
    awk '{print $1}') || return
  docker logs -f --tail=100 "$cid"
}

ddebug() {
  local cid
  if [[ -n "$1" ]]; then cid="$1"; else
    cid=$(docker ps --format '{{.Names}}' | fzf --height=40% --reverse) || return
  fi
  docker debug "$cid"
}
