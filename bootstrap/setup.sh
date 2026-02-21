#!/usr/bin/env zsh

INSTALL_DIR="$HOME/.dotfiles"
BOOTSTRAP_DIR="$INSTALL_DIR/bootstrap"

# 環境変数を最初に読み込む
source "$BOOTSTRAP_DIR/env.sh"

# sudo パスワードを事前に要求（以降の sudo プロンプトを省略）
echo ""
echo "⚠️  Some setup steps require administrator privileges."
sudo -v
# sudo のタイムスタンプを維持（バックグラウンドで定期更新）
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ステップ実行結果トラッキング
typeset -a FAILED_STEPS=()

run_step() {
    local name="$1"
    local script="$2"
    local critical="${3:-false}"

    echo ""
    echo "==============================="
    echo "  Running: $name"
    echo "==============================="

    if "$script"; then
        echo "=> $name: OK"
    else
        echo "=> $name: FAILED"
        FAILED_STEPS+=("$name")
        if [[ "$critical" == "true" ]]; then
            echo "❌ Critical step '$name' failed. Aborting."
            exit 1
        fi
    fi
}

# Critical steps (後続が依存するため失敗時は即時中断)
run_step "setup-dir"  "$BOOTSTRAP_DIR/setup-dir.sh"  true
run_step "setup-link" "$BOOTSTRAP_DIR/setup-link.sh" true
run_step "setup-brew" "$BOOTSTRAP_DIR/setup-brew.sh" true

# Non-critical steps (失敗しても続行)
run_step "setup-lang"   "$BOOTSTRAP_DIR/setup-lang.sh"
run_step "setup-macos"  "$BOOTSTRAP_DIR/setup-macos.sh"
run_step "setup-vscode" "$BOOTSTRAP_DIR/setup-vscode.sh"
run_step "setup-claude" "$BOOTSTRAP_DIR/setup-claude.sh"

# 実行結果サマリ
echo ""
echo "==============================="
echo "  Setup Summary"
echo "==============================="

if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
    echo "✅ All steps completed successfully."
else
    echo "⚠️  The following steps failed:"
    for step in "${FAILED_STEPS[@]}"; do
        echo "  - $step"
    done
    exit 1
fi
