# =================
#  Container aliases (shared template for docker / podman)
# =================
# This file defines _container_aliases and is sourced before docker.zsh / podman.zsh
# because "_" sorts before "a-z" in the rc.d/*.zsh glob.

_container_aliases() {
  local tool=$1   # docker | podman
  local p=$2      # d | p

  # Validate inputs — these are interpolated into eval below
  case "$tool" in
    docker|podman) ;;
    *) echo "_container_aliases: unknown tool '$tool'" >&2; return 1 ;;
  esac
  case "$p" in
    d|p) ;;
    *) echo "_container_aliases: unknown prefix '$p'" >&2; return 1 ;;
  esac

  # Compose: lifecycle
  alias "${p}c"="${tool} compose"
  alias "${p}cu"="${tool} compose up"
  alias "${p}cud"="${tool} compose up -d"
  alias "${p}cw"="${tool} compose up --watch"
  alias "${p}cd"="${tool} compose down"
  alias "${p}cdv"="${tool} compose down --volumes"
  alias "${p}cr"="${tool} compose restart"
  alias "${p}ce"="${tool} compose exec"
  alias "${p}cdry"="${tool} compose up --dry-run"

  # Compose: logs
  alias "${p}cl"="${tool} compose logs --tail=50"
  alias "${p}clf"="${tool} compose logs -f --tail=50"

  # Status & monitoring
  alias "${p}p"="${tool} ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
  alias "${p}pa"="${tool} ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'"
  alias "${p}stats"="${tool} stats --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"

  # Cleanup
  alias "${p}prune"="${tool} system prune -f"
  alias "${p}prunea"="${tool} system prune -af --volumes"

  # fzf interactive functions
  eval "
  ${p}exec() {
    local cid
    cid=\$(${tool} ps --format '{{.Names}}' | fzf --height=40% --reverse) || return
    ${tool} exec -it \"\$cid\" sh -c 'if command -v bash >/dev/null; then bash; else sh; fi'
  }

  ${p}clz() {
    local svc
    svc=\$(${tool} compose ps --format '{{.Service}}' | fzf --height=40% --reverse) || return
    ${tool} compose logs -f --tail=100 \"\$svc\"
  }

  ${p}lz() {
    local cid
    cid=\$(${tool} ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
      column -t -s \$'\t' |
      fzf --height=40% --reverse |
      awk '{print \$1}') || return
    ${tool} logs -f --tail=100 \"\$cid\"
  }
  "
}
