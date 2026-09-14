#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/codex-config.XXXXXX")"
trap 'rm -r -- "$fixture"' EXIT

cat > "$fixture/input.toml" <<'TOML'
approval_policy = "on-request"
model = "gpt-6-astra"
notify = [ "/private/app" ]

[plugins."browser@openai-bundled"]
enabled = true

[plugins."documents@openai-primary-runtime"]
enabled = true

[marketplaces.ponytail]
last_updated = "runtime"
source_type = "git"
source = "https://github.com/DietrichGebert/ponytail.git"

[tui]
notifications = [ "agent-turn-complete" ]

[projects."/private/repo"]
trust_level = "trusted"
TOML

cat > "$fixture/expected.toml" <<'TOML'
approval_policy = "on-request"
model = "gpt-6-astra"

[plugins."browser@openai-bundled"]
enabled = true

[plugins."documents@openai-primary-runtime"]
enabled = true

[marketplaces.ponytail]
source_type = "git"
source = "https://github.com/DietrichGebert/ponytail.git"

[tui]
notifications = [ "agent-turn-complete" ]
TOML

awk -f "$root/config/git/hooks/sanitize-codex-config.awk" "$fixture/input.toml" > "$fixture/actual.toml"
diff -u "$fixture/expected.toml" "$fixture/actual.toml"
echo "PASS: portable plugins are retained and machine state is removed"
