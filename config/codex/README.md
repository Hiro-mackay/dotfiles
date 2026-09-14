# Codex は共有ルールと標準機能を使う

このディレクトリは Codex CLI とアプリの設定を管理する。
運用ルールの編集元は [共有 AGENTS.md](../agents/AGENTS.md) だ。
この README は自動読み込みされる指示ではない。

## モデルの固定を必要最小限にする

通常の作業には `gpt-6-astra` と推論量 `medium` を使う。
`review_model` は指定せず、レビューも選択中のモデルを使う。
重い作業だけ推論量を引き上げる。
モデルと推論量の用途は [OpenAI 公式ドキュメント](https://learn.chatgpt.com/docs/models) に従う。

Claude Code から Codex を呼ぶ `codex@openai-codex` は、Codex 内では無効にする。
この用途のスキルやフックを Codex 自身へ追加する必要がないためだ。
画像表示やシェル実行など、有効な標準機能は重複して設定しない。

Web 検索は `cached` を使う。
最新のページを直接取得したい CLI セッションでは `codex --search` を使う。
モードの違いは [設定リファレンス](https://learn.chatgpt.com/docs/config-file/config-reference) を参照する。

## 共有ファイルから各ツールの配置を生成する

| ファイル | 役割 |
|---|---|
| `config.toml` | モデル、承認、サンドボックス、フック、プラグイン |
| `AGENTS.md` | 共有ルールから生成するコピー |
| `skills/` | 共有スキルへのリンクと Codex 専用スキル |
| `agents/design-reviewer.toml` | 明示依頼時に使う UI レビュー役 |
| `script/` | コマンド検査と編集後の検査 |

[setup-agents.sh](../../bootstrap/setup-agents.sh) が共有ルールをコピーする。
共有スキルの実体は `config/agents/skills/` に置く。
同じスクリプトが Claude と Codex の両方へリンクを作る。
[setup-codex.sh](../../bootstrap/setup-codex.sh) は CLI、依存コマンド、MCP 登録を確認する。

スキルは `$critique` のように明示して呼び出せる。
自動選択の条件は各スキルの `description` に書く。
`paths:` による拡張子ごとの自動適用を前提にしない。
作成方法は [公式スキルガイド](https://learn.chatgpt.com/docs/build-skills) を参照する。

## フックは補助的な検査に使う

| フック | 動作 |
|---|---|
| `pre-tool-policy.sh` | 一部の破壊的コマンドを文字列で検出し、拒否する |
| `permission-request.sh` | コマンド名に基づいて許可や拒否を返す |
| `post-edit-check.sh` | デバッグ出力を検出し、Go ファイルの編集後に `go vet` を実行する |

コマンド名の照合は、引数まで含めた安全性の判定ではない。
権限の制限はサンドボックスと承認設定で行う。
`Bash` は `exec_command` にも一致する。
`apply_patch` は `Edit` と `Write` にも一致する。
入力形式は [公式フックガイド](https://learn.chatgpt.com/docs/hooks) を参照する。

TUI 通知は `[tui]` の標準機能を使う。
`script/notify.sh` は現在の設定からは呼び出していない。
アプリが追加する `notify` は端末固有の設定として扱う。

## 更新時は実際の CLI で読み込みを確認する

```sh
codex --version
codex features list
codex --strict-config app-server --listen stdio:// </dev/null
codex doctor --summary
```

2026-09-15 に CLI `0.154.0` で厳密な設定読み込みを確認した。
`tools.view_image` はこの版で未知の項目として拒否されたため削除した。
`codex features list` では `view_image` が標準で有効だった。
アプリ同梱 CLI は `0.153.4` であり、CLI とアプリの版は別々に確認する。
設定読み込みの成功だけでは、モデル応答やフックの発火までは確認できない。

## 端末固有の状態をコミットへ含めない

認証、会話、履歴、SQLite、キャッシュ、生成済みスキルは Git 管理から除く。
[設定の抽出処理](../git/hooks/sanitize-codex-config.awk) はコミット対象だけを書き換える。
作業ツリー内の信頼設定やアプリ用 MCP 設定は残す。
新しい設定セクションを追加する場合は、抽出処理が保持するかも確認する。
