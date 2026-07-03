# 英数/かな切替（Hammerspoon）

左⌘ 単体タップ → 英数、右⌘ 単体タップ → かな。長押しや他キーとの組み合わせでは通常の
⌘ のまま。Karabiner-Elements の同等ルールを置き換えたもの。

- 設定本体: `config/hammerspoon/init.lua`（追跡済み）
- リンク: `~/.hammerspoon -> ~/.config/hammerspoon`（`setup-link.sh`）
- アプリ: `hammerspoon` cask（`Brewfile.cask`）

## なぜ Hammerspoon か

キー入力を横取りする（Accessibility 権限が要る）以上、そのコードの素性と更新経路が最重要。
Hammerspoon は成熟 OSS で Homebrew cask が checksum 固定、切替ロジックは自分が追跡する
`init.lua` だけ。BTT は tap/hold の区別が甘く「長押し=通常⌘」で誤爆しやすいため不採用。
`⌘英かな` fork は最軽量だが個人1人・brew 不可で素性/メンテが弱いため不採用。

## セットアップ

```sh
brew install --cask hammerspoon
~/.dotfiles/bootstrap/setup-link.sh   # ~/.hammerspoon をリンク
open -a Hammerspoon
```

初回起動時に **システム設定 > プライバシーとセキュリティ > アクセシビリティ** で
Hammerspoon を許可する（キーイベントの送出に必須）。許可後、Hammerspoon メニューから
"Reload Config"。

## Karabiner からの移行

Hammerspoon の動作を確認できたら Karabiner を撤去する。両方常駐すると ⌘ が二重に
remap されるので、テスト中は Karabiner を終了しておく。

```sh
# 動作確認後にクリーンアップ
brew uninstall --cask karabiner-elements
git -C ~/.dotfiles rm config/karabiner/karabiner.json   # 追跡ファイル
rm -rf ~/.dotfiles/config/karabiner                      # 残り (assets/ など未追跡)
```

## 検証

1. テキスト欄で 左⌘ を単体で叩く → 英数入力に切り替わる
2. 右⌘ を単体で叩く → かな入力に切り替わる
3. ⌘C / ⌘Tab / ⌘Space など通常のショートカットが誤爆せず動く
4. ⌘ を長押ししても英数/かなが送られない

微調整: `init.lua` の `HOLD_THRESHOLD`（既定 0.2s）で長押し判定の閾値を変えられる。
