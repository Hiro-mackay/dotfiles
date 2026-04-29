# =================
#  Container aliases (shared template for docker / podman)
# =================
# This file defines _container_aliases and is sourced before docker.zsh / podman.zsh
# because "_" sorts before "a-z" in the rc.d/*.zsh glob.

_container_aliases() {
  local tool=$1   # docker | podman
  local p=$2      # d | p

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

}

# fzf interactive helpers (shared between docker / podman)
_container_exec() {
  local rt=$1 cid
  cid=$("$rt" ps --format '{{.Names}}' | fzf --height=40% --reverse) || return
  "$rt" exec -it "$cid" sh -c 'command -v bash >/dev/null && exec bash || exec sh'
}

_container_clz() {
  local rt=$1 svc
  svc=$("$rt" compose ps --format '{{.Service}}' | fzf --height=40% --reverse) || return
  "$rt" compose logs -f --tail=100 "$svc"
}

_container_lz() {
  local rt=$1 cid
  cid=$("$rt" ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
    column -t -s $'\t' |
    fzf --height=40% --reverse |
    awk '{print $1}') || return
  "$rt" logs -f --tail=100 "$cid"
}

dexec() { _container_exec docker }
pexec() { _container_exec podman }
dclz()  { _container_clz docker }
pclz()  { _container_clz podman }
dlz()   { _container_lz docker }
plz()   { _container_lz podman }
