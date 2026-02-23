# -----------------
#  cheat - quick reference in terminal
#  Usage: cheat [topic]
#  Topics: git, docker, fzf, nav, util, dev
# -----------------
cheat() {
  case "${1:-}" in
    git)
      cat <<'SHEET'
  Git Cheatsheet
  ──────────────────────────────────────────
  STAGE & COMMIT
    ga <file>       add file         gaa    add all
    gc              commit           gcm "msg"  commit -m
    gcamend         amend (no edit)  gundo  soft reset HEAD^

  DIFF
    gd    unstaged diff    gds   staged diff    gdw   word diff

  STASH
    gst   stash    gstp  pop    gstl  list    gsts  show -p

  LOG
    gl    graph (all)      gll   detailed graph
    glz   fzf interactive  today my commits today
    glme  my commits       glt   since midnight
    gln 5 last 5 commits   gls   log + file stats
    glg "text"  search messages   glS "text"  search code

  BRANCH
    gco <branch>   switch           gcb <branch>  create + track
    gcom           switch to main   gfb           fzf branch switch
    gb             list             gbm <name>    rename
    gbclean        delete gone branches

  DISCARD (with confirmation)
    gcd    restore all + clean      greset  hard reset HEAD

  WORKTREE
    gwa <branch>   create worktree (copies .env)
    gwaf           create from fzf branch selection
    gws            switch worktrees (fzf)
    gwr [branch]   remove worktree

  CREATE
    gcreate <name>           create repo (public, ghq path)
    gcreate --private <name> create private repo

  OTHER
    push / pull    push / pull      rebase  fetch + rebase on main
    ghopen         open repo on GitHub
SHEET
      ;;
    docker|dc)
      cat <<'SHEET'
  Docker Cheatsheet
  ──────────────────────────────────────────
  COMPOSE LIFECYCLE
    dc     docker compose   dcu    up        dcud   up -d
    dcw    up --watch       dcd    down      dcdv   down + volumes
    dcr    restart          dce    exec      dcdry  dry run

  LOGS
    dcl    logs (tail 50)   dclf   logs follow
    dclz   fzf pick service -> follow logs

  STATUS
    dp     running containers (name, status, ports)
    dpa    all containers (name, status, image)
    dstats CPU, memory, network per container

  INTERACTIVE (fzf)
    dexec  pick container -> shell into it
    dlz    pick container -> follow logs
    ddebug debug distroless/scratch container

  CLEANUP
    dprune   prune stopped containers + images
    dprunea  prune everything (including volumes)

  BUILD
    dlint    lint Dockerfile       dscout   scan CVEs
SHEET
      ;;
    fzf)
      cat <<'SHEET'
  fzf Usage
  ──────────────────────────────────────────
  fzf-POWERED COMMANDS
    g         jump to repo (ghq)
    gfb       switch git branch (with log preview)
    glz       interactive git log (with diff preview)
    gwaf      create worktree from branch
    gws       switch worktree
    dexec     exec into container
    dclz      compose service logs
    dlz       any container logs

  INSIDE fzf
    Ctrl+D/U  scroll preview down / up
    Enter     select
    Esc       cancel
    Tab       multi-select (when supported)

  QUERY SYNTAX
    foo         fuzzy match ("btn" matches "Button.tsx")
    foo bar     multiple fragments, AND ("btn comp" -> components/Button)
    'foo        exact match ("'button" matches literal "button")
    !foo        negation ("!test" excludes "test")
    ^foo        prefix ("^src" -> starts with "src")
    foo$        suffix (".tsx$" -> ends with ".tsx")

  NON-WARP TERMINALS ONLY (Warp has its own keybindings)
    Ctrl+R    search history
    Ctrl+T    find file -> insert path
    Alt+C     cd into directory
SHEET
      ;;
    nav|cd|z)
      cat <<'SHEET'
  Navigation Cheatsheet
  ──────────────────────────────────────────
  FIXED ALIASES
    repo       ~/Repository/github.com
    mackay     ~/Repository/github.com/Hiro-mackay
    ac         ~/Repository/github.com/acompany-develop
    dl / dt / doc   Downloads / Desktop / Documents
    dotfiles   ~/.dotfiles       dotconf  ~/.config
    drive      Google Drive      ob       ObsidianVault

  SMART NAVIGATION
    g          fzf select from ghq repos
    z <name>   zoxide jump (learns from cd usage)
    zi         zoxide interactive (fzf)

  ZOXIDE TIPS
    z matches directory NAME components, not substrings:
      z github    -> ~/Repository/github.com
      z dotfiles  -> ~/.dotfiles
      z myproj    -> wherever myproj/ is

    Build zoxide memory by using cd normally.
    The more you visit, the smarter it gets.

  DIRECTORY STACK
    cd -       go back to previous directory
    dirs -v    show directory stack
    pushd/popd manual stack control
SHEET
      ;;
    util|tools)
      cat <<'SHEET'
  Utilities Cheatsheet
  ──────────────────────────────────────────
  FILESYSTEM
    mkcd <dir>       mkdir + cd in one step
    bigfiles [dir]   top 20 largest files
    op               open Finder here
    pwdcp            copy current path to clipboard

  NETWORK
    killport 3000    kill process on port
    ports            list all listening TCP ports

  CLIPBOARD
    cpb              pipe to clipboard: echo foo | cpb
    jc               prettify JSON in clipboard

  HTTP CLIENT (cget)
    cget <url>             status + timing summary
    cget -b <url>          response body (auto-formats JSON/HTML)
    cget -I <url>          headers only
    cget -i <url>          headers + body

  RANDOM STRING (rndl)
    rndl                   32-char alphanumeric
    rndl 64                64-char
    rndl -s                32-char with symbols
    rndl -s 16             16-char with symbols

  OTHER
    howlong          timestamp of last command
    c / e            clear / exit
SHEET
      ;;
    dev)
      cat <<'SHEET'
  Dev Cheatsheet
  ──────────────────────────────────────────
  PYTHON (uv)
    pyinit         create new project
    pyadd <pkg>    add dependency
    pyin           install/sync deps
    pyrun <cmd>    run command in venv
    pyshell        activate venv shell
    pyrm           delete .venv
    pyfreeze       export requirements.txt

  RUST
    compete        cargo compete (competitive programming)

  KUBERNETES
    k              kubectl

  EDITORS
    co             open Cursor here
    em             emacs
    note           open Obsidian vault in Cursor

  CLAUDE CODE
    cc             claude (skip permissions)
    ccdev          claude with dev context
    ccreview       claude with review context
    ccsearch       claude with research context
    ccconfig       cd to claude config dir

  TUI TOOLS
    lg             lazygit   (visual git)
    lzd            lazydocker (visual docker)

  DIRENV
    echo 'export KEY=val' > .envrc
    direnv allow
    # KEY is set when you cd in, unset when you cd out
SHEET
      ;;
    *)
      cat <<'SHEET'
  Quick Reference                     cheat <topic> for details
  ──────────────────────────────────────────────────────────────

  TOPICS
    cheat git      stage, diff, stash, log, branch, worktree
    cheat docker   compose, logs, status, exec, cleanup
    cheat fzf      keybindings, query syntax, fzf commands
    cheat nav      directory aliases, zoxide, ghq, dir stack
    cheat util     killport, ports, cget, rndl, clipboard
    cheat dev      python, rust, k8s, claude, lazygit, direnv

  GIT
    gs  status    gd  diff    gds  staged    ga / gaa  add
    gc  commit    gcm "msg"   push / pull    gfb  switch (fzf)
    gl  log       glz  log (fzf)             today  my commits

  DOCKER
    dp  ps        dcu / dcd   up / down      dcl / dclf  logs
    dexec  exec (fzf)         dlz  logs (fzf)

  NAV
    g   repo (fzf)    z <name>  zoxide    repo / dl / dt  aliases

  UTIL
    killport <port>   ports   rndl [len]   jc   cget <url>
SHEET
      ;;
  esac
}
