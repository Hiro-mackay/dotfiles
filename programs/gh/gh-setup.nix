# gh-setup, built for the home profile (gh and git from PATH, so its test can swap in
# fakes) or, with runtimeInputs, for install.sh to run before anything is installed.
{
  pkgs,
  runtimeInputs ? [ ],
}:
pkgs.writeShellApplication {
  name = "gh-setup";
  inherit runtimeInputs;
  text = ''
    base_default=${import ../git/base-login.nix}
  ''
  + builtins.readFile ./gh-setup.sh;
}
