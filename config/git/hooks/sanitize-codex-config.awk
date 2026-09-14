#!/usr/bin/env awk -f
# Keep portable Codex preferences while dropping machine paths and runtime state.
# Plugin and marketplace names are intentionally open-ended so enabling a new
# plugin survives a commit without requiring a sanitizer change.

function shared_top_level(line) {
    return line ~ /^[[:space:]]*(approval_policy|approvals_reviewer|model|model_reasoning_effort|sandbox_mode|web_search)[[:space:]]*=/
}

function shared_section(header) {
    return header ~ /^\[plugins\./ \
        || header ~ /^\[marketplaces\./ \
        || header == "[tui]"
}

BEGIN {
    seen_section = 0
    keep_section = 0
    wrote_output = 0
}

/^\[/ {
    seen_section = 1
    header = $0
    sub(/[[:space:]]+$/, "", header)
    keep_section = shared_section(header)
    if (keep_section) {
        if (wrote_output) print ""
        print header
        wrote_output = 1
    }
    next
}

!seen_section {
    if (shared_top_level($0)) {
        print
        wrote_output = 1
    }
    next
}

keep_section && NF {
    if ($0 !~ /^[[:space:]]*(last_updated|last_revision)[[:space:]]*=/) print
}
