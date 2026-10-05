# Nix 構成プラン

- 版: v17（2026-10-05）
- 状態: `feat/nix` ブランチで実装済み。Mac への適用（6章）はまだ
- 対象: この dotfiles リポジトリ（`~/.dotfiles`）

## 1. 概要

### 目的

- どの環境にも、余計な手間なく、確実に同じ環境を届ける
- 同じ flake から、Mac と Linux（Ubuntu / Debian）の環境を何度でも作れるようにする
- Nix 以外の仕組み（自作のリンク処理、スクリプト）を最小限にし、壊れたときに Nix の外を調べずに済むようにする

### 方針

- 設定はツールごとに `programs/<ツール>/` に置き、home-manager が読み取り専用で配る。Nix の基本のやり方（Nix store へのリンク）に従う
- 設定を変えたら `nix run .#switch` で反映する。変更は月に数回の想定なので、この手間は受け入れる
- アプリが書き込む状態（認証情報、履歴、キャッシュなど）は管理しない。リポジトリにも入れない
- Mac はフル構成、Linux は開発サーバーや開発環境向けの軽い構成にする
- 言語と開発ツールは mise に任せる。会社のプロジェクトが mise を使っているからだ

### 全体図

```
flake.nix
├── Mac:   nix-darwin（darwin.nix） ＋ home-manager（home.nix）
├── Linux: home-manager（home.nix ＋ linux.nix）
├── packages.switch（nix run .#switch）  nh で適用 → mise install
└── GitHub Actions                   評価、Mac の build、Ubuntu での通しの確認、週1回の更新 PR
```

### 何を何で管理するか

| 対象 | Mac | Linux |
|---|---|---|
| 基本の CLI | nixpkgs（home-manager） | 同じ |
| Mac だけの CLI | nixpkgs（nix-darwin） | 入れない |
| 言語と開発ツール | mise（宣言は home-manager） | 同じ。Mac だけのツールは入らない |
| Claude Code、Codex CLI | llm-agents.nix | 同じ |
| 設定ファイル | home-manager が読み取り専用で配る | 同じ |
| GUI アプリ | Homebrew の cask（nix-darwin から宣言） | 入れない |
| Docker | Docker Desktop（cask） | Docker Engine（install.sh が入れる。Nix の管理外） |
| OS の設定 | nix-darwin | 管理しない |
| アプリが書き込む状態 | 管理しない | 同じ |

## 2. 設計の原則

1. **設定は home-manager が読み取り専用で配る。** リポジトリへの直接リンクや、自分で書いたリンク処理は使わない。どの環境でも中身が同じになり、世代を戻せば中身も戻る
2. **アプリが書き込む状態は管理しない。** 認証情報、履歴、キャッシュ、Codex の `~/.codex/config.toml`、mise に手で足したツールがそうだ。どれもリポジトリの外に置かれる
3. **シェルの処理は `.zsh` ファイルのまま残す。** エイリアスや関数を Nix の書式に書き直しても、良くなる点がない。ファイルは store から読み込む
4. **OS とマシンの違いは Nix の中で決める。** 実行時に OS を判定しない。どの環境に何が入るかを `nix eval` で事前に確かめられ、CI でも検査できる
5. **ネットワークを使う処理は activation に置かない。** activation はオフラインでも成功させる。ネットワークが要る処理は `nix run .#switch` の後処理に置く。ただし Mac では、nix-darwin の Homebrew モジュールが activation の中で cask を取りにいく

## 3. リポジトリの構成

```
~/.dotfiles/
├── flake.nix / flake.lock
├── home.nix              # home-manager の入口（両方の OS で共通）。パッケージと imports
├── darwin.nix            # nix-darwin の入口（Mac だけ）
├── darwin/               # defaults.nix（macOS の設定）、homebrew.nix
├── linux.nix             # Linux だけの home-manager の設定
├── programs/
│   ├── zsh/              # default.nix と rc.d/*.zsh
│   ├── git/              # default.nix と hooks/pre-commit
│   ├── gh/  mise/
│   ├── agents/           # AGENTS.md と skills/（Claude と Codex で共有する原本）
│   ├── claude/           # default.nix、settings.json、CLAUDE.md、statusline.sh
│   ├── codex/            # default.nix、config.toml（宣言する設定）
│   ├── vscode/           # default.nix、settings.json、extensions（一覧）
│   ├── hammerspoon/      # default.nix と init.lua
│   └── bettertouchtool/  # プリセット（手で読み込む）
├── nix/switch.nix        # nix run .#switch
├── install.sh
└── .github/workflows/    # ci.yml、update-flake-lock.yml
```

## 4. 各部の設計

### 4.1 flake と Nix 本体

- 両方の OS で Determinate Nix を使う。Mac では Determinate の darwin モジュールで nix-darwin と組み合わせる（`determinateNix.enable = true`）
- 対象のシステムは `aarch64-darwin`、`x86_64-linux`、`aarch64-linux` の3つだ

| flake の入力 | 版 |
|---|---|
| nixpkgs | `nixpkgs-unstable` |
| nix-darwin、home-manager | master（nixpkgs は `follows` でそろえる） |
| nix-homebrew | flake.lock で固定 |
| llm-agents.nix | 最新。numtide のバイナリキャッシュを使う |
| determinate、nix-index-database | 最新 |
| ponytail、codex-plugin-cc | Claude Code のプラグイン。flake.lock で固定 |

- **ユーザー名とホームディレクトリ**: flake に書かず、`USER` と `HOME` から読む。そのため評価には常に `--impure` が要る（`nix run .#switch` と CI は付けている）。設定の名前は `darwinConfigurations.default` と `homeConfigurations.<system>` で、ユーザー名を含まない
- **numtide のキャッシュ**: flake の `nixConfig` には書かない（信頼されたユーザー以外では無視される）。install.sh が Nix のインストール時に渡す。Mac では、その後 `determinateNix.customSettings` が引き継ぐ。インストーラが書いた `/etc/nix/nix.custom.conf` は nix-darwin の管理とぶつかるので、install.sh が最初の switch の前に `.before-nix-darwin` へ退避する
- **その他**: GC は Determinate Nixd に任せる。フォーマッタは `nixfmt-tree`。stateVersion は `home.stateVersion = "26.05"`、`system.stateVersion = 7`

### 4.2 入口のコマンド（`nix run .#switch`）

1. OS を判定して、nh で適用する。適用するのは、このコマンドを実行した flake 自身だ。worktree で実行すればその内容が、`nix run github:...` なら GitHub の内容が適用される
   - Mac: `nh darwin switch --no-nom <flake> -H default -- --impure`
   - Linux: `nh home switch --no-nom <flake> -c <system> -b backup -- --impure`
   - nh は build をユーザーの権限で行い、`activate` だけを sudo で実行する。そのため、Mac の初回（`darwin-rebuild` がまだない状態）でもそのまま動く
2. `mise install` を実行する。`gh auth token` で値が取れれば、`MISE_GITHUB_TOKEN` に渡す
3. `mise install` が失敗すると、終了コード1で終える。最後の処理なので、構成の適用は済んでいる。install.sh は「Done」を出さずに止まる

### 4.3 Mac（`darwin.nix`）

- **macOS の設定**（旧 `setup-macos.sh`）: `darwin/defaults.nix` に書く。型付きのオプションがないものは `CustomUserPreferences`、root で書くものは `CustomSystemPreferences` を使う。LSQuarantine の無効化は `DOTFILES_DISABLE_QUARANTINE=1` を付けて switch したときだけ行う
- **Homebrew**: `darwin/homebrew.nix` に書く。nix-homebrew で Homebrew 本体の版を固定する。cask と、VS Code の拡張機能（`homebrew.vscode`。一覧は `programs/vscode/extensions`。VS Code を Homebrew で入れているときだけ）を宣言する。Homebrew の外ですでに入っているアプリ（会社の MDM、手で入れたもの）の cask は、評価のときに飛ばす（`--impure` で `/Applications` と Homebrew の Caskroom を見る）。そのアプリは、入れた側が管理と更新を続ける。`cleanup` は、最初の switch を確かめてから `"zap"` にする。brew bundle は activation の中で home-manager より先に走るので、失敗しても警告だけにして先へ進める
- **その他**: Touch ID で sudo を通す。Mac だけの CLI（emacs、shellcheck、watch、terminal-notifier、coreutils-prefixed）は `environment.systemPackages` で入れる。nix-darwin の zsh の既定の動きのうち `promptInit` と全員分の `compinit` は止める

### 4.4 Linux（`linux.nix` と `install.sh`）

- `targets.genericLinux.enable = true`。GPU の設定（`gpu.enable`）と systemd のユーザーサービス（`systemd.user.enable`）は止める
- Linux だけのパッケージは lsof。`programs.bash` も有効にして、chsh する前（ログインシェルが bash）でも PATH と環境変数をそろえる
- install.sh が、初回だけ sudo で次の作業を行う
  - `docker` がなく systemd が動いていれば、Docker Engine を入れる
- systemd のない環境（コンテナなど）は対象外にする（Determinate のインストーラが止まる）
- SSH の鍵は管理しない。サーバーから push するときは、Mac から SSH エージェントを転送する

### 4.5 シェル（`programs/zsh`）

- `programs.zsh` が `~/.zshenv` と `~/.config/zsh/.zshrc` を生成する
- 履歴は `~/.local/state/zsh/history` に10万件保存する。`*DATABASE_URL=*`、`*TOKEN=*` などは履歴に残さない
- エイリアスと関数は `rc.d/*.zsh` のまま、store から読み込む。Mac だけのファイル（`darwin.zsh`、`warp-code.zsh`）は、Mac の構成にだけ入れる
- 入力補完の候補表示、構文のハイライト、zoxide、direnv、mise、command-not-found は、home-manager のモジュールでつなぐ。fzf のキーバインドと starship だけは、Warp の中では読み込まないように `rc.d/plugins.zsh` に残す
- Mac では、PATH の末尾に Homebrew を足す。cask が置く `code` と `sbx` のためだ
- その環境だけの設定は `~/.config/zsh/.zshrc.local` に書けば読み込まれる（追跡しない）

### 4.6 開発ツールと言語

迷ったら、「どこかのプロジェクトで版を固定する可能性があるか」で決める。可能性があれば mise、なければ Nix に入れる。

| 管理するもの | 中身 |
|---|---|
| Nix（両方の OS） | git、gh、ghq、fzf、ripgrep、fd、bat、eza、jq、zoxide、direnv、lazygit、starship、vim、git-secrets、htmlq、comma、mise |
| Nix（Mac だけ） | emacs、htmlq、shellcheck、watch、terminal-notifier、coreutils-prefixed |
| mise（両方の OS） | node、python、uv、go、pnpm、terraform、kubectl、kind、skaffold、golangci-lint、sqlc、buf、task、lefthook、golang-migrate、gopls、codebase-memory-mcp |
| mise（Mac だけ） | gcloud、bun、deno、ni、rust、sops |

- mise の宣言は `programs.mise.globalConfig` に書く。`~/.config/mise/conf.d/` に読み取り専用で生成される。`mise use -g` で手で足したものは、書き込める `~/.config/mise/config.toml` に入る（追跡しない）
- codebase-memory-mcp は npm のパッケージで、インストール後スクリプトで本体を取得する。そのため、このパッケージだけ `allow_builds` で許可する
- mise の shims を PATH に入れて、GUI から起動したアプリや非対話シェルからも見えるようにする
- 言語の更新は `mise upgrade` で行う

### 4.7 Claude Code と Codex

**Claude Code**（`programs/claude`）

| 対象 | 扱い |
|---|---|
| 本体 | llm-agents.nix。版は flake.lock で固定。自動更新は止まっている |
| `~/.claude/settings.json` | `settings.json` を読み取り専用で配る。禁止ルールもここに書く。禁止ルールは事故を防ぐためのもので、権限の境界ではない（ファイルは利用者のホームにある symlink なので、普通の `rm` で置き換えられる） |
| `~/.claude/CLAUDE.md` | `programs/agents/AGENTS.md` と `programs/claude/CLAUDE.md`（Claude だけの補足）をつなげて配る |
| skills | `programs/agents/skills/` の skill ごとにリンクする。`synced` など、Claude が自分で置くものとは共存する |
| プラグイン | ponytail と codex。flake の入力で版を固定し、個人プラグインとして読み込む |
| MCP | codebase-memory-mcp。home-manager が生成するプラグインに入る |
| ログイン状態、プロジェクトの履歴など | 管理しない（`~/.claude.json`、`~/.claude/projects/` など） |

**Codex**（`programs/codex`）

| 対象 | 扱い |
|---|---|
| 本体 | CLI は llm-agents.nix。Codex.app（Mac）は cask で、自分専用の codex を内蔵するので CLI とは版が別になる。どちらも `~/.codex` の設定を読む |
| `~/.codex/AGENTS.md`、skills | `programs/agents` から配る。Codex は symlink の AGENTS.md も、skill のディレクトリの symlink も読む（ソースで確認） |
| 共通の設定 | `programs/codex/config.toml` に宣言する。home-manager の `mutableSettings` が、switch のたびに `~/.codex/config.toml` へ合成する |
| `~/.codex/config.toml` | 書き込めるファイルのまま残し、追跡しない。Codex が書く trust や端末固有のパスは残る。宣言したキーは宣言の値に戻る |

### 4.8 git、gh、VS Code、Hammerspoon

- **git**: `programs.git` で設定する。`~/Repository/` の下では `~/.gitconfig.local` を読む。このリポジトリでは（clone の場所によらず remote の URL で判定する）noreply のアドレスを使い、pre-commit（git-secrets）を有効にし、`~/.gitconfig.local` の名前とメールアドレスを禁止パターンにする（provider で毎回読む）
- **gh**: `programs.gh` で設定する。認証情報（`hosts.yml`）は gh が自分で書く
- **VS Code**: 本体は cask。`settings.json` は読み取り専用で配る（設定画面からは保存できない）。拡張機能は一覧ファイルを Homebrew（brew bundle）が入れる。取得に失敗すると switch が止まる。画面から入れたら `codeexport` で一覧に書き出す。nixpkgs にない拡張機能が多いので、Nix のパッケージとしては管理しない
- **Hammerspoon**: `~/.hammerspoon/init.lua` を配る（Mac だけ）
- **BetterTouchTool**: プリセットはリポジトリに置き、読み込みは手作業で行う

### 4.9 CI と更新

GitHub Actions で次の4つを行う。

1. `nix flake check --all-systems --no-build`（全部の構成を評価する）と `nix fmt -- --ci`
2. Mac の2つの構成を macOS のランナーで build する（`--impure`、ランナーのユーザー）
3. Ubuntu のランナーで、一般ユーザーとして install.sh から `nix run .#switch` まで通しで実行し、配置されたものを確かめる
4. 週1回、`update-flake-lock` で更新の PR を作る

## 5. インストール前後の手作業

`docs/additional-setup.md` にまとめてある。

- **Mac（最初の switch の前）**: Command Line Tools
- **両方の OS（switch の後）**: `~/.gitconfig.local`（任意）、`gh auth login`、`claude` と `codex` へのログイン
- **Mac（switch の後）**: `sbx login`、Hammerspoon と Warp のアクセシビリティの許可、Docker Desktop の初回起動、BTT のプリセットの読み込み、`cleanup = "zap"` への切り替え
- **Linux（switch の後）**: SSH エージェントの転送、`docker` グループの反映のための再ログイン、必要なら zsh をログインシェルにする

## 6. Mac の切り替え（手動で実行する）

今の Mac は、`~/.config`、`~/.claude`、`~/.codex` がリポジトリの中を指している。新しい構成では、これらは普通のディレクトリになる。そのため、切り替えでは実行時のデータ（約2.3GB）をリポジトリの外へ移す。

Claude Code と Codex を終了させてから、素のターミナルで行う。

1. **退避**: `cp -a ~/.dotfiles ~/dotfiles.backup`
2. **準備**: podman を使っていれば `podman machine stop` と `podman machine rm` を実行する
3. **まだコミットしていない変更を退避する**: `git -C ~/.dotfiles stash -u`。次の手順で `config/` を動かす前に行う。後で行うと、`config/` の削除まで stash に入ってしまう
4. **設定をリポジトリから切り離す**
   ```sh
   rm ~/.config && mv ~/.dotfiles/config ~/.config      # ~/.config を普通のディレクトリに
   rm ~/.claude && mv ~/.config/claude ~/.claude        # Claude の状態を ~/.claude へ
   rm ~/.codex  && mv ~/.config/codex  ~/.codex         # Codex の状態を ~/.codex へ
   rm ~/.zshenv ~/.hammerspoon                          # home-manager が作り直す
   rm ~/.config/mise/config.toml                        # 旧構成の宣言。home-manager の conf.d と重なる
   find ~/.claude/skills ~/.codex/skills -maxdepth 1 -type l -delete   # 旧構成の skill のリンク（移すと壊れ、switch が止まる）
   ```
5. **ブランチを取り込む**: PR #4 をマージし、`git -C ~/.dotfiles pull --ff-only` で取り込む。そのあと、古い構成が `.git/config` に書いた設定を消す。残すと、新しい pre-commit（git-secrets）が動かない
   ```sh
   git -C ~/.dotfiles config --unset core.hooksPath
   git -C ~/.dotfiles config --remove-section filter.codex-config
   ```
6. **古いものを片づける**: `codebase-memory-mcp uninstall` を実行する。Homebrew の `codex` cask（旧構成の Codex CLI）を `brew uninstall --cask codex` で消す。CLI は Nix で入れ、Codex.app は自分専用の codex を内蔵している。ネイティブインストーラで入れた Claude Code（`~/.local/bin/claude` と `~/.local/share/claude`）を消す。消さないと、PATH の先頭にあるこちらが Nix の版より優先されてしまう
7. **入れて適用する**: `sh ~/.dotfiles/install.sh` を実行する。Determinate Nix を numtide のキャッシュ付きで入れ、インストーラが作った `/etc/nix/nix.custom.conf` を nix-darwin のために退避してから、`nix run .#switch` を実行する（`~/.dotfiles` はあるので clone はしない）。すでにあるファイル（`~/.config/zsh/.zshrc` など）は、home-manager が `.backup` を付けて退避してからリンクを張る
8. **履歴を移す**: 同じターミナルで、秘密情報らしい行を除いて新しい履歴ファイルに足す。終わったらこのターミナルを閉じる（開いたままだと古いファイルに書き続ける）
   ```sh
   mkdir -p ~/.local/state/zsh
   LC_ALL=C grep -a -v -i -E 'token[^ ]*=|secret|passw|api_key|private_key|access_key|database_url=|authorization:|bearer |://[^ /]*:[^ /]*@' \
     ~/.config/zsh/.zsh_history >> ~/.local/state/zsh/history && rm ~/.config/zsh/.zsh_history
   ```
9. **確かめる**: 新しいターミナルで、7章の「変わらないこと」を確かめる。そのあと、podman と graphify を消し、Homebrew の `cleanup` を `"zap"` にして、もう一度 switch する

**元に戻すとき**: 世代は `sudo darwin-rebuild --rollback` で戻せる。Nix ごと消すときは、先に nix-darwin のアンインストーラ、次に Determinate のアンインストーラの順で実行し、退避した `~/dotfiles.backup` とリンクを戻す。Homebrew で入れたものと、手で移したデータは、世代を戻しても元に戻らない。

nix-darwin が、`nix.custom.conf` 以外のファイル（`/etc/zshrc` など）で「Unexpected files in /etc」と表示して止まった場合は、表示されたファイル名の末尾に `.before-nix-darwin` を付けてからやり直す。

## 7. 現在の構成から変わること

| 今 | これから |
|---|---|
| Mac だけ | Mac（フル構成）と Linux（軽い構成） |
| `~/.config` がリポジトリそのもの（2.3GB、認証情報を含む） | 普通のディレクトリ。リポジトリには自分で書いた設定だけが入る |
| 設定ファイルをその場で編集すれば反映される | リポジトリを編集して `nix run .#switch` で反映する |
| bootstrap スクリプトが10本、Brewfile | `install.sh` と `nix run .#switch` |
| Claude の `/model`、`/config`、`/plugin` の変更が保存される | そのセッション限り。残すなら `programs/claude/settings.json` を編集する |
| Claude Code はネイティブインストーラで自動更新 | Nix で版を固定。更新は flake の更新で行う |
| Claude のプラグインは marketplace から入れる | flake の入力で版を固定する |
| VS Code の設定画面で変えた値が保存される | 保存されない。`programs/vscode/settings.json` を編集する |
| Codex の `config.toml` を sanitizer と clean filter で整えて追跡 | 共通の設定は `programs/codex/config.toml` に宣言し、switch で手元のファイルへ合成する。手元のファイルは追跡しない |
| mise と brew の両方に同じ言語 | 言語は mise だけ。宣言は Nix に書く |
| podman | Docker Desktop（Mac）と Docker Engine（Linux） |
| `DOTFILES_SKIP_CASKS`（制限付きの Mac 向け） | 構成は1つ。Homebrew の外ですでに入っているアプリの cask は自動で飛ばす |
| `compete`、`drive`、`lzd`、graphify | 削除する |

**変わらないこと**: エイリアスと関数、mise での言語管理と `mise use -g`、会社のプロジェクトの `mise.toml`、`sbxc`、Codex の trust、英数/かなの切り替え、Warp での表示、BetterTouchTool、`brew tap`

## 8. 注意すること

### 8.1 まだ確かめていないこと

CI では、Linux で install.sh から switch まで通し、配置されたものを確かめている。次のものは、Mac での最初の switch で確かめる。

| 確かめること | 確かめられなかった場合 |
|---|---|
| Mac での最初の switch が通るか（Homebrew の引き継ぎ、defaults、`/etc`） | 表示に従って直す。6章の「元に戻すとき」で戻せる |
| flake で固定したプラグイン（ponytail のフックを含む）が動くか | marketplace から入れる方式に戻す |
| codebase-memory-mcp が Mac で署名の問題なく起動し、Claude と Codex につながるか | 公式の `install.sh --skip-config` に切り替える |
| Codex.app から起動したときも、`codebase-memory-mcp` を名前だけで見つけられるか（Dock から起動したアプリには、mise の shims が PATH に入らない） | このコマンドのパスだけ、Nix で組み立てる |
| `nix.custom.conf` を退避した後も、最初の build で numtide のキャッシュが効くか | 遅いだけで、失敗はしない |
| VS Code が読み取り専用の `settings.json` で問題なく動くか | 設定ファイルの管理を外す |
| nixpkgs の `watch` が Mac で brew 版と同じように動くか | brew の `watch` に戻す |
| sbx の sandbox の中で kind が動くか | sandbox の中では kind を使わない |

### 8.2 承知しておくこと

- 設定を変えたら、`nix run .#switch` を実行しないと反映されない
- Claude Code と Codex の版は flake.lock で決まる。急いで上げたいときは `nix flake update llm-agents` を実行する
- mise のツールは `latest` なので、作るたびに同じ版になるとは限らない
- 禁止ルールを書いた `settings.json` は読み取り専用だが、Claude が symlink ごと消して置き換えることまでは防げない（`rm -rf` は禁止しているが、`rm` は禁止していない）
- `programs/codex/config.toml` に宣言したキーは、switch のたびに宣言の値に戻る。Codex の画面で変えた model なども戻る
- brew bundle が失敗しても、switch は警告を出して先に進む（home-manager の設定は入る）。cask が入ったかは switch の出力で確かめる
- Dock の設定（`persistent-apps = []` を含む）は switch のたびに適用され、Dock が再起動される。手で固定したアプリは外れる
- `docker` グループのユーザーは、実質的に root と同じことができる
- Homebrew の `autoUpdate` と `upgrade` を有効にしているので、switch のたびに Homebrew の更新と cask の入れ替えが走る。設定を1行直すだけでも数分かかることがあり、起動中のアプリが入れ替わることもある
- `cleanup` を `"zap"` にすると、`programs/vscode/extensions` にない VS Code の拡張機能も消される可能性がある（未確認）。画面から入れたものは、switch の前に `codeexport` で一覧に書き出す
- Homebrew の外で入れたアプリは cask で管理しない。そのアプリを消すと、次の switch で cask として入る
- `cleanup` を `"zap"` にすると、宣言していない cask は消される。今の Mac では Zed、Spotify、Podman Desktop が対象になる
- nix-homebrew は Homebrew 本体の版を固定している。最初の switch で、今の Homebrew がその版に置き換わる
- 週1回の更新 PR には、リポジトリの設定「Allow GitHub Actions to create and approve pull requests」の有効化が必要。GitHub Actions が作った PR では、CI は自動では動かない

## 9. 判断の記録

| 判断 | 理由 | 検討して採らなかった案 |
|---|---|---|
| Nix の基本のやり方（store へのリンク）に従う | 確実に同じ環境を届けることを優先する。自作のリンク処理は、環境差やリンク切れの調べ方が Nix の外になる | `~/.config` をリポジトリに丸ごとリンクする（v11〜v16）。リポジトリへの直接リンク |
| アプリの画面からの設定変更はあきらめる | 設定の変更は月に数回で、Nix に書いて switch すれば足りる | 書き込めるリンクにする |
| ツールごとに `programs/<ツール>/` に分ける | どこを直せばよいかがすぐ分かる | 層ごと（home / darwin）に分ける |
| OS の違いは Nix で決める | 何が入るかを事前に評価でき、CI で検査できる | 実行時に `$OSTYPE` で判定する |
| nix-darwin を使う | Homebrew の cask、Touch ID、root の defaults、`/etc` は home-manager では扱えない | home-manager だけにする |
| ユーザー名とホームは環境から読む（`--impure`） | マシンやサーバーでユーザー名が違うことがある | マシンごとのファイルに書く |
| `nix run .#switch` は常に nh を使う | build はユーザーの権限、`activate` だけ sudo。Mac の初回でも分岐が要らない | 初回だけ `sudo nix run nix-darwin` |
| Determinate Nix を使う | macOS のアップデートに強い。インストーラが Determinate Nix しか入れない | upstream の Nix |
| nixpkgs は `nixpkgs-unstable` | 更新の速さを、mise の `latest` に近づける | 安定版 |
| GUI アプリは Homebrew の cask | nixpkgs では古いか、署名がないか、そもそもない | nixpkgs と mac-app-util |
| 言語は mise に任せる | 会社のプロジェクトが mise を使う | nixpkgs、uv、rustup |
| Claude Code と Codex は llm-agents.nix で入れる | どの環境でも同じ版になる | ネイティブインストーラ、cask |
| Claude のプラグインは flake で版を固定する | どの環境でも同じものが入る | marketplace から入れる |
| 禁止ルールは読み取り専用の `settings.json` に書く | 両方の OS で同じ仕組みになる | 管理設定（`/Library`、`/etc`） |
| Codex の共通設定は `programs.codex.settings` と `mutableSettings` で手元の `config.toml` に合成する | Codex が書く trust を残したまま、宣言した値をそろえられる。sudo も `/etc` も要らない | `/etc/codex/config.toml`（Linux では sudo のリンクが要り、root が利用者の書けるファイルを読む） |
| VS Code の拡張機能は一覧ファイルから入れる | nixpkgs にない拡張機能が多く、Nix で管理するには入力と VS Code 本体の入れ替えが要る | `programs.vscode` |
| Mac の構成は1つ | Homebrew の外ですでに入っているアプリを評価のときに飛ばすので、会社の Mac（MDM が入れるアプリがある）でも同じ構成で済む | `default` と `minimal` の2つ |
| Warp の設定は管理しない | Warp のアカウントの同期でそろっている。公開したくない識別子も含まれていた | リポジトリで管理する |
| system-manager は使わない | Determinate との組み合わせが保証されていない。`/etc` に置くのは1ファイルだけ | system-manager |
| systemd のない Linux は対象外 | 一般ユーザーが Nix を使えない | `--init none` で root で使う |
| Docker に統一する | 互換性を気にしなくて済む | podman、Colima |

## 10. 参考

- [nix-darwin](https://github.com/nix-darwin/nix-darwin)
- [home-manager](https://github.com/nix-community/home-manager)
- [Use Determinate with nix-darwin](https://docs.determinate.systems/guides/nix-darwin/)
- [Determinate Nixd（自動 GC）](https://docs.determinate.systems/determinate-nix/determinate-nixd)
- [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer)
- [DeterminateSystems/determinate-nix-action](https://github.com/DeterminateSystems/determinate-nix-action)
- [zhaofengli/nix-homebrew](https://github.com/zhaofengli/nix-homebrew)
- [nix-community/nh](https://github.com/nix-community/nh)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)
- [Claude Code: Settings files and precedence](https://code.claude.com/docs/en/settings)
- [Claude Code: Skills](https://code.claude.com/docs/en/skills)
- [Codex config loader README](https://github.com/openai/codex/blob/main/codex-rs/config/src/loader/README.md)
- [mise: npm backend（lifecycle scripts）](https://mise.jdx.dev/dev-tools/backends/npm.html)
- [DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)
- [ebina4yaka/dotfiles.nix](https://github.com/ebina4yaka/dotfiles.nix)（ツールごとのディレクトリ構成の参考）
