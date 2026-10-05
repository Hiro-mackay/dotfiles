{
  programs.gh = {
    enable = true;
    # Keep git's own credential handling; gh is not set up as a credential helper.
    gitCredentialHelper.enable = false;
    settings = {
      git_protocol = "ssh";
      aliases.co = "pr checkout";
    };
  };
}
