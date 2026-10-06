# VS Code itself is a Homebrew cask. settings.json is read-only (the Settings UI cannot
# save); extensions in ./extensions are installed by Homebrew (darwin/homebrew.nix).
{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file."Library/Application Support/Code/User/settings.json".source = ./settings.json;
}
