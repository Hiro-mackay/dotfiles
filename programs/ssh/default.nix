# ssh-setup: an interactive command that adds a host to ~/.ssh/config and creates its
# key. ~/.ssh/config itself stays unmanaged, so hosts and keys never enter this repo.
{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "ssh-setup";
      text = builtins.readFile ./ssh-setup.sh;
    })
  ];
}
