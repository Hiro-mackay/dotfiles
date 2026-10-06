{ lib, pkgs, ... }:
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
  };

  # gh writes config.yml itself (on login, for instance), so it stays a regular file;
  # each switch sets these values in it instead of linking a read-only copy.
  xdg.configFile."gh/config.yml".enable = false;
  home.activation.ghConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.gh}/bin/gh config set git_protocol https
    run ${pkgs.gh}/bin/gh alias set --clobber co 'pr checkout' >/dev/null
  '';

  # gh-setup: sign in to a GitHub account and tie it to its owners' repositories.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "gh-setup";
      text = builtins.readFile ./gh-setup.sh;
    })
  ];
}
