---
name: local-diff-review
description: 利用者が差分を自分の目でローカルで確かめたいときに、会話の右の herdr ペインに差分の画面（herdr-diff-view）を開く。「PR1 の diff 確認」「この PR の差分を見たい」「ローカルで diff を確認」「人間レビューしたい」「diff を右に出して」のように、差分を見る・レビューする依頼で使う。差分の中身を Claude がレビューする依頼（「レビューして」）では使わない。
---

# ローカルの差分を右のペインに開く

利用者が自分で読むための画面を開くだけにする。差分を要約したりレビューしたりはしない。

## 1. base と compare を決める

- 会話の中で PR やブランチが決まっていれば、それを使う。stacked PR なら、その PR のブランチを compare、1つ前の PR のブランチ（最初の PR なら統合先、例: `origin/dynamic-qa/<name>` や `origin/develop`）を base にする。
- GitHub の PR 番号を言われたら、`gh pr view <番号> --json headRefName,baseRefName` で決める。手元にないブランチは `origin/<名前>` にする。
- 決まらなければ base と compare を省く。画面が、今のブランチと一番近いブランチを選ぶ。
- 2つ以上に読めて決まらないときだけ、短く聞く。

## 2. 開く

リポジトリのフォルダ（worktree ならその worktree）で、次を Bash で実行する。

```bash
herdr-diff-pane --session "<セッションID>" --cwd "<リポジトリのフォルダ>" --base "<base>" --compare "<compare>"
```

- セッションID は、`$CLAUDE_JOB_DIR` があればその最後のフォルダ名（例: `/…/jobs/1e44532a` なら `1e44532a`）。なければ `--session` を省く（選ばれているペインの右に開く）。
- 同じタブに差分の画面がすでにあれば、新しく開かずに、そのペインで base と compare を差し替える（位置と幅はそのまま）。2つ以上あれば一番広いものだけを残す。なければ会話のペインを右に分割して開く（会話 3.5 割、差分 6.5 割）。
- 成功すると、差分を出したペインの ID を1行で出す。失敗したら理由を出し、`~/.local/state/herdr-diff-view/pane.log` にも残る。

## 3. 伝える

開いた base と compare を1行で伝える。操作の説明は、聞かれない限り書かない（画面の一番下に出ている）。
