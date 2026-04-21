#!/usr/bin/env zsh
# NOTE: set -e is intentionally omitted.
# This is a non-critical step — individual preference writes may fail
# (e.g., SIP restrictions, missing plist domains) without affecting the rest.

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# -----------------
# System General
# -----------------
_log_run "Configuring system general..."

sudo nvram SystemAudioVolume=" "
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
defaults write NSGlobalDomain NSWindowResizeTime -float 0.1
defaults write com.apple.LaunchServices LSQuarantine -bool false
defaults write com.apple.CrashReporter DialogType -string none
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1
sudo systemsetup -settimezone Asia/Tokyo > /dev/null

_log_ok "System general configured."

# -----------------
# Dock
# -----------------
_log_run "Configuring Dock..."

defaults write com.apple.dock tilesize -int 38
defaults write com.apple.dock largesize -int 58
defaults write com.apple.dock autohide -int 1
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock magnification -int 0
defaults write com.apple.dock show-process-indicators -int 1
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock show-recents -int 0
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 5
defaults write com.apple.dock wvous-br-modifier -int 0

_log_ok "Dock configured."

# -----------------
# Trackpad
# -----------------
_log_run "Configuring Trackpad..."

defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write -g com.apple.trackpad.scaling -int 2.5
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0

_log_ok "Trackpad configured."

# -----------------
# Screen
# -----------------
_log_run "Configuring Screen..."

defaults write com.apple.screencapture disable-shadow -boolean true
defaults write com.apple.screencapture type -string "png"

_log_ok "Screen configured."

# -----------------
# Finder
# -----------------
_log_run "Configuring Finder..."

defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true

_log_ok "Finder configured."

# -----------------
# Safari & WebKit
# -----------------
_log_run "Configuring Safari..."

defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

_log_ok "Safari configured."

# -----------------
# Apply changes
# -----------------
_log_run "Applying changes..."
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
_log_ok "macOS preferences applied."
