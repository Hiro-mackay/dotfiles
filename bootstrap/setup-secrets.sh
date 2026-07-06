#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

# Register the machine-local private identity (from ~/.gitconfig.local) as
# git-secrets prohibited patterns, so it can never be committed to this public
# repo. Must run AFTER setup-brew (which installs git-secrets) — hence a step of
# its own rather than living in setup-link. No-op when the repo is not a git
# checkout, git-secrets is absent, or ~/.gitconfig.local does not exist.
DOTFILES_DIR="${HOME}/.dotfiles"
GITCONFIG_LOCAL="${HOME}/.gitconfig.local"

if [[ ! -d "${DOTFILES_DIR}/.git" ]]; then
    _log_ok "Not a git checkout; skipping git-secrets registration."
    exit 0
fi
if ! command -v git-secrets >/dev/null 2>&1; then
    _log_warn "git-secrets not installed; skipping git-secrets registration."
    exit 0
fi
if [[ ! -f "${GITCONFIG_LOCAL}" ]]; then
    _log_ok "No ~/.gitconfig.local; skipping git-secrets registration."
    exit 0
fi

_log_run "Registering git-secrets patterns from ~/.gitconfig.local"
existing="$(git -C "${DOTFILES_DIR}" config --get-all secrets.patterns 2>/dev/null || true)"
for key in user.name user.email; do
    value="$(git config -f "${GITCONFIG_LOCAL}" "${key}" 2>/dev/null || true)"
    [[ -z "${value}" ]] && continue
    if ! print -r -- "${existing}" | grep -qxF -- "${value}"; then
        git -C "${DOTFILES_DIR}" secrets --add "${value}"
    fi
done
_log_ok "git-secrets patterns registered."
