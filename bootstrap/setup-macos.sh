#!/usr/bin/env zsh

echo "--------------------------------"
echo "⏳ Setting up macOS..."
echo "--------------------------------"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'


# -----------------
# System General
# -----------------

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Reveal IP address, hostname, OS version, etc. when clicking the clock in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.1

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string none

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Set sidebar icon size to small
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

# Set the timezone
sudo systemsetup -settimezone Asia/Tokyo > /dev/null



# -----------------
# Dock
# -----------------

# Set the dock size
defaults write com.apple.dock tilesize -int 38

# Set the dock scaling size
defaults write com.apple.dock largesize -int 58

# Set the dock auto hide
defaults write com.apple.dock autohide -int 1

# Set the dock position
defaults write com.apple.dock orientation -string left

# Disabled the dock magnification
defaults write com.apple.dock magnification -int 0

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -int 1

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -int 0

# Set the hot corner
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 5
defaults write com.apple.dock wvous-br-modifier -int 0

# -----------------
# Trackpad
# -----------------

# Enable tap to click for this user and for the login screen
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Set the trackpad scaling
defaults write -g com.apple.trackpad.scaling -int 2.5

# Set the trackpad click threshold
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

# Set the trackpad swipe actions
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0


# Set the trackpad click power 
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0

# Set the trackpad gesture
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0 # Disable three finger swipe down because it's used for BTT


# -----------------
# Screen
# -----------------

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -boolean true

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# -----------------
# Finder
# -----------------

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# -----------------
# Safari & WebKit
# -----------------

# Privacy: don’t send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

echo "--------------------------------"
echo "✅ All macOS setup is complete!"
echo "--------------------------------"