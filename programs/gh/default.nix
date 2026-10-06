{ pkgs, ... }:
let
  # gh that uses the GitHub account set for the current repository (gh-wrapper.sh).
  gh = pkgs.symlinkJoin {
    name = "gh-${pkgs.gh.version}";
    inherit (pkgs.gh) version;
    paths = [ pkgs.gh ];
    postBuild = ''
      rm $out/bin/gh
      substitute ${./gh-wrapper.sh} $out/bin/gh --subst-var-by gh ${pkgs.gh}/bin/gh
      chmod +x $out/bin/gh
    '';
  };
in
{
  programs.gh = {
    enable = true;
    package = gh;
    settings = {
      git_protocol = "ssh";
      aliases.co = "pr checkout";
    };
  };

  # gh-setup: a GitHub account's SSH key and the git settings that use it.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gh-setup";
      text = builtins.readFile ./gh-setup.sh;
    })
  ];
}
