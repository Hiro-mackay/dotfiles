#!/usr/bin/env awk -f
#
# Keep only the shared portions of Codex config.toml when it enters a commit.
# The working tree copy is left untouched; only the staged blob is rewritten by
# the pre-commit hook that invokes this script.
#
# Whitelist model (default-deny): a section is committed ONLY if it matches the
# shared list below. Anything else — including future per-machine sections Codex
# may invent — is dropped automatically, so leaks fail safe.
#
# Committed (shared):
#   - top-level keys (model, approval_policy, ... before the first section)
#   - [agents] [analytics] [auto_review] [feedback] [history] [tools] [tui]
#   - [sandbox_workspace_write]
#   - [shell_environment_policy] and [shell_environment_policy.set]
#   - [[hooks.PermissionRequest|PostToolUse|PreToolUse]] (+ their .hooks)
#   - [marketplaces.*]  (source / source_type only)
#   - [plugins.*]
#
# Dropped (per-machine / runtime state — not on the whitelist):
#   - [projects.*]                  (trusted dirs leak local paths + email)
#   - [hooks.state.*]               (per-machine hook trust hashes)
#   - [tui.model_availability_nux]  (per-machine UX nudge counters)
#   - [mcp_servers.*]               (machine-local MCP server paths)
#   - last_updated / last_revision keys inside [marketplaces.*]
#   - any section not explicitly whitelisted

function is_shared_section(name) {
    return name == "[agents]" \
        || name == "[analytics]" \
        || name == "[auto_review]" \
        || name == "[feedback]" \
        || name == "[history]" \
        || name == "[tools]" \
        || name == "[tui]" \
        || name == "[sandbox_workspace_write]" \
        || name == "[shell_environment_policy]" \
        || name == "[shell_environment_policy.set]" \
        || name ~ /^\[\[hooks\.(PermissionRequest|PostToolUse|PreToolUse)(\.hooks)?\]\]$/ \
        || name ~ /^\[marketplaces\./ \
        || name ~ /^\[plugins\./
}

function is_marketplaces_section(name) {
    return name ~ /^\[marketplaces\./
}

BEGIN {
    skip = 0
    in_marketplaces = 0
    pending_blank = 0
}

/^\[/ {
    header = $0
    sub(/[[:space:]]+$/, "", header)

    if (!is_shared_section(header)) {
        skip = 1
        in_marketplaces = 0
        pending_blank = 1
        next
    }

    skip = 0
    in_marketplaces = is_marketplaces_section(header)

    if (pending_blank) {
        pending_blank = 0
    }
    print
    next
}

{
    if (skip) next

    if (in_marketplaces && ($0 ~ /^[[:space:]]*last_updated[[:space:]]*=/ \
                         || $0 ~ /^[[:space:]]*last_revision[[:space:]]*=/)) {
        next
    }

    # Collapse the blank line that originally separated a now-removed section
    # from the next one — keeps the output tidy without touching real spacing.
    if (pending_blank && $0 ~ /^[[:space:]]*$/) {
        pending_blank = 0
        next
    }
    pending_blank = 0
    print
}
