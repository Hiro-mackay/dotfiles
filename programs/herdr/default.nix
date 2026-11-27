# herdr (terminal multiplexer for coding agents). The binary is a Homebrew formula
# (darwin/homebrew.nix); the config and the scripts its keys run are managed here.
# The scripts are on PATH too: herdr-claude-sync is started outside herdr.
{ pkgs, ... }:
let
  scripts = pkgs.runCommandLocal "herdr-scripts" { nativeBuildInputs = [ pkgs.ncurses ]; } ''
    mkdir -p $out/share/terminfo
    cp -r ${./bin} $out/bin
    chmod u+w $out/bin/herdr-diff-view
    # macOS's /usr/bin/python3 is a stub that asks to install the Xcode tools.
    substituteInPlace $out/bin/herdr-diff-view \
      --replace-fail "#!/usr/bin/env python3" "#!${pkgs.python3}/bin/python3"
    # herdr-diff-view looks for its terminfo entry in ../share/terminfo.
    tic -x -o $out/share/terminfo ${./terminfo/noscroll.src}
  '';
in
{
  home.packages = [ scripts ];
  xdg.configFile."herdr/config.toml" = {
    text = builtins.replaceStrings [ "@bin@" ] [ "${scripts}/bin" ] (builtins.readFile ./config.toml);
    # A running server keeps the config it started with, so its keys would go on running the
    # previous generation's scripts. Activation's PATH has no herdr: it is Homebrew's on the Mac
    # and the installer's in ~/.local/bin elsewhere. With no server running this fails, harmlessly.
    onChange = ''
      for herdr in "$HOME/.local/bin/herdr" /opt/homebrew/bin/herdr; do
        if [[ -x $herdr ]]; then
          run "$herdr" server reload-config >/dev/null 2>&1 || true
          break
        fi
      done
    '';
  };
}
