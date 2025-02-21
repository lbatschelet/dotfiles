#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Fully automated Xcode and iOS Simulator installation script with cleanup.
#
# Features:
#  - Ensures 'xcodes' is installed.
#  - Checks if an Apple ID is logged in; if not, prompts login.
#  - Checks if Xcode is already installed and up to date before downloading.
#  - Installs the latest Xcode version if needed.
#  - Removes old Xcode versions after installing a new one.
#  - Installs the latest iOS Simulator runtime if not already installed.
#  - Removes outdated iOS Simulator runtimes.
#  - Includes colored INFO, WARN, and ERROR messages.
#  - Robust error handling and cleanup.
#
# Designed to be used in a dotfiles setup without manual intervention.
################################################################################

# Colors for messages
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"    # Bold Blue
COLOR_WARN="\033[1;33m"    # Bold Yellow
COLOR_ERROR="\033[1;31m"   # Bold Red

info_msg()  { echo -e "${COLOR_INFO}[INFO] $*${COLOR_RESET}"; }
warn_msg()  { echo -e "${COLOR_WARN}[WARN] $*${COLOR_RESET}"; }
error_msg() { echo -e "${COLOR_ERROR}[ERROR] $*${COLOR_RESET}"; exit 1; }

# Ensure 'xcodes' CLI is installed
if ! command -v xcodes &>/dev/null; then
  info_msg "Installing 'xcodes' CLI..."
  brew install xcodes
fi

# Check if an Apple ID is logged in
if ! xcodes account &>/dev/null; then
  info_msg "No Apple Developer account found. Logging in..."
  if ! xcodes auth; then
    error_msg "Apple ID login failed. Ensure you have an active Apple Developer account and have accepted the latest terms at https://developer.apple.com/account."
  fi
else
  info_msg "Apple Developer account already logged in."
fi

# Ensure latest Xcode version is known
LATEST_XCODE=$(xcodes list --latest)
if [[ -z "$LATEST_XCODE" ]]; then
  error_msg "Failed to fetch latest Xcode version. Check your network connection or xcodes installation."
fi

# Check if Xcode is installed and up to date
INSTALLED_XCODE=$(xcodes installed | grep -Eo '^[0-9]+\.[0-9]+(\.[0-9]+)?' | tail -n1)

if [[ "$INSTALLED_XCODE" == "$LATEST_XCODE" ]]; then
  info_msg "Latest Xcode ($LATEST_XCODE) is already installed. Skipping installation."
else
  info_msg "Installing latest Xcode: $LATEST_XCODE..."
  xcodes install --latest --experimental-unxip || error_msg "Failed to install Xcode."
  
  if [[ ! -d "/Applications/Xcode.app" ]]; then
    error_msg "Xcode installation failed or is incomplete. Please check manually."
  fi

  # Remove old Xcode versions safely
  mapfile -t OLD_XCODES < <(xcodes installed | grep -Eo '^[0-9]+\.[0-9]+(\.[0-9]+)?' | grep -v "$LATEST_XCODE")
  for OLD_XCODE in "${OLD_XCODES[@]}"; do
    info_msg "Removing old Xcode version: $OLD_XCODE"
    xcodes uninstall "$OLD_XCODE" || warn_msg "Failed to remove Xcode $OLD_XCODE. Manual cleanup may be needed."
  done
fi

# Ensure latest iOS Runtime is known
LATEST_RUNTIME=$(xcodes runtimes list | grep -E '^iOS ' | grep -v 'beta' | tail -n1 | awk '{print $1, $2}')
if [[ -z "$LATEST_RUNTIME" ]]; then
  warn_msg "No valid iOS runtimes found. Skipping installation."
else
  if xcodes runtimes list --installed | grep -q "$LATEST_RUNTIME"; then
    info_msg "Latest iOS Simulator Runtime ($LATEST_RUNTIME) is already installed. Skipping."
  else
    info_msg "Installing latest iOS Simulator Runtime: $LATEST_RUNTIME..."
    xcodes runtimes install "$LATEST_RUNTIME" || error_msg "Failed to install iOS Simulator Runtime."
  fi
  
  # Remove old iOS Simulator runtimes
  info_msg "Removing outdated iOS Simulator runtimes..."
  mapfile -t OLD_RUNTIMES < <(xcodes runtimes list --installed | grep -E '^iOS ' | grep -v "$LATEST_RUNTIME")
  for OLD_RUNTIME in "${OLD_RUNTIMES[@]}"; do
    info_msg "Removing old iOS runtime: $OLD_RUNTIME"
    xcodes runtimes uninstall "$OLD_RUNTIME" || warn_msg "Failed to remove iOS runtime $OLD_RUNTIME. Manual cleanup may be needed."
  done
fi

info_msg "Setup complete! Xcode and iOS Simulator are up to date."

