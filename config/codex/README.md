# Codex グローバル設定

dotfiles で管理する Codex CLI のグローバル設定。

> この `README.md` は Codex のコンテキストに読み込まれない。自動読み込み
> される運用ルールは `AGENTS.md` に置く。

## 運用原則

- Codex が active agent のときは、依頼された作業を end-to-end で所有する
- 実装、検証、レビュー、ハーネス構築、安全確認を分断せず、納品品質の一部として扱う
- agent や tool は、タスク適性、文脈、検証ニーズで選ぶ
- cross-provider review は品質を上げるための独立判断として使う

## ディレクトリ構成

```
codex/
  AGENTS.md              # グローバル指示（全プロジェクトで自動読み込み）
  config.toml            # モデル、sandbox、hooks、plugins、MCP、trusted projects
  agents/                # Codex サブエージェント定義
  script/                # hook スクリプト、通知、skill bridge
  skills/                # 共有 agent skills への symlink と Codex system skills
```

## レイヤー構成

| レイヤー | 役割 |
|---------|------|
| `AGENTS.md` | Codex の運用原則、workflow、review policy、agent coordination |
| `config.toml` | モデル、reasoning、sandbox、approval、hooks、plugins、MCP |
| `agents/` | read-only reviewer agents |
| `script/` | command policy、permission short-circuit、post-edit checks、通知 |
| `skills/` | Claude/Codex で共有する設計原則・言語別ルール |

## エージェント

| エージェント | 役割 |
|------------|------|
| `code-reviewer` | 汎用コードレビュー。言語を検出し、共有 skill を適用する |
| `security-reviewer` | 認証、認可、入力処理、secrets、暗号、依存関係の監査 |

## Hooks

| Hook | トリガー | 動作 |
|------|---------|------|
| `pre-tool-policy.sh` | Bash 実行前 | `sudo`, `git reset`, `git clean`, `rm -rf` などを拒否 |
| `permission-request.sh` | Bash approval | 一般的な dev command を許可し、危険 command を拒否 |
| `post-edit-check.sh` | Edit/Write/apply_patch 後 | `console.log`, `fmt.Print*`, `print()` を検出し、Go では `go vet` を実行 |
| `notify.sh` | TUI 通知 | approval 待ち、入力待ち、完了をデスクトップ通知 |

## Skills

`skills/` は `script/bootstrap.sh` で生成される。現時点では共有 agent skills の
実体を `~/.config/claude/skills` に置き、Codex 側から symlink する。

この配置に関係なく、skills は複数 agent が同じ品質基準を使うための共有知識
ベースとして扱う。

Codex では `$skill-name` で skill を明示呼び出しできる。これは Claude の
`/command` に相当する定常タスク呼び出しとして使える。

例:

```text
$review-local
$critique
$architecture-decisions
$security-principles
```

`paths:` を持つ language skill は対象ファイルに応じて自動適用される。
`user-invocable: false` の skill は通常は明示呼び出しせず、ファイル種別や
関連タスクに応じて適用される。

## Runtime state

`auth.json`, session, history, sqlite, cache, generated `skills/` は git に入れない。
追跡するのは宣言的設定だけにする。
