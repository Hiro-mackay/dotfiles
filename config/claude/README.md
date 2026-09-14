# Claude Code と Codex は共通ルールで運用する

Claude Code と Codex は、待ち時間と手戻りを減らす構成に揃える。
作業を受けた主担当が、実装から検証まで責任を持つ。
この README は運用資料で、自動読み込みする指示は `CLAUDE.md` に置く。

## 共通の指示とスキルは一箇所で編集する

| 編集元 | 役割 |
| --- | --- |
| `../agents/AGENTS.md` | 日本語、作業手順、Git 操作、引き継ぎの共通ルール |
| `../agents/skills/` | 両方で使う文書、計画、UI 評価の手順 |
| `CLAUDE.md` | 共通ルールの読み込みと Claude 固有の補足 |
| `settings.json` | 権限、推論量、通知、プラグイン |
| `agents/design-reviewer.md` | 明示依頼された UI 評価の担当 |

Claude は共通ルールを `@import` で読む。
Codex は導入スクリプトが作る実ファイルのコピーを読む。
共有スキルは両方の `skills/` にディレクトリリンクとして配置する。
共有元を変更したら、リポジトリのルートで次を実行する。

```sh
bash bootstrap/setup-agents.sh
```

## 主担当を一人にして、独立した作業だけ分ける

独立して進めると速くなる調査や実装だけを子エージェントへ渡す。
委任の判断と引き継ぎ項目は共通ルールに従う。
検証と統合は主担当が行い、同じ調査を両ツールへ重ねて依頼しない。

同じ変更には一人の担当を置き、並行編集しない。
独立した変更を並行して進めるときは、Git worktree を分ける。
Claude の Agent Teams を全セッションで有効にする設定は置かない。

UI 評価はユーザーが対象を指定して依頼したときだけ起動する。
`design-reviewer` は Opus、推論量 `high` を使う。
評価手順は共有スキルに置き、再委任とファイル書き込みは禁止する。
Bash の読み取り専用という指示は、OS が強制する権限境界とは異なる。

## 速度と判断品質を優先する

Claude のモデルはこの設定で固定せず、契約とセッションの選択に従う。
推論量の既定値は `medium` とし、費用節約のための手動切り替えを前提にしない。
Codex 側は Astra と Standard を既定とし、Fast は必要な作業で明示する。
設定だけで所要時間の改善を保証せず、完了時間と再修正の回数で判断する。

## 承認と実行範囲を標準機能で制御する

Claude の既定の承認モードは `auto` とする。
コマンド名による一括許可は置かず、既存の拒否設定を維持する。
利用条件を満たさず `auto` が使えない場合は Manual へ戻る。
モードの条件は [公式の承認モード](https://code.claude.com/docs/en/permission-modes) で確認する。

一方、`sandbox.enabled` はコマンドが触れられる範囲を制限する。
操作を承認するかの判断とは別の仕組みだ。
OS ごとの適用範囲は [公式の sandbox 説明](https://code.claude.com/docs/en/sandboxing) に従う。
起動後は `/permissions` と `/sandbox` で適用状態を確認する。

## 検証は変更に合わせ、失敗結果をそのまま扱う

dotfiles 独自の承認、毎編集後の検査、出力加工のフックは使わない。
主担当が変更に必要な検証をまとめて実行し、終了コードと失敗内容を確認する。
通知は `terminal_bell`、状態表示は既存の `statusLine` を使う。
プラグインが提供するフックは、独自フックの撤去とは別に残り得る。

有効なプラグインは次の2個とする。

- `codex@openai-codex`
- `ponytail@ponytail`

Claude から Codex を呼ぶ経路は残す。
独立したレビューは明示依頼時だけ使い、通常の完了条件には加えない。
Git 操作と Go の検証には、標準コマンドとプロジェクトのツールを使う。

`setup-claude.sh` は、利用可能な `codebase-memory-mcp` をユーザースコープへ登録する。
実行ファイルのパスは端末固有なので、`settings.json`には保存しない。

導入設定は、リポジトリのルートで次を確認する。

```sh
bash bootstrap/test-setup-agents.sh
zsh bootstrap/test-setup-claude.zsh
```
