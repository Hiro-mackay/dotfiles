# -----------------
#  Python (uv)
# -----------------
alias pyrun="uv run"
alias pyadd="uv add"
alias pyinit="uv init"
alias pyin="uv sync"
alias pyshell="uv shell"
alias pyrm="rm -rf .venv"
alias pyfreeze="uv pip freeze > requirements.txt"

# -----------------
#  Rust
# -----------------
alias compete="cargo compete"

# -----------------
#  Kubernetes
# -----------------
alias k="kubectl"

# -----------------
#  ni
# -----------------
export NI_DEFAULT_AGENT="pnpm"
export NI_GLOBAL_AGENT="pnpm"

# -----------------
#  Claude Code
# -----------------
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000
