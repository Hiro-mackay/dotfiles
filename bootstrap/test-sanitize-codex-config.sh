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

repo="$fixture/repo"
mkdir -p "$repo/config/codex" "$repo/config/git/hooks"
cp "$root/config/git/hooks/sanitize-codex-config.awk" "$repo/config/git/hooks/"
cp "$fixture/input.toml" "$repo/config/codex/config.toml"
printf '%s\n' 'config/codex/config.toml filter=codex-config' > "$repo/.gitattributes"

git -C "$repo" init -q
git -C "$repo" config filter.codex-config.clean 'awk -f config/git/hooks/sanitize-codex-config.awk'
git -C "$repo" config filter.codex-config.smudge cat
git -C "$repo" config filter.codex-config.required true
git -C "$repo" add .
diff -u "$fixture/expected.toml" <(git -C "$repo" show :config/codex/config.toml)
git -C "$repo" -c user.name=Test -c user.email=test@example.com commit -qm initial
[[ -z "$(git -C "$repo" status --porcelain)" ]]

clone="$fixture/clone"
git clone -q "$repo" "$clone"
diff -u "$fixture/expected.toml" "$clone/config/codex/config.toml"

sed -i.bak 's/model = "gpt-6-astra"/model = "gpt-6-astra-updated"/' "$repo/config/codex/config.toml"
rm "$repo/config/codex/config.toml.bak"
[[ "$(git -C "$repo" status --porcelain)" == " M config/codex/config.toml" ]]
git -C "$repo" add config/codex/config.toml
git -C "$repo" show :config/codex/config.toml | grep -q '^model = "gpt-6-astra-updated"$'
! git -C "$repo" show :config/codex/config.toml | grep -Eq '/private/repo|^\[projects\.'

echo "PASS: portable settings are tracked while machine state stays local"
