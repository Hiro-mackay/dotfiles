# -----------------
#  Podman compatibility
# -----------------
alias docker="podman"
alias docker-compose="podman-compose"

# -----------------
#  Podman Compose: lifecycle
# -----------------
alias dc="podman compose"
alias dcu="dc up"
alias dcud="dcu -d"
alias dcw="dcu --watch"
alias dcd="dc down"
alias dcdv="dc down --volumes"
alias dcr="dc restart"
alias dce="dc exec"
alias dcdry="dcu --dry-run"

# -----------------
#  Podman Compose: logs
# -----------------
alias dcl="dc logs --tail=50"
alias dclf="dc logs -f --tail=50"

# -----------------
#  Container: status & monitoring
# -----------------
alias dp="podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dpa="podman ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
alias dstats="podman stats --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"

# -----------------
#  Cleanup
# -----------------
alias dprune="podman system prune -f"
alias dprunea="podman system prune -af --volumes"

# -----------------
#  Podman fzf
# -----------------
dexec() {
  local cid
  cid=$(podman ps --format '{{.Names}}' | fzf --height=40% --reverse) || return
  podman exec -it "$cid" sh -c 'if command -v bash >/dev/null; then bash; else sh; fi'
}

dclz() {
  local svc
  svc=$(dc ps --format '{{.Service}}' | fzf --height=40% --reverse) || return
  dc logs -f --tail=100 "$svc"
}

dlz() {
  local cid
  cid=$(podman ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
    column -t -s $'\t' |
    fzf --height=40% --reverse |
    awk '{print $1}') || return
  podman logs -f --tail=100 "$cid"
}
