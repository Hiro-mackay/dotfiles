# Claude Code グローバル設定

dotfiles + GNU Stow で管理する Claude Code のグローバル設定。

> この `README.md` は Claude Code のコンテキストに読み込まれない。自動読み込みされるのは `CLAUDE.md` のみ。

## ディレクトリ構成

```
claude/
  CLAUDE.md              # グローバル指示（全プロジェクトで自動読み込み）
  settings.json          # 権限、hooks、プラグイン、言語設定
  agents/                # コードレビュー用エージェント（サブエージェントとして起動）
  rules/                 # 言語別ルール（ファイルパターンで自動読み込み）
  skills/                # 設計原則スキル（トリガーマッチで自動読み込み）
  script/                # hook スクリプト、通知、ステータスライン
```

## レイヤー構成と役割分担

| レイヤー | 読み込み方式 | 役割 |
|---------|------------|------|
| `CLAUDE.md` | 常時 | ワークフロー、subagent 委譲方針、memory 運用、コード品質の普遍ルール |
| `settings.json` | 常時 | 権限制御、hook による機械的強制、プラグイン |
| `rules/` | ファイルパターン一致時 | 言語固有の実装ガイドライン |
| `skills/` | トリガーマッチ時 | ドメイン知識・設計原則 |
| `agents/` | サブエージェント起動時 | レビュープロセスの定義 |

## エージェント

サブエージェントとして起動されるレビュー専門エージェント。ドメイン知識は rules/skills に委譲し、プロセス・出力形式のみ定義。

| エージェント | モデル | 役割 |
|------------|--------|------|
| `code-reviewer` | sonnet | 汎用コードレビュー。言語を検出し対応 rule を適用。静的解析ツールを実行 |
| `security-reviewer` | opus | セキュリティ監査。security-principles skill を適用し CWE 参照付きで報告 |

## ルール（言語別）

ファイルパターンに一致すると自動でコンテキストに読み込まれる。各言語の命名規則、型安全性、エラーハンドリング、パフォーマンスパターンなど、実装レベルの具体的な指針。

| ルール | トリガー | 内容 |
|-------|---------|------|
| `go-principles` | `**/*.go` | 命名（MixedCaps、-er インターフェース）、エラーハンドリング（errors.Is/As、%w）、並行処理（context 伝播、goroutine ライフサイクル）、メモリ安全性 |
| `typescript-principles` | `**/*.{ts,tsx}` | 型安全（no any、型ガード、discriminated union）、型設計（有効な状態のみ表現）、ジェネリクス、async パターン、エスケープハッチ |
| `react-principles` | `**/*.{tsx,jsx}` | Server Components、ウォーターフォール排除、バンドル最適化、データフェッチ層設計、再レンダリング最適化、コンポーネント設計 |
| `python-principles` | `**/*.py` | 型ヒント（3.10+ 構文）、エラーハンドリング（raise...from）、モダン Python（dataclasses、match、Protocol）、async、セキュリティ |
| `sql-implementation` | `**/*.sql`, `**/migrations/**` | 命名規則、N+1 防止、インデックス戦略、トランザクション設計、バルク操作、マイグレーション安全性 |
| `dockerfile` | `**/Dockerfile*`, `**/docker-compose*` | マルチステージビルド、レイヤーキャッシュ最適化、セキュリティ（非 root、secrets 除外）、ヘルスチェック |

## スキル

タスクの内容に応じて自動的にコンテキストに読み込まれる設計原則・ドメイン知識。

### アーキテクチャ・設計

| スキル | 内容 |
|-------|------|
| `architecture-decisions` | トレードオフ分析、Type 1/2 意思決定、ADR フォーマット、build-vs-buy、複雑性管理、YAGNI |
| `system-design` | CAP 定理、一貫性モデル、レプリケーション、パーティショニング、障害ドメイン、スケーリング戦略。参照: `reference/data-patterns.md`（CDC、イベントソーシング） |
| `module-design` | 凝集度・結合度、依存方向（安定方向へ）、境界検出、インターフェース設計（Postel の法則）、循環依存の解消 |
| `ddd-principles` | イベント→コマンド→集約の発見プロセス、境界づけられたコンテキスト、集約サイジング、ユビキタス言語 |
| `db-schema-design` | UUID vs auto-increment、正規化判断、リレーションシップパターン（1:N, M:N, ポリモーフィック）、ソフトデリート、キャパシティプランニング |

### コード品質

| スキル | 内容 |
|-------|------|
| `readable-code` | 関数 30行以下、ネスト 3段以下、引数 3個以下、コメントは WHY のみ、Rule of 3 |
| `naming-conventions` | 命名は設計シグナル。And = 2つの責務、temp = 無意味。品詞ルール（名詞/動詞/形容詞/前置詞）、メタファー認識 |
| `test-strategy` | TDD ワークフロー（t-wada 式: テストリスト→Red→Green→Refactor）、実装戦略（Fake It、三角測量）、テストダブル、スコープ戦略、AI 時代のガードレール |
| `error-handling` | リトライ（指数バックオフ + ジッター）、タイムアウト設計、サーキットブレーカー、フォールバック、バルクヘッド、冪等性 |
| `git-workflow` | ブランチ命名、PR サイズ（300行未満）、レビュー SLA（1日）、マージ戦略、stacked PR |

### セキュリティ・可観測性

| スキル | 内容 |
|-------|------|
| `security-principles` | 認証アーキテクチャ（Session/JWT/OAuth 2.0+PKCE）、認可（default deny、IDOR 防止）、入力バリデーション、シークレット管理、暗号化、HTTP セキュリティヘッダ |
| `observability` | 構造化ログ（JSON、マスキング）、分散トレーシング（W3C Trace Context）、メトリクス（RED/USE メソッド）、アラート設計、ヘルスチェック |
| `api-design` | リソース設計、HTTP メソッド・ステータスコード、エラーレスポンス、ページネーション（cursor vs offset）、バージョニング、冪等性キー、キャッシュ。参照: `reference/advanced-patterns.md` |

### UI・デザイン

| スキル | 内容 |
|-------|------|
| `visual-design` | タイポグラフィ（モジュラースケール、65ch）、色彩（OKLCH、60-30-10 ルール）、レイアウト（4pt グリッド、ゲシュタルト）、モーション、AI アンチパターン検出 |
| `ui-quality` | アクセシビリティ（セマンティック HTML、コントラスト 4.5:1、キーボード操作）、レスポンシブ、インタラクティブ状態（8状態）、エラー UX ライティング |
| `web-performance` | Core Web Vitals（LCP/INP/CLS）、画像最適化、フォント読み込み、バンドル最適化（200KB 以下）、リソースローディング |
| `critique` | Nielsen ヒューリスティクス評価、認知負荷分析、ペルソナテスト、AI スロップ検出。`/critique` で手動起動。参照: `reference/heuristics-scoring.md`, `reference/personas.md`, `reference/cognitive-load.md` |

### ユーティリティ

| スキル | 内容 |
|-------|------|
| `review-local` | `/review-local` で手動起動。git diff を取得し code-reviewer エージェントで構造化レビュー |

## Hooks

settings.json で定義。ツール実行の前後に自動で発火するシェルスクリプト。

| Hook | トリガー | 動作 |
|------|---------|------|
| `detect-console-log.sh` | PostToolUse (Edit/Write) | `console.log` / `fmt.Println` / `print()` を検出して警告 |
| `go-vet.sh` | PostToolUse (Edit/Write) | Go ファイル変更時に `go vet` を実行 |
| `filter-test-output.sh` | PreToolUse (Bash) | 冗長なテスト出力をフィルタリング |
| `notify.sh` | Stop / Notification | タスク完了時のデスクトップ通知 |

## プラグイン

| プラグイン | 機能 |
|-----------|------|
| `hookify` | Hook の管理・作成 |
| `commit-commands` | `/commit`, `/commit-push-pr` コマンド |
| `context7` | ライブラリドキュメントの取得 |
| `security-guidance` | ファイル編集時のセキュリティチェック |
| `codex@openai-codex` | OpenAI Codex CLI 連携。`/codex:review`, `/codex:rescue` などのクロスプロバイダレビュー |

> `gopls-lsp`, `typescript-lsp` はプロジェクト単位で有効化。グローバルでは無効。

## シェルエイリアス

`zsh/rc.d/aliases.zsh` で定義:

| エイリアス | コマンド |
|-----------|---------|
| `ccode` | `claude --dangerously-skip-permissions` |
| `ccconf` | Claude 設定ディレクトリへ移動 |
