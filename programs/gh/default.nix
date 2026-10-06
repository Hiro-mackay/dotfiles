{ pkgs, ... }:
let
  # gh that uses the GitHub account set for the current repository (gh-wrapper.sh).
  gh = pkgs.symlinkJoin {
    name = "gh-${pkgs.gh.version}";
    inherit (pkgs.gh) version;
    meta.mainProgram = "gh";
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
    # git's credential helper is set per account in programs/git and gh-setup.
    gitCredentialHelper.enable = false;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };

  # gh-setup: sign in to a GitHub account and tie it to its owners' repositories.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gh-setup";
      text = builtins.readFile ./gh-setup.sh;
    })
  ];
}
