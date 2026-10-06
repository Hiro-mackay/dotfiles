# 英数/かな on left/right ⌘ (Hammerspoon itself is a Homebrew cask).
{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  home.file.".hammerspoon/init.lua".source = ./init.lua;
}
