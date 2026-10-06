{ pkgs, ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases.co = "pr checkout";
    };
  };

  # gh-account: a GitHub account's SSH key and the git settings that use it.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gh-account";
      text = builtins.readFile ./gh-account.sh;
    })
  ];
}
