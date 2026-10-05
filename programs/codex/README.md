# Codex は短い常設設定と必要時の拡張で動かす

この構成は GPT-6 Astra の判断力を前提にする。
常時読む指示と利用可能な拡張を減らし、必要な文脈だけを作業中に取得する。

## 既定値は能力と消費の均衡を取る

| 項目 | 設定 |
|---|---|
| モデル | `gpt-6-astra` |
| 推論量 | `medium` |
| 速度 | Standard |
| 承認 | `on-request` と `auto_review` |
| sandbox | `workspace-write` |
| Web検索 | `cached` |

Astra は明示的な制約と自動レビューに従う能力が高い。
そのため、dotfiles 独自のコマンド名による許可や検査フックを重ねない。
Fast は急ぎの作業で明示的に有効にする。
完了と承認要求は、端末が非アクティブなときに通知する。
状態行にはモデル、文脈使用量、利用枠を表示する。

## 常設指示は作業の境界だけを示す

`programs/agents/AGENTS.md` が共通指示の編集元である。
home-manager が `~/.codex/AGENTS.md` として配り、Claude には `CLAUDE.md` の前半として配る。

常設指示には、会話、権限、Git操作、完了条件だけを置く。
調査手順、言語別の一般知識、細かな設計規則は置かない。
プロジェクト固有の構成と検証コマンドは、各リポジトリの `AGENTS.md` に置く。

## skill は固有の成果物を持つ3個に絞る

| skill | 用途 |
|---|---|
| `japanese-writing` | 日本語の文書を構成して推敲する |
| `plan-template` | 複雑な作業の実装計画を作る |
| `critique` | 明示依頼されたUI評価を行う |

一般的なGo、Python、TypeScript、SQL、設計、テストの知識はAstra自身に任せる。
同じ失敗が繰り返された場合だけ、狭いskillかプロジェクト指示として追加する。

## プラグインは実際に使う2個だけ有効にする

| プラグイン | 用途 |
|---|---|
| `browser` | ローカルWeb画面の操作と確認 |
| `ponytail` | 不要な実装と依存を抑える |

文書、PDF、表計算、スライド、ログイン済みChromeの操作は常用しない。
必要になった時点で設定から有効にする。

## 構造探索と実装確認で道具を分ける

`codebase-memory-mcp` は構文木から永続的な知識グラフを作る。
広い呼び出し経路、依存関係、ハブ、影響範囲の探索に使う。
Codex標準の検索とファイル読み取りは、候補箇所の実装と現在の差分を確認するために使う。

知識グラフの結果だけで変更を確定しない。
論文の評価では、ファイル探索より回答品質が低い一方、トークンとツール呼び出しを減らしている。
そのため、構造探索を先に行い、対象を絞ってから正確なソースを読む。

`codebase-memory-mcp` の登録を含む共有設定は `system-config.toml` に置く。
Nix がこれを `/etc/codex/config.toml` に配り、Codex は最も優先度の低い層として読む。
`~/.codex/config.toml` は Codex が trust や端末固有のパスを書き込むので、追跡しない。
同じキーが両方にあるときは `~/.codex/config.toml` が優先される。

## 変更後は実際の読み込みを確認する

```sh
nix run ~/.dotfiles#switch
codex mcp get codebase-memory-mcp
codex --strict-config app-server --listen stdio:// </dev/null
```

設定方針は [Astra向けskillsとpromptの見直し](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra) と [Codexのベストプラクティス](https://learn.chatgpt.com/guides/best-practices) に基づく。
