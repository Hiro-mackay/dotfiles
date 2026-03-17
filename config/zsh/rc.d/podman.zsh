# =================
#  Podman
# =================

# -----------------
#  Podman Compose: lifecycle
# -----------------
alias pc="podman compose"
alias pcu="pc up"
alias pcud="pcu -d"
alias pcw="pcu --watch"
alias pcd="pc down"
alias pcdv="pc down --volumes"
alias pcr="pc restart"
alias pce="pc exec"
alias pcdry="pcu --dry-run"

# -----------------
#  Podman Compose: logs
# -----------------
alias pcl="pc logs --tail=50"
alias pclf="pc logs -f --tail=50"

# -----------------
#  Podman: status & monitoring
# -----------------
alias pp="podman ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias ppa="podman ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
alias pstats="podman stats --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"

# -----------------
#  Podman: cleanup
# -----------------
alias pprune="podman system prune -f"
alias pprunea="podman system prune -af --volumes"

# -----------------
#  Podman: fzf
# -----------------
pexec() {
  local cid
  cid=$(podman ps --format '{{.Names}}' | fzf --height=40% --reverse) || return
  podman exec -it "$cid" sh -c 'if command -v bash >/dev/null; then bash; else sh; fi'
}

pclz() {
  local svc
  svc=$(podman compose ps --format '{{.Service}}' | fzf --height=40% --reverse) || return
  podman compose logs -f --tail=100 "$svc"
}

plz() {
  local cid
  cid=$(podman ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
    column -t -s $'\t' |
    fzf --height=40% --reverse |
    awk '{print $1}') || return
  podman logs -f --tail=100 "$cid"
}
