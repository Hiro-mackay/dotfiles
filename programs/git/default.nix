{ pkgs, ... }:
let
  # git-secrets provider for this repo: the machine-local identity (never tracked)
  # becomes a prohibited pattern at scan time, so it can never be committed here.
  localIdentityPatterns = pkgs.writeShellScript "gitconfig-local-patterns" ''
    file="$HOME/.gitconfig.local"
    [ -f "$file" ] || exit 0
    for key in user.name user.email; do
      ${pkgs.git}/bin/git config -f "$file" "$key" || true
    done | ${pkgs.gnused}/bin/sed 's/[][\\.*^$+?(){}|]/\\&/g'
  '';
  identity = {
    name = "mackay";
    email = "43330841+Hiro-mackay@users.noreply.github.com";
  };
in
{
  programs.git = {
    enable = true;
    settings = {
      user = identity;
      core = {
        editor = "vim";
        quotepath = false;
      };
      init.defaultBranch = "main";
      fetch.prune = true;
      pull.rebase = true;
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      ghq.root = "~/Repository";
    };

    ignores = [
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      ".AppleDB"
      ".AppleDesktop"
      "Network Trash Folder"
      "Temporary Items"
      ".apdisk"
      "**/.claude/settings.local.json"
      "**/.claude/.cc-writes/"
    ];

    includes = [
      # Per-directory identity for repos under the ghq root; the file stays on the machine.
      {
        condition = "gitdir:~/Repository/";
        path = "~/.gitconfig.local";
      }
    ]
    # This public repo wherever it is cloned (matched by remote URL, listed after the
    # include above so it wins): the noreply identity, and the pre-commit hook
    # (git-secrets) with the identity patterns above.
    ++
      map
        (url: {
          condition = "hasconfig:remote.*.url:${url}";
          contents = {
            user = identity;
            core.hooksPath = "programs/git/hooks";
            secrets.providers = "${localIdentityPatterns}";
          };
        })
        [
          "https://github.com/Hiro-mackay/dotfiles*"
          "git@github.com:Hiro-mackay/dotfiles*"
        ];
  };

  home.packages = [ pkgs.git-secrets ];
}
