#!/usr/bin/env awk -f
#
# Strip per-machine runtime state from Codex config.toml before it enters a
# commit. The working tree copy is left untouched; only the staged blob is
# rewritten by the pre-commit hook that invokes this script.
#
# Removed:
#   - [projects.*]                       (trusted dirs leak local paths + email)
#   - [hooks.state.*]                    (per-machine hook trust hashes)
#   - [tui.model_availability_nux]       (per-machine UX nudge counters)
#   - last_updated / last_revision keys inside [marketplaces.*]
#
# Preserved:
#   - [marketplaces.*] source / source_type (the shared part)
#   - everything else verbatim

function should_skip_section(name) {
    return name ~ /^\[projects\./ \
        || name ~ /^\[hooks\.state\./ \
        || name == "[tui.model_availability_nux]"
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

    if (should_skip_section(header)) {
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
