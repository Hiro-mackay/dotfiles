# Upstream

- Source: https://github.com/nanaism/yomiyasu (`skills/yomiyasu/`)
- Vendored commit: `29d67ccb05e370b5958d72920a9cd1aa829dee80` (v2.5.0)
- License: MIT (`LICENSE`)、同梱の Unicode データは `UNICODE-LICENSE.txt`

`.codex-plugin/` と `assets/` は取り込んでいない。
プラグイン配布用のメタデータとロゴであって、スキルの動作には要らない。

更新するときは upstream の `skills/yomiyasu/` を、上の2つを除いてフォルダごと入れ替え、このファイルのコミットを書き換える。
v2.x では references と scripts のファイルが版ごとに増減するので、上書きではなく入れ替える。
