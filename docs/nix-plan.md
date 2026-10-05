# Nix 構成プラン

- 版: v16（2026-10-05）
- 状態: `feat/nix` ブランチで実装済み。CI で検証中。Mac への適用（6.2）はまだ
- 対象: この dotfiles リポジトリ（`~/.dotfiles`）

## 1. 概要

### 目的

- 今の dotfiles を Nix 前提で組み直し、宣言している内容と実際の状態のずれをなくす
- 同じ flake から、Mac と Linux（Ubuntu / Debian）の環境を何度でも作れるようにする
- 今の使い勝手は変えない。エイリアス、mise、Claude Code と Codex の使い方はそのまま残す

### 方針

- 設定ファイルは `~/.dotfiles/config` の1か所で管理する。`~/.config` はディレクトリごとここを指すリンクにする。これは今と同じ構成だ。コミットしてよいファイルは、ホワイトリスト方式の `.gitignore` で決める
- Nix が受け持つのは、次の3つだけにする
  - 何をインストールするか
  - OS の設定
  - ホーム直下などに張るリンク
- Mac はフル構成にする。Linux は、開発サーバーや開発環境で使う軽い構成にする
- 入口のコマンドは、両方の OS で `nix run .#switch` の1つにする
- 言語と開発ツールは mise に任せる。会社のプロジェクトが mise を使っているからだ

### 全体図

```
~/.dotfiles（公開リポジトリ）
├── config/        ← ~/.config がディレクトリごとここを指す。設定の中身はすべてここに置く
└── flake
    ├── 共通: home-manager
    │     パッケージ、環境変数、activation（リンクを張るなど）
    ├── Mac: nix-darwin
    │     macOS の設定、Homebrew、/etc と /Library、Touch ID
    │     └── 共通の home-manager を組み込む
    ├── Linux: home-manager を単体で使う
    │     └── 初回だけ sudo で /etc にリンクを張り、Docker を入れる
    ├── apps.switch（nix run .#switch）
    │     OS を判定して nh で適用 → Claude Code が無ければ入れる → MCP を登録 → mise install
    └── GitHub Actions
          flake check、Mac と Linux の build、Ubuntu での通しの確認、週1回の更新 PR
```

### 何を何で管理するか

| 対象 | Mac | Linux |
|---|---|---|
| 基本の CLI と mise 本体 | nixpkgs | nixpkgs |
| 追加の CLI | nixpkgs | 入れない |
| 言語と開発ツール | mise（共通分と Mac 分） | mise（共通分だけ） |
| Codex CLI | llm-agents.nix | llm-agents.nix |
| Claude Code | ネイティブインストーラ（入っていないときだけ） | 同じ |
| 設定ファイル | `~/.dotfiles/config` | 同じ |
| Claude Code と Codex の設定 | フル | フル |
| GUI アプリ | Homebrew の cask | 入れない |
| Docker | Docker Desktop（cask） | Docker Engine（入っていないときだけ apt で入れる。Nix の管理外） |
| sbx | Homebrew | 入れない |
| OS の設定 | nix-darwin | 管理しない |

## 2. 設計の原則

1. **設定の中身は `~/.dotfiles/config` に置く。** `~/.config` はディレクトリごとここを指す。アプリが新しく作った設定ファイルも、自動でここに入る。Nix が `/etc` や `/Library` に置くファイルも、中身は `config/` の中に普通のファイルとして置き、Nix はそれを配置するだけにする
2. **home-manager には、`~/.config` の中のファイルを生成させない。** `programs.zsh`、`programs.git`、`programs.gh`、`programs.claude-code`、`programs.codex`、`xdg.configFile` などは使わない。使うと、リポジトリの実ファイルとぶつかるか、生成したファイルがリポジトリの中に置かれてしまう。例外は1つで、activation が張る skills のリンクだけは `~/.config` の中に作る。このリンクは追跡しない
3. **シェルの処理は `.zsh` ファイルのまま残す。** エイリアスや関数を Nix の書式に書き直しても、良くなることがない
4. **マシン固有の値を含むファイルは追跡しない。** アプリが書き込むファイルでも、共有したい設定なら追跡する。たとえば Claude の `settings.json` や mise の `config.toml` がそうだ。一方、Codex の `config.toml` にはそのマシンのパスが入るので追跡しない。Nix で固定したい設定は、アプリが書き込まない層に置く。Claude なら管理設定、Codex なら `/etc/codex/config.toml` だ
5. **自分で書く activation では、ネットワークを使わない。** オフラインでも成功するようにする。ネットワークが要る処理は、`nix run .#switch` の後処理に置く。ただし Mac では、nix-darwin の Homebrew モジュールが activation の中で cask を取りにいく。そのため Mac の switch だけは、ネットワークが要る
6. **原則2は CI で機械的に確かめる。** home-manager が生成したファイルの一覧（`home-files`）に `.config/` 以下のものが1つでもあれば、CI を失敗させる。`targets.genericLinux` のように、知らないうちに `~/.config` へ書き込むモジュールがあるからだ

## 3. リポジトリの構成

```
~/.dotfiles/
├── flake.nix / flake.lock   # darwinConfigurations.default / minimal、homeConfigurations.<system>
├── nix/switch.nix           # nix run .#switch
├── modules/
│   ├── home/default.nix     共通（OS の違いは hostPlatform.isDarwin で分ける）
│   ├── home/linux.nix       Linux だけ
│   └── darwin/              Mac だけ（default.nix、defaults.nix、homebrew.nix）
├── config/                  ~/.config の実体。ホワイトリスト方式の .gitignore を使う
│   ├── zsh/  git/  gh/  mise/  hammerspoon/  agents/  vscode/  bttpreset/  ...
│   ├── claude/         settings.json、CLAUDE.md、managed-settings.json など
│   └── codex/          AGENTS.md、system-config.toml、rules/ など
└── install.sh
```

## 4. 各部の設計

### 4.1 Nix 本体と flake

- 両方の OS で Determinate Nix を入れる。Mac では、Determinate の darwin モジュールで nix-darwin と組み合わせる（`determinateNix.enable = true`）
- llm-agents.nix のバイナリキャッシュの設定は、flake の `nixConfig` に書かない。`nixConfig` は信頼されたユーザー以外には無視され、Codex を Rust からビルドし始めてしまうからだ。代わりに、次の場所に書く
  - Mac: `determinateNix.customSettings`
  - Linux: install.sh が書く `/etc/nix/nix.custom.conf`
  - CI: Nix をインストールするときの追加設定
- 対象のシステムは `aarch64-darwin`、`x86_64-linux`、`aarch64-linux` の3つだ。システムごとの出力は `nixpkgs.lib.genAttrs` で作る

| flake の入力 | 版 |
|---|---|
| nixpkgs | `nixpkgs-unstable` |
| nix-darwin、home-manager | master（nixpkgs は `follows` でそろえる） |
| nix-homebrew | flake.lock で固定 |
| llm-agents.nix | 最新 |
| determinate、nix-index-database | 最新 |

- stateVersion は `home.stateVersion = "26.05"`、`system.stateVersion = 7` にする
- ガベージコレクションは、Determinate Nixd の自動 GC に任せる
- フォーマッタは `formatter = pkgs.nixfmt-tree` にする

**ユーザー名とホームディレクトリは、実行したときの環境から読む**

ユーザー名やホームディレクトリのパスは、flake に書かない。マシンやサーバーによって、ユーザー名が同じとは限らないからだ。

- `flake.nix` の1か所で `builtins.getEnv "USER"` と `builtins.getEnv "HOME"` を読み、必要な設定すべてに配る。対象は `system.primaryUser`、`users.users.<name>.home`、nix-homebrew の `user`、`home.username`、`home.homeDirectory`、Hammerspoon の `MJConfigFile` だ
- 環境変数は `--impure` を付けたときにしか読めない。そのため `nix run .#switch` は、nh に `--impure` を渡す。nh は build をユーザーの権限で行うので、`USER` には実際のユーザー名が入る
- 設定の名前にユーザー名は入れない。Mac は `darwinConfigurations.default` と `minimal`、Linux は `homeConfigurations.x86_64-linux` と `aarch64-linux` だ
- `--impure` を付けずに評価したとき（`nix flake check` など）は、環境変数が空になる。その場合は仮のユーザー名（`nixuser`）を使うので、CI の check は通る
- ユーザー名が `root` のときは評価を失敗させる。`sudo darwin-rebuild switch` を直接実行すると `USER` が `root` になり、root の環境を作り変えてしまうからだ。適用は必ず `nix run .#switch` から行う。例外は 6.3 の世代を戻す操作で、これは flake を評価しないので問題ない

### 4.2 入口のコマンド（`nix run .#switch`）

flake に、短い app を1つ置く。処理の流れは次のとおり。

1. OS を判定し、nh で適用する
   - Mac: `nh darwin switch -H default -- --impure`。制限付きの Mac では `-H minimal` にする
   - Linux: `nh home switch -b backup -c <system> -- --impure`。`<system>` は `x86_64-linux` などで、app の中で組み立てる
   - nh は、flake から取り出したパッケージのパスで直接呼ぶ。初回は、まだ PATH に入っていないからだ
   - nh は、build をユーザーの権限で行い、build 結果の `activate` だけを sudo で実行する（nh のソースで確認済み）。そのため、Mac の初回（`darwin-rebuild` がまだない状態）でも、そのまま動く。root で git リポジトリを読むこともないので、所有者のチェックにも引っかからない
2. `~/.local/bin/claude` がなければ、Claude Code のネイティブインストーラを実行する
3. codebase-memory-mcp を Claude に登録する。`claude mcp get` で確かめ、未登録なら `claude mcp add -s user` を実行する。今の `setup-claude.sh` と同じ処理だ
4. `mise install` を実行する。`gh auth token` で値が取れる場合は、`MISE_GITHUB_TOKEN` に渡してから実行する。認証なしの GitHub API は1時間に60回までしか呼べず、その制限にかからないようにするためだ
5. Mac で `code` があれば、`config/vscode/extensions` の一覧のうち、入っていない VS Code の拡張機能を入れる。旧 `setup-vscode.sh` の処理を移したもの
6. 2〜5 は、失敗しても警告を出すだけで先に進む。次の switch でやり直される

`NH_FLAKE` は `home.sessionVariables` で `~/.dotfiles` に設定する。こうすると、nh を直接実行するときにも引数が要らない。

### 4.3 home-manager の役割

| 役割 | 中身 |
|---|---|
| パッケージ | `home.packages`（4.8 を参照） |
| 環境変数 | `home.sessionVariables`。zsh のプラグインのパスや `NH_FLAKE` など。値は `hm-session-vars.sh` に書き出され、`.zshenv` がこれを読む |
| activation | 下の表を参照。どれもネットワークを使わず、何度実行しても同じ結果になる |
| ファイル単位のリンク | 下の表を参照 |

**activation で行うこと**

| 処理 | 中身 |
|---|---|
| ホーム直下の入口のリンク | `~/.config` → `~/.dotfiles/config`、`~/.zshenv` → `~/.dotfiles/config/zsh/.zshenv`、`~/.claude` → `~/.config/claude`、`~/.codex` → `~/.config/codex` の4つを、`ln -sfn` で張る。今の `setup-link.sh` と同じ動きだ。普通のファイルやディレクトリがすでにあれば、先に退避する。home-manager の `home.file` は使わない。`.config` の下に生成されるファイルとぶつかるうえ、世代を戻したときにリンクごと消えるおそれがあるからだ |
| skills のリンク | `config/agents/skills/` の skill ごとに、`config/claude/skills/<name>` と `config/codex/skills/<name>` へ相対リンクを張る。今の `setup-agents.sh` の処理を移したものだ。skills ディレクトリを丸ごとリンクにはしない。`~/.claude/skills` には SSoT（skills の原本を置く1か所）の外の skill（`dig`、`synced` など）があり、`~/.codex/skills` には Codex が置く `.system` があるからだ |
| git の設定 | このリポジトリの `core.hooksPath` を `config/git/hooks` にする。残っている `filter.codex-config.*` は消す |
| git-secrets | `~/.gitconfig.local` の値を、禁止パターンとして登録する |
| ディレクトリ | `~/.local/state/zsh` などを作る |

**ファイル単位のリンク**（`home.file` と `mkOutOfStoreSymlink` で張る）

| リンク | 指す先 | OS |
|---|---|---|
| `~/Library/Application Support/Code/User/settings.json` | `~/.dotfiles/config/vscode/settings.json` | Mac |
| `~/.local/share/dotfiles/etc/codex/config.toml` | `~/.dotfiles/config/codex/system-config.toml` | Linux |
| `~/.local/share/dotfiles/etc/claude-code/10-nix.json` | `~/.dotfiles/config/claude/managed-settings.json` | Linux |

リンクを張る場所にファイルがすでにあると、home-manager は上書きせずに止まる。そのため、Mac では `home-manager.backupFileExtension = "backup"` を、Linux では `-b backup` を指定する。こうすると、元のファイルを退避してからリンクを張る。

### 4.4 Mac だけの設定（nix-darwin）

| 今の `setup-macos.sh` の内容 | 移し先 |
|---|---|
| ユーザー単位の defaults | `system.defaults` と `CustomUserPreferences` |
| root で書く defaults（`AdminHostInfo`） | `CustomSystemPreferences` |
| nvram | activation script |
| タイムゾーン | `time.timeZone` |
| LSQuarantine の無効化 | 今と同じく、選んだときだけ行う。`DOTFILES_DISABLE_QUARANTINE=1` を付けて switch する（評価のときに読む） |

ほかに、次の設定を入れる。

- **Hammerspoon**: `MJConfigFile` を `<ホームディレクトリ>/.config/hammerspoon/init.lua` にする。`~` が展開されるかは分からないので、絶対パスで書く。これで `~/.hammerspoon` のリンクは要らなくなる
- **Touch ID**: sudo を Touch ID で通す（`security.pam.services.sudo_local.touchIdAuth`）
- **zsh**: `programs.zsh.enable = true` にする。この `programs.zsh` は nix-darwin のもので、書き込み先は `/etc/zshrc` だ。既定の動きのうち、次の2つは `.zshrc` とぶつかるので止める
  - `programs.zsh.promptInit = ""`: 既定では `prompt suse` が設定されるため
  - `programs.zsh.enableGlobalCompInit = false`: 既定では全員分の `compinit` が走り、`.zshrc` の `compinit -C` と二重になるため
- **home-manager**: nix-darwin のモジュールとして組み込む（`useGlobalPkgs`、`useUserPackages`）。組み込むには、`users.users.<ユーザー名>.home` の指定が必要だ
- **Codex の共通の設定**: `environment.etc."codex/config.toml".source` で、`config/codex/system-config.toml` を `/etc` に置く
- **Claude Code の管理設定**: nix-darwin の activation script で、`config/claude/managed-settings.json` を `/Library/Application Support/ClaudeCode/managed-settings.d/10-nix.json` にコピーする。`/Library` は `environment.etc` の対象外だからだ。宣言から消しても、このファイルは自動では消えない
- **制限付きの Mac**: `darwinConfigurations.minimal` を使う。必須の cask（Hammerspoon、Warp）以外は入れない。`DOTFILES_HOST=minimal nix run .#switch` で選ぶ。今の `DOTFILES_SKIP_CASKS=1` の代わりになる

### 4.5 Mac のアプリ（Homebrew）

- nix-homebrew で Homebrew 本体を入れる。設定は `user`（環境から読んだユーザー名）と `autoMigrate = true` だ。tap は `homebrew.taps` にそのまま書くので、`brew tap` も手で使える
- `homebrew.onActivation` は `autoUpdate = true`、`upgrade = true`、`cleanup = "zap"` にする。`cleanup` は、切り替えが終わってから有効にする

| 種類 | 中身 |
|---|---|
| taps | `docker/tap` |
| brews | `docker/tap/sbx` |
| casks（必須） | Hammerspoon、Warp |
| casks（default だけ） | Docker Desktop、BetterTouchTool、VS Code、Zed、Chrome、Obsidian、Spotify、AppCleaner、ChatGPT、Claude、Codex.app |
| masApps（default だけ） | Kindle |

BetterTouchTool のプリセットは `config/bttpreset/` で管理し、BTT への読み込みは手作業で行う。

### 4.6 Linux だけの設定

- `targets.genericLinux.enable = true` にする。ロケールは、home-manager の `i18n` モジュールが `LOCALE_ARCHIVE` を設定する
- `systemd.user.enable = false` にする。有効なままだと、home-manager が `~/.config/systemd/user/tray.target` と `~/.config/environment.d/` を生成する。これは原則2に反する（実装中に原則6の検査が見つけた）。systemd のユーザーサービスは使っていないので、止めても困らない
- `targets.genericLinux.gpu.enable = false` にする。サーバーでは GPU のドライバの設定は要らず、sudo を求める警告も出さずに済む
- `homeConfigurations` は、システムごとに1つずつ用意する（`x86_64-linux`、`aarch64-linux`）。ユーザー名は環境から読むので、ユーザーごとの設定は要らない
- install.sh は、まず `curl` と `ca-certificates` が無ければ apt で入れる。git は Nix を入れたあとに `nix run nixpkgs#git -- clone` で使うので、前もって入れる必要はない
- 初回だけ、sudo で次の作業を行う。どれも install.sh に入れる
  - `/etc/codex/config.toml` と `/etc/claude-code/managed-settings.d/10-nix.json` にリンクを張る。リンク先は、4.3 の表にある `~/.local/share/dotfiles/etc/` 以下のファイルだ。そのため、これ以降の変更は root なしで反映される
  - `docker` が無く、かつ systemd が動いている（`/run/systemd/system` がある）ときだけ、Docker の公式 apt リポジトリから Docker Engine と compose プラグインを入れ、ユーザーを `docker` グループに加える。`docker` がすでにある環境（sbx の sandbox の中や、用意済みのサーバー）と、systemd のない環境（コンテナなど）では何もしない
  - 必要な環境では、Nix で入れた zsh を `/etc/shells` に登録し、`chsh` でログインシェルにする
- Linux のサーバーは、1人で使う前提にする。`/etc` のファイルはマシンに1つしかなく、リンク先は最初に install.sh を実行したユーザーのホームにある。そのため、複数のユーザーで使うと全員が同じ設定を読む
- systemd のない環境（コンテナや一部の sandbox）は、今は対象外にする。Nix のデーモンが動かず、root 以外は Nix を使えないからだ。install.sh は、systemd がなければ止まる。必要になったら、構成を焼き込んだイメージを作る
- SSH の鍵は Nix で管理しない。サーバーから push するときは、手元の Mac から SSH エージェントを転送する
- サーバーで `/model` や `mise use -g` を使うと、追跡しているファイル（`settings.json` や `config.toml`）が書き換わる。更新を取り込むときは `git pull --autostash` を使う。サーバーで変えた設定は、残したいものだけをコミットする

### 4.7 シェル（zsh）

- `.zshenv`、`.zshrc`、`rc.d/*.zsh` は、今と同じく `config/zsh/` の実ファイルを使う
- `.zshenv` で `hm-session-vars.sh` を読む。このファイルの場所は環境によって違うので、どちらにあっても読めるようにしておく
  - nix-darwin: `/etc/profiles/per-user/$USER/etc/profile.d/`
  - home-manager を単体で使う場合: `~/.nix-profile/etc/profile.d/`
- **履歴の設定（v13 で適用済み）**: macOS の `/etc/zshrc` が、`.zshenv` で設定した `HISTFILE`、`HISTSIZE`、`SAVEHIST` を上書きしていた。そのせいで履歴はリポジトリの中に保存され、件数の上限も1000件になっていた。この3つと `HISTORY_IGNORE` を `.zshrc` で設定し直し、履歴を `~/.local/state/zsh/history` に戻した。nix-darwin の `/etc/zshrc` も同じように上書きするので、この設定は移行後も残す
- PATH は「Nix → mise → Homebrew（Mac だけ）」の順に組み立て直す。今の `.zshrc` は Homebrew を先頭に足しているので、ここを書き直す。Mac では `/opt/homebrew/bin` を残す。cask が置く `code` と `zed`、Homebrew で入れる `sbx` がここにあるからだ。Homebrew を Nix より後ろに置くのは、Codex.app の cask が `codex` を置いた場合でも、Nix の `codex` を使うためだ
- zsh-autosuggestions と zsh-syntax-highlighting は Nix で入れる。読み込むパスは、home-manager の環境変数（例: `ZSH_AUTOSUGGEST_DIR`）で渡す。`$BREW_HOME/share/...` と直接書いている箇所は、この環境変数に置き換える
- nix-index の command-not-found（見つからないコマンドを打ったときに、入っているパッケージを教えてくれる機能）も、環境変数でパスを渡して `.zshrc` から読み込む。`programs.zsh` を使わないので、自動では有効にならない
- mise、zoxide、direnv、fzf、starship は、今の `plugins.zsh` の `eval` で読み込む。Warp を判定するコードも残す
- Mac でしか動かないものは `rc.d/darwin.zsh` にまとめ、`[[ $OSTYPE == darwin* ]]` のときだけ読み込む

| 対象 | 扱い | 理由 |
|---|---|---|
| `warp-code.zsh` の中身 | Mac だけ | AppleScript を使う |
| `sbxc` | Mac だけ | sbx は Mac にだけ入れる |
| `ccgo` | Mac だけ | `pmset` を使う |
| `pwdcp`、`cpb`、`jc` | Mac だけ | `pbcopy` と `pbpaste` を使う |
| `op` | Mac だけ | `open` を使う |
| `em` | Mac だけ | emacs は Mac にだけ入れる |
| `co`、`edzsh`、`codeexport` | `code` コマンドがあるときだけ定義する | VS Code の Remote SSH でつないだサーバーでも、`code` が使えるため |

- 削除するもの: `podman.zsh`、`compete`、`drive`、`lzd`（lazydocker。入れる予定がないため）と `cheat` の中のその説明、gcloud の `~/.google-cloud-sdk` を読む処理（このディレクトリはもう無い）

### 4.8 開発ツールと言語

Nix と mise のどちらで入れるか迷ったら、「どこかのプロジェクトで版を固定する可能性があるか」で決める。可能性があれば mise、なければ Nix に入れる。

**Nix で入れるもの（`home.packages`）**

| 範囲 | 中身 |
|---|---|
| 両方の OS | mise、git、gh、ghq、fzf、ripgrep、fd、bat、eza、jq、zoxide、direnv、lazygit、starship、vim、lsof、git-secrets、zsh-autosuggestions、zsh-syntax-highlighting、nh、comma |
| Mac だけ | emacs、htmlq、shellcheck、watch、terminal-notifier、coreutils-prefixed（`cpb` が使う `ghead` のため） |

**mise で入れるもの**

| ファイル | 中身 | OS |
|---|---|---|
| `config/mise/config.toml` | node、python、uv、go、pnpm、terraform、kubectl、kind、skaffold、golangci-lint、sqlc、buf、task（go-task）、lefthook、`aqua:golang-migrate/migrate`、`go:golang.org/x/tools/gopls`、`npm:codebase-memory-mcp` | 両方 |
| `config/mise/config.macos.toml` | gcloud、bun、deno、ni、rust、sops | Mac だけ |

- `config.macos.toml` は Linux からも見える。そこで、`config/mise/miserc.toml` に `auto_env = true` を書く。こうすると mise は、Mac で動いているときだけ `config.macos.toml` を読む。`auto_env` は設定ファイルを探す前に読む設定なので、`config.toml` に書いても効かない（実装中に確かめた）
- `mise use -g` は `config.toml` に書き込むので、変更が git diff に出る。今と同じだ
- `~/.local/share/mise/shims` を `home.sessionPath` で PATH に入れる。Dock から起動した VS Code や、エージェントが使う非対話シェルからも、mise のツールが見えるようにするためだ
- mise の Python は、ビルド済みのバイナリを使う
- 言語の更新は、今と同じく `mise upgrade` で行う

**codebase-memory-mcp**

- mise の `npm:` バックエンドで、公式の npm パッケージを入れる。mise は npm のツールを、既定では組み込みの aube で入れる。インストール後のスクリプトを確実に動かすため、`npm.package_manager = "npm"` を指定する。node は npm のツールより先に入る（mise のドキュメントで確認済み）
- 更新する前に、Claude と Codex のセッションを閉じる。古い版のデーモンが残っていると、新しい版が起動時に拒否されるからだ
- npm 経由で動かない場合は、公式の `install.sh --skip-config` に切り替える。`nix run .#switch` の後処理で、入っていないときだけ実行する

### 4.9 設定ファイル（`config/` と `.gitignore`）

`config/.gitignore` は、今と同じホワイトリスト方式で運用する。変更点は次のとおり。

| 変更 | 対象 |
|---|---|
| 追加する | `!codex/rules/**`、`!codex/system-config.toml`、`!claude/managed-settings.json` |
| 外す（ほか） | `!brew/*`（Brewfile を削除したため） |
| 外す | `!codex/config.toml`（マシン固有のパスを含むので追跡しない） |
| そのまま | `!claude/settings.json`、`!mise/*`、`!zsh/**` など、今の許可リスト |

skills のリンクは追跡しない。activation が毎回張り直す（4.3 を参照）。

### 4.10 Claude Code と Codex（両方の OS で同じ）

設定の実体は、今と同じく `~/.dotfiles/config/claude` と `~/.dotfiles/config/codex` に置く。Claude Code と Codex は、ホーム直下の `~/.claude` と `~/.codex` を読みにくる。この2つは、実体を指すリンクとしてホーム直下に残す。

`CLAUDE_CONFIG_DIR` や `CODEX_HOME` を使えば、ホーム直下のリンクをなくすこともできる。ただし、Dock から起動したアプリや launchd、sbx などには、環境変数が届かない。届かなかったアプリは、別の `~/.claude` を新しく作って動いてしまう。リンクなら、どこから起動しても同じ場所を読む。

**Claude Code**

| 対象 | 置き場所 |
|---|---|
| 本体 | `nix run .#switch` の後処理で、入っていないときだけネイティブインストーラで入れる。更新は Claude Code の自動更新に任せる |
| 禁止ルール | 中身は `config/claude/managed-settings.json` に置く。それを管理設定の場所に配置する（Mac は `/Library/Application Support/ClaudeCode/managed-settings.d/10-nix.json`、Linux は `/etc/claude-code/managed-settings.d/10-nix.json`）。今の11件に加えて、作業ツリーの中にある認証情報を読ませないルールを足す。パスは `~/.config/...` と `~/.dotfiles/config/...` の両方で書く。リポジトリの中で作業するエージェントは、同じファイルを後者のパスで読めるからだ（例: `Read(~/.config/codex/auth.json)` と `Read(~/.dotfiles/config/codex/auth.json)`、gh の `hosts.yml`、`gcloud/**`） |
| モデル、テーマ、プラグインの有効化 | `config/claude/settings.json`。今と同じく追跡する |
| CLAUDE.md | 今と同じく、`@~/.config/agents/AGENTS.md` を参照する1行のファイル |
| プラグイン | marketplace から入れる |
| codebase-memory-mcp | `nix run .#switch` の後処理で、`claude mcp add -s user` を実行して登録する |
| ログイン状態、trust など | Claude Code が `~/.claude.json` と Keychain（Mac）に書き込む。設定ではなく状態なので、管理しない |

**Codex**

| 対象 | 置き場所 |
|---|---|
| 本体 | llm-agents.nix |
| 既定のモデル、承認の方針、sandbox、codebase-memory-mcp、プラグイン、marketplace、`[tui]` | 中身は `config/codex/system-config.toml` に置く。それを `/etc/codex/config.toml` に配置する。Codex はこのファイルを一番優先度の低い層として読み、自分では書き込まない。ユーザーのホームのパスは書かない。MCP の起動コマンドは `codebase-memory-mcp` という名前だけで書く |
| `/etc` に移さない設定 | `notify`、`CODEX_HOME`、`NODE_REPL_*`、`[projects."..."]`、Codex.app が管理するプラグイン（`openai-bundled` と `openai-primary-runtime`）とその marketplace。どれも Codex か Codex.app が書き込んだ、そのマシンのパスを含む値なので、`~/.codex/config.toml` に残す |
| `config/codex/config.toml` | Codex に任せる。追跡はやめる |
| AGENTS.md | `config/codex/AGENTS.md`。今と同じく、pre-commit で `config/agents/AGENTS.md` からコピーした実ファイルにする。Codex はファイルのリンクを読まないことが分かっている |
| 実行してよいコマンドのルール | `config/codex/rules/` に置き、追跡する |

### 4.11 git、エディタ、pre-commit

- git と gh の設定は、今と同じく `config/git/config` と `config/gh/config.yml` の実ファイルを使う。`~/.gitconfig.local` も今と同じく手で置く
- リポジトリの pre-commit は、git-secrets の検査と、Codex の AGENTS.md のコピーの2つだけを行う。sanitizer と clean filter は削除する
- VS Code と Zed の設定は、Nix で生成しない
- VS Code の拡張機能は、今と同じく一覧ファイル、`codeexport`、差分の警告で管理する。home-manager の `programs.vscode` は `~/.config` の外に書き込むので使えなくはないが、使うかどうかは確かめてから決める

### 4.12 日々の運用と、再現できることの確認

| 道具 | 使い方 |
|---|---|
| `nix run .#switch` | 両方の OS で、設定の適用と後処理を行う |
| nh | 適用するとき、パッケージの差分を表示する |
| comma と nix-index-database | `, sqlc` のように、インストールしなくてもコマンドを試せる |

GitHub Actions では、次の5つを行う。キャッシュの action は使わない。ほとんどが公式のバイナリキャッシュから取ってくるだけなので、効果が小さいからだ。

1. `nix flake check --all-systems --no-build` を実行する
2. darwin の構成を macOS で、home の構成を Ubuntu で build する。どちらも `--impure` を付け、ランナーのユーザー名で build する
3. Ubuntu のランナーの上で、一般ユーザーとして、Nix のインストールから `nix run .#switch` まで通しで実行する。コンテナは使わない。systemd のないコンテナでは、一般ユーザーが Nix を使えないからだ。checkout した場所から `~/.dotfiles` にリンクを張り、mise 用に `GITHUB_TOKEN` を渡す
4. 週1回、`update-flake-lock` で更新の PR を作る
5. home-manager が生成したファイルの一覧に、`.config/` 以下のものがないことを確かめる（原則6）。一覧の場所は、home-manager を単体で使う場合と nix-darwin 経由の場合とで違うので、両方を調べる。作ったら一度、わざと `xdg.configFile` を足して、この確認が失敗することを確かめる

1 が、Linux の上で darwin の設定を評価するところで失敗した場合は、darwin の確認は 2 の macOS のランナーだけに任せる。3 が通っている限り、同じ環境をいつでも一から作れる。

sbx のテンプレートに Linux の構成を焼き込むかどうかは、あとで決める。

## 5. インストール前後の手作業

`docs/additional-setup.md` を、この一覧に書き換える。

| 対象 | 作業 |
|---|---|
| Mac（最初の switch の前） | `xcode-select --install` で Command Line Tools を入れる。Homebrew が必要とする。App Store にサインインする。サインインしていないと、Kindle のインストールで switch が失敗する。Homebrew の外で入れた ChatGPT、Claude、BetterTouchTool、Codex.app を削除する |
| 両方の OS（switch の後） | `~/.gitconfig.local` を作る。`gh auth login` を実行する。`claude` と `codex` にログインする |
| Mac（switch の後） | `sbx login` を実行する。Hammerspoon と Warp にアクセシビリティの権限を与える。Docker Desktop を一度起動する。BTT のプリセットを読み込む。動作を確かめたら `cleanup = "zap"` にする |
| Linux（switch の後） | SSH エージェントの転送を設定する。`docker` グループを反映させるため、一度ログインし直す |

## 6. 移行の進め方

### 6.1 ブランチでの作業（いつでも元に戻せる）

1. 別のブランチで、flake と `modules/` を足す。`config/` の中身は必要な分だけ直す。新しく作ったファイルは `git add` しておく（コミットは要らない）。flake は、git に登録されていないファイルを見ないからだ
2. （取りやめ）Warp の設定は dotfiles で管理しない。Warp のアカウントの同期で、すでにほかのマシンとそろっているからだ。公開リポジトリに載せたくない識別子も含まれていた
3. 今の `config/codex/config.toml` から共通の設定を取り出し、`config/codex/system-config.toml` を作る。今の `permissions.deny` から `config/claude/managed-settings.json` を作る
4. Mac で `darwin-rebuild build` が通り、Linux（Ubuntu の VM かランナー）で `nix run .#switch` が通るところまで進める。ここまでは、Mac の状態は変わらない
5. 「8.2 まだ確かめていないこと」を、Linux での実行と build の結果で確かめる

### 6.2 Mac の切り替え（手動で実行する）

`~/.config`、`~/.claude`、`~/.codex` のリンクは今と同じなので、データを移し替える必要はない。

切り替えは、Claude Code と Codex を終了させてから、素のターミナルで行う。`~/.claude` の実体はリポジトリの中にあるので、動作中に退避すると不完全なコピーになる。また、管理設定の禁止ルールがあるため、sudo を使う手順は Claude からは実行できない。

1. `~/.dotfiles` を退避する
2. App Store にサインインしていることを確かめる
3. ChatGPT、Claude、BetterTouchTool、Codex.app を `/Applications` から削除する。どれも Homebrew の外で入れたものなので、残っていると cask のインストールとぶつかり、switch が失敗する。BTT は先にプリセットを書き出しておく。ライセンスは `~/Library` に残る
4. podman を使っている場合は、`podman machine stop` と `podman machine rm` を実行する。Docker Desktop が使えるようになるまでは、podman を使い続けてよい
5. Determinate Nix を入れる
6. `codebase-memory-mcp uninstall` で、公式インストーラで入れたものを消す。インデックスは残る。インストーラが `~/.claude/skills/codebase-memory` などに書き込んだものも、このとき取り除かれる
7. `~/.codex/config.toml` から、`system-config.toml` に移した設定を消す。ユーザーのファイルに残っていると、そちらが優先されて、Nix で変えた設定が効かなくなるからだ
8. `nix run .#switch` を実行する。最初の switch は全部の cask を更新するので、時間がかかる。Docker Desktop などがパスワードを求めることがあるので、対話できるターミナルで実行する
9. 「7. 現在の構成から変わること」の「変わらないこと」を、1つずつ確かめる
10. podman と graphify（`uv tool uninstall graphifyy`）を消す。そのあとで、Homebrew の `cleanup` を有効にする

途中で失敗してやり直すときは、まず退避ファイルが残っていないかを確かめて消す。残っていると、home-manager は上書きを避けて止まる。場所は次のとおり。

- `~/Library/Application Support/Code/User/settings.json.backup`

nix-darwin が「Unexpected files in /etc」と表示して止まった場合は、表示されたファイル名の末尾に `.before-nix-darwin` を付けてから、もう一度実行する。今の `/etc/zshrc`、`/etc/bashrc`、`/etc/zprofile` は nix-darwin が知っている内容なので、自動で名前が変わる。止まるのは、Determinate がこれらのファイルを書き換えた場合だけだ。

### 6.3 元に戻す

- **Mac で世代を戻す**: `sudo darwin-rebuild --rollback` を使う。これは flake を評価しないので、4.1 の root のチェックには引っかからない
- **Linux で世代を戻す**: `home-manager generations` で戻したい世代のパスを調べ、そのパスの `activate` を実行する
- **世代を戻しても元に戻らないもの**: 次のものは、activation や Homebrew が直接変えたものだからだ
  - ホーム直下のリンクと skills のリンク
  - `/Library` の Claude の管理設定と、`/etc` のファイル
  - Homebrew で入れたもの
  - git の設定（`core.hooksPath` など）
- **Nix ごと消す**: 順番を守る。先に nix-darwin のアンインストーラ（`nix run nix-darwin#darwin-uninstaller`）を実行し、そのあとで Determinate のアンインストーラを実行する。逆の順にすると、nix-darwin が作った `/etc` のファイルが、存在しない store を指したまま残る
- **最後に**: 退避しておいた `~/.dotfiles` を戻す

### 6.4 後片付け（同じブランチで行う）

- 次のものを削除する
  - 旧 bootstrap スクリプト
  - Brewfile
  - sanitizer
  - `.gitattributes` の filter
  - `setup-agents.sh`（処理は activation に移した）
- `config/codex/config.toml` を git の追跡から外す
- `install.sh` を作り直す。処理は次の5段階だ
  1. OS を判定する
  2. Determinate Nix を入れる
  3. `~/.dotfiles` を clone する
  4. Linux なら、初回の sudo 作業を行う
  5. `nix run .#switch` を実行する
- README と MEMORY.md を書き直す
- 別のリポジトリの作業として、`kindle-ocr/.mise.toml` の扱いを見直す

## 7. 現在の構成から変わること

| 今 | これから |
|---|---|
| Mac だけ | Mac（フル構成）と Linux（開発作業用の軽い構成） |
| bootstrap スクリプトが10本 | `install.sh` と `nix run .#switch` |
| Brewfile が、実際の状態とずれている | Nix で宣言する。cask は switch のたびに更新される |
| mise と brew の両方に、同じ言語が入っている | 言語は mise だけで入れる。共通の分と Mac の分は、ファイルを分ける |
| Go の開発ツールや kubectl を brew で入れている | mise のグローバル設定に移す |
| codebase-memory-mcp を公式インストーラで入れている | mise の `npm:` で入れる |
| podman | Docker Desktop（Mac）と Docker Engine（Linux） |
| Codex CLI を cask で入れている | llm-agents.nix で入れる |
| Codex の `config.toml` を、sanitizer、clean filter、pre-commit で整えている | 共通の設定は `config/codex/system-config.toml` に置き、`/etc` に配置する。この3つの仕組みは削除する |
| Claude の禁止ルールが、ユーザー設定の中にある | `config/claude/managed-settings.json` に移し、管理設定として配置する |
| skills と入口のリンクを `setup-agents.sh` と `setup-link.sh` で張っている | 同じ処理を activation で行う |
| 履歴がリポジトリの中に保存され、上限が1000件になっていた | `~/.local/state/zsh/history` に保存し、上限を10万件にした（適用済み） |
| `DOTFILES_SKIP_CASKS` などの環境変数で切り替えている | `darwinConfigurations.minimal` で切り替える |
| `compete`、`drive`、`lzd`、graphify | 削除する |

**変わらないこと**

- `~/.config`、`~/.claude`、`~/.codex` が、`~/.dotfiles/config` 以下を指すリンクであること。ホワイトリスト方式の `.gitignore`
- エイリアスと関数。`sozsh` で、すぐ反映されること
- mise での言語管理、`mise use -g`、会社のプロジェクトの `mise.toml`
- `sbxc`
- Claude Code の `/config` と `/model` が保存されること、プラグインの追加と削除、自動更新
- Codex の trust
- 英数/かなの切り替え、Warp での表示、BetterTouchTool
- `brew tap`

## 8. 注意すること

### 8.1 切り替えの前に済ませること

- `.zshrc` の履歴の設定は、すでに直した（4.7）。開いているシェルを全部閉じてから、古い履歴を新しい場所に移す。`cat ~/.config/zsh/.zsh_history >> ~/.local/state/zsh/history && rm ~/.config/zsh/.zsh_history`。閉じる前に移すと、古いシェルが古いファイルに書き込み続ける

### 8.2 まだ確かめていないこと

Ubuntu のランナーでの検証（CI の `linux-e2e`）と、Mac での最初の switch で確かめる。次のものは実装中に確かめたので、一覧から外した。

- `auto_env` で、Mac のときだけ `config.macos.toml` が読まれること（`miserc.toml` に置く必要があった）
- `docker/tap` の信頼の手作業は要らないこと（nix-darwin が Brewfile に `trusted: true` を付ける）
- home-manager が `~/.config` の下に何も生成しないこと（原則6の検査で確認。Linux の systemd を止めた）

| 確かめること | 確かめられなかった場合 |
|---|---|
| `hm-session-vars.sh` が、4.7 に書いた2か所のどちらかにあるか | `.zshenv` で読む場所を直す |
| `settings.json` に書いたプラグインが、新しいマシンで自動で入るか | 後処理で `claude plugin install` を実行する |
| mise の npm バックエンドで、codebase-memory-mcp のインストール後スクリプトが動くか。Mac で署名の問題なく起動し、MCP としてつながるか | 公式の `install.sh --skip-config` に切り替える |
| Codex.app から起動したときも、MCP の起動コマンドを名前だけ（`codebase-memory-mcp`）で見つけられるか | このコマンドのパスだけ、Nix でホームディレクトリから組み立てる |
| sbx の sandbox の中で kind が動くか | sandbox の中では kind を使わない |

### 8.3 承知しておくこと

**設定とその追跡**
- 実行時のデータ（認証情報、セッション、キャッシュ）は、今と同じくリポジトリの作業ツリーの中に置かれる。コミットを防ぐのはホワイトリストと git-secrets だ。Claude には管理設定の禁止ルールで読ませないが、ほかのツール（インデクサなど）からは見える
- 新しく追跡したいファイルがあるときは、`config/.gitignore` に `!` の行を足す。今と同じ運用だ
- home-manager の `programs.*` を使わないので、zsh などの設定ファイルの中身が正しいかどうかを、Nix の build では確かめられない
- `config/` の中の `system-config.toml` と `managed-settings.json` を書き換えたときは、switch するまで `/etc` と `/Library` に反映されない。ただし Linux はリンクで配置しているので、すぐに反映される

**版と再現性**
- ユーザー名とホームディレクトリを環境から読むので、設定の結果は flake.lock だけでは決まらない。実行した人の `USER` と `HOME` にも左右される。変わるのは、この2つだけだ
- `--impure` で評価するので、評価結果のキャッシュが効かない。switch のたびに評価し直すので、少し遅くなる
- mise のグローバル設定は `latest` なので、作るたびに同じ版になるとは限らない。週1回の自動 PR で更新されるのは、Nix で入れたものだけだ
- Claude Code と、Linux の Docker Engine の版は、flake.lock では固定されない
- 同じツールを Nix と mise の両方に入れない。両方にあると mise が優先され、Nix のほうは使われない
- `auto_env = true` にすると、プロジェクトの `mise.macos.toml` や `mise.linux.toml` も、OS に合わせて自動で読まれる
- nix-homebrew は Homebrew 本体の版を flake.lock で固定する。最初の switch で、今入っている Homebrew が固定した版に置き換わる（版が下がることもある）
- 週1回の更新 PR を作るには、リポジトリの設定「Allow GitHub Actions to create and approve pull requests」を有効にする必要がある。今は無効になっている。また、GitHub Actions のトークンで作った PR では、CI が自動では動かない

**Claude Code と Codex**
- 管理設定に書いた値は、`/config` で変えても効かない。普段変えない値だけを置く
- Codex の画面でプラグインの有効・無効を切り替えると、その設定は `~/.codex/config.toml` に書き込まれる。それ以降は、`/etc` の設定よりこちらが優先される。Nix で変えた設定が効かないときは、まずユーザー側のファイルを確かめる
- 管理設定や `/etc` に置いたファイルは、宣言から消しても自動では消えない。要らなくなったら手で消す
- Linux では、`/etc` からのリンクが、ユーザーが書き込める場所を経由する。そのため、Claude が自分で禁止ルールを緩められないという保護は、Mac より弱い
- codebase-memory-mcp を更新する前に、エージェントのセッションを閉じる
- Codex を急いで更新したいときは、`nix flake update llm-agents` を実行する

**運用**
- `docker` グループに入ったユーザーは、実質的に root と同じことができる。共用のサーバーでは、インフラ担当の方針に従う
- Homebrew の cask は switch のたびに更新されるので、そのぶん switch に時間がかかる

## 9. 判断の記録

| 判断 | 理由 | 検討して採らなかった案 |
|---|---|---|
| 今の構成を移植せず、ゼロから組み直す | 独自に作った仕組みの副作用を残さないため。Codex の sanitizer や、bootstrap のスクリプト群がその例だ | 今の構成をそのまま Nix に移植する |
| `~/.config` をディレクトリごとリンクしたままにする | 設定を1か所で管理し、散らさないため。アプリが新しく作った設定も、自動でリポジトリに入る | ファイルごとにリンクする。この案なら home-manager の `programs.*` が使えるが、設定の置き場所が分散する |
| home-manager に `~/.config` の中のファイルを生成させない | `~/.config` の実体はリポジトリなので、生成したファイルと実ファイルがぶつかる | `programs.zsh` などで生成する |
| ホーム直下の入口のリンクは activation で張る | `home.file` で管理すると `.config` の下の生成物とぶつかる。世代を戻すと、リンクごと消えるおそれもある | home-manager の `home.file` で管理する |
| `~/.claude` と `~/.codex` はリンクで残す | 環境変数（`CLAUDE_CONFIG_DIR`、`CODEX_HOME`）は、Dock から起動したアプリや launchd に届かないことがある | 環境変数で置き場所を変える |
| `/etc` と `/Library` に置く設定も、中身は `config/` に置く | 設定の中身を1か所に集めるため | Nix のコードの中に書く |
| ユーザー名とホームディレクトリは環境から読む（`--impure`） | ユーザー名は、マシンやサーバーによって違うことがある。サーバーを増やすたびに設定を足さずに済む | マシンごとのファイルにユーザー名を書く |
| `nix run .#switch` は常に nh を使う | nh は build をユーザーの権限で行い、`activate` だけを sudo で実行する。そのため、Mac の初回にも、root で git を読む問題にも、場合分けが要らない | 初回だけ `sudo nix run nix-darwin` を使う |
| Determinate Nix を使う | macOS のアップデートに強い。2026年1月以降、Determinate のインストーラは Determinate Nix しか入れない | upstream の Nix |
| nixpkgs は `nixpkgs-unstable` にする | 更新の速さを、今の mise の `latest` に近づけるため | 安定版の 26.05 |
| GUI アプリは Homebrew の cask で入れる | nixpkgs では、多くのアプリが古いか、署名がないか、そもそもない | nixpkgs と mac-app-util |
| 言語は mise に任せる | 会社のプロジェクトが mise を使っている | nixpkgs、uv、rustup |
| Claude Code はネイティブインストーラで入れる | 自動更新が使え、今と同じ運用で済む | nixpkgs、llm-agents.nix |
| Codex は llm-agents.nix で入れる | Mac と Linux で入れ方をそろえるため | brew の cask |
| Claude のプラグインは marketplace から入れる | 試す、入れる、外すを自由にできるようにするため | flake で版を固定する |
| Codex の共通の設定は `/etc/codex/config.toml` に置く | Codex はここを一番優先度の低い層として読み、自分では書き込まない | activation でユーザー設定にマージする |
| Claude の禁止ルールは管理設定に置く | ユーザー側から上書きできないので、Claude が自分で緩めることもできない | ユーザー設定に置く |
| skills は skill ごとにリンクする | 両方の skills ディレクトリには、SSoT の外のものもある | skills ディレクトリを丸ごとリンクにする |
| Codex の AGENTS.md は pre-commit でコピーする | Codex はファイルのリンクを読まない | 相対リンクにする |
| system-manager は使わない | Determinate との組み合わせが保証されていない。`/etc` に置くファイルも2つしかない | system-manager |
| Docker に統一する | 互換性のことを考えずに済む | podman、Colima |
| Linux は軽い構成にする | 開発サーバーや sandbox での作業が中心になる | Mac と同じフル構成 |
| CI の通しの確認は Ubuntu のランナーで直接行う | systemd のないコンテナでは、一般ユーザーが Nix を使えない | Ubuntu のコンテナで行う |
| flake-parts と git-hooks.nix は使わない | 今の規模では、使って得られるものが少ない | それぞれを使う |
| Warp の設定は dotfiles で管理しない | Warp のアカウントの同期で、すでにマシン間でそろっている。公開したくない識別子も含まれていた | `~/.warp` をリポジトリにリンクする |
| systemd のない Linux は対象外にする | Nix のデーモンが動かず、一般ユーザーが Nix を使えない。root での利用は、root を拒否する検査と両立しない | `--init none` で入れて root で使う |
| 原則6はモジュールの assertion で実装する | 評価するたびに検査されるので、CI を待たずに手元で気づける | CI だけで検査する |

## 10. 参考

- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [Use Determinate with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [Determinate Nixd（自動 GC）](https://docs.determinate.systems/determinate-nix/determinate-nixd)
- [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer)
- [zhaofengli/nix-homebrew](https://github.com/zhaofengli/nix-homebrew)
- [nix-community/nh](https://github.com/nix-community/nh)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)
- [Claude Code: Settings files and precedence](https://code.claude.com/docs/en/settings)
- [Claude Code: Deploy managed settings](https://code.claude.com/docs/en/managed-settings)
- [Codex config loader README](https://github.com/openai/codex/blob/main/codex-rs/config/src/loader/README.md)
- [mise: shims](https://mise.jdx.dev/dev-tools/shims.html)
- [mise: Platform environments](https://mise.jdx.dev/configuration/environments.html)
- [DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)
- [Docker Sandboxes（sbx）](https://www.docker.com/products/docker-sandboxes/)
- [DeterminateSystems/determinate-nix-action](https://github.com/DeterminateSystems/determinate-nix-action)
