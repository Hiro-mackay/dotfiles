# macOS preferences (formerly bootstrap/setup-macos.sh).
{ lib, ... }:
let
  # Opt-in, as before: weakens Gatekeeper. Read at evaluation time (needs --impure).
  disableQuarantine = builtins.getEnv "DOTFILES_DISABLE_QUARANTINE" == "1";
in
{
  system.defaults = {
    NSGlobalDomain = {
      NSWindowResizeTime = 0.1;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSTableViewDefaultSizeMode = 1;
      AppleEnableSwipeNavigateWithScrolls = false;
      "com.apple.trackpad.scaling" = 2.5;
      "com.apple.keyboard.fnState" = true;
    };

    dock = {
      tilesize = 39;
      largesize = 58;
      autohide = true;
      orientation = "left";
      magnification = false;
      show-process-indicators = true;
      persistent-apps = [ ];
      show-recents = false;
      wvous-bl-corner = 10;
      wvous-br-corner = 5;
    };

    trackpad = {
      Clicking = true;
      FirstClickThreshold = 0;
      SecondClickThreshold = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadThreeFingerTapGesture = 0;
    };

    screencapture = {
      disable-shadow = true;
      type = "png";
    };

    finder = {
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
    };

    LaunchServices.LSQuarantine = lib.mkIf disableQuarantine false;

    # Keys without a typed nix-darwin option, written as-is.
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleKeyboardUIMode = 1;
        "com.apple.scrollwheel.scaling" = 1.7;
      };
      "com.apple.dock" = {
        wvous-bl-modifier = 0;
        wvous-br-modifier = 0;
        showAppExposeGestureEnabled = false;
      };
      "com.apple.finder".WarnOnEmptyTrash = false;
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.CrashReporter".DialogType = "none";
      "com.apple.systempreferences".NSQuitAlwaysKeepsWindows = false;
    };

    CustomSystemPreferences."/Library/Preferences/com.apple.loginwindow".AdminHostInfo = "HostName";
  };
}
