# Sets reasonable macOS defaults.
#
# Or, in other words, set shit how I like in macOS.
#
# The original idea (and a couple settings) were grabbed from:
#   https://github.com/mathiasbynens/dotfiles/blob/master/.macos
#
# Visit https://macos-defaults.com/ for all possibilities
#
# Run ./set-defaults.sh and you'll be good to go.

# Disable press-and-hold for keys in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Always open everything in Finder's list view. This is important.
defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"

# Show the ~/Library folder.
chflags nohidden ~/Library

# Set a really fast key repeat.
defaults write NSGlobalDomain KeyRepeat -int 1

# Finder
defaults write com.apple.finder "ShowExternalHardDrivesOnDesktop" -bool true
defaults write com.apple.finder "ShowRemovableMediaOnDesktop" -bool true
defaults write com.apple.finder "AppleShowAllFiles" -bool true
defaults write com.apple.finder "ShowPathbar" -bool true
defaults write com.apple.finder "_FXSortFoldersFirst" -bool true
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"
defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"

# Run the screensaver if we're in the bottom-left hot corner.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# Hide Safari's bookmark bar.
defaults write com.apple.Safari.plist ShowFavoritesBar -bool false

# Set up Safari for development.
defaults write com.apple.Safari.SandboxBroker ShowDevelopMenu -bool true
defaults write com.apple.Safari.plist IncludeDevelopMenu -bool true
defaults write com.apple.Safari.plist WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari.plist "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Dock config
defaults write com.apple.dock "tilesize" -int "40"
defaults write com.apple.dock "autohide" -bool "true"
defaults write com.apple.dock "autohide-time-modifier" -float "0.2"
defaults write com.apple.dock "autohide-delay" -float "0.1"
defaults write com.apple.dock "show-recents" -bool "false"

# Time machine
defaults write com.apple.TimeMachine "DoNotOfferNewDisksForBackup" -bool "true"

# TextEdit
defaults write com.apple.TextEdit "RichText" -bool "false"

# MissionControll
defaults write com.apple.dock "expose-group-apps" -bool "true"

# Set right click
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse "MouseButtonMode" -string "TwoButton"
defaults write com.apple.driver.AppleHIDMouse "MouseButtonMode" -string "TwoButton"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadCornerSecondaryClick" -int "2"
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad "TrackpadRightClick" -int "0"
defaults write com.apple.AppleMultitouchTrackpad "TrackpadCornerSecondaryClick" -int "2"
defaults write com.apple.AppleMultitouchTrackpad "TrackpadRightClick" -int "0"

# Disable Siri in the menu bar
defaults write com.apple.Siri StatusMenuVisible -int 0
