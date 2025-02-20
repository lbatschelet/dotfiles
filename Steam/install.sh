#!/bin/bash

# Configuration: Application name and download URL
APP_NAME="Steam"
APP_URL="https://cdn.fastly.steamstatic.com/client/installer/steam.dmg"
APP_PATH="/Applications/$APP_NAME.app"


#!/bin/bash

################################################################################
# A robust, universal macOS installation script with colored logging.
#
# Supports:
#  - DMG
#  - PKG
#  - ZIP (might contain .app, .pkg, or a .dmg)
#  - .app files (directly or containing an internal installer)
#
# Checks first if the app is installed; if yes, skips downloading altogether.
################################################################################

set -euo pipefail  # Stop on error, treat unset vars as errors, fail on pipeline errors

################################################################################
# CONFIGURATION
################################################################################
APP_NAME="Steam"
APP_URL="https://cdn.fastly.steamstatic.com/client/installer/steam.dmg"
readonly APP_PATH="/Applications/${APP_NAME}.app"

################################################################################
# COLORS
################################################################################
COLOR_RESET="\033[0m"
COLOR_INFO="\033[1;34m"     # Bold Blue
COLOR_WARN="\033[1;33m"     # Bold Yellow
COLOR_ERROR="\033[1;31m"    # Bold Red

info_msg()  { echo -e "${COLOR_INFO}[INFO] $*${COLOR_RESET}"; }
warn_msg()  { echo -e "${COLOR_WARN}[WARN] $*${COLOR_RESET}"; }
error_msg() { echo -e "${COLOR_ERROR}[ERROR] $*${COLOR_RESET}"; }

################################################################################
# GLOBALS & TRAPS
################################################################################
TMP_DIR=""

cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    info_msg "Cleaning up temporary files..."
    rm -rf "$TMP_DIR"
  fi
}

on_error() {
  local exit_code="$?"
  local last_command="$BASH_COMMAND"
  error_msg "Command '$last_command' failed with exit code $exit_code."
  warn_msg "You may need to install $APP_NAME manually."
  cleanup
  exit "$exit_code"
}

on_exit() {
  # This is called on normal exit or after on_error().
  cleanup
}

trap on_error ERR
trap on_exit EXIT

################################################################################
# 1) EARLY-EXIT IF ALREADY INSTALLED
################################################################################
if [[ -d "$APP_PATH" ]]; then
  info_msg "$APP_NAME is already installed at $APP_PATH. Skipping installation."
  exit 0
fi

################################################################################
# 2) ENVIRONMENT CHECKS
################################################################################

# 2A) Verify macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  error_msg "This script only supports macOS."
  exit 1
fi

# 2B) Required tools check
REQUIRED_TOOLS=(curl unzip hdiutil defaults installer)
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    error_msg "'$tool' is required but not installed or not in PATH."
    exit 1
  fi
done

################################################################################
# 3) UTILITY FUNCTIONS
################################################################################

install_pkg() {
  local pkg_file="$1"
  info_msg "Installing package: $pkg_file"
  if [[ $EUID -ne 0 ]]; then
    sudo installer -pkg "$pkg_file" -target /
  else
    installer -pkg "$pkg_file" -target /
  fi
}

install_app() {
  local app_dir="$1"
  info_msg "Copying .app to /Applications: $app_dir"
  cp -R "$app_dir" /Applications/
}

move_app() {
  local app_dir="$1"
  info_msg "Moving .app to /Applications: $app_dir"
  mv "$app_dir" /Applications/
}

get_cf_bundle_executable() {
  local app_dir="$1"
  local plist_file="$app_dir/Contents/Info.plist"
  if [[ -f "$plist_file" ]]; then
    defaults read "${plist_file%.plist}" CFBundleExecutable 2>/dev/null || true
  else
    echo ""
  fi
}

run_app_installer() {
  local app_dir="$1"

  local exe_name
  exe_name="$(get_cf_bundle_executable "$app_dir")"
  if [[ -n "$exe_name" ]]; then
    local installer_path="$app_dir/Contents/MacOS/$exe_name"
    if [[ -x "$installer_path" ]]; then
      info_msg "Running .app internal installer: $installer_path"
      "$installer_path"
      return
    fi
  fi

  # Fallback: largest executable in Contents/MacOS
  local -a installers
  mapfile -t installers < <(find "$app_dir/Contents/MacOS" -type f -perm +111 2>/dev/null || true)
  if [[ ${#installers[@]} -eq 0 ]]; then
    warn_msg "No executables found in $app_dir/Contents/MacOS. Attempting to install .app to /Applications."
    move_app "$app_dir"
    return
  fi
  if [[ ${#installers[@]} -eq 1 ]]; then
    info_msg "Running single discovered installer: ${installers[0]}"
    "${installers[0]}"
  else
    local biggest_installer
    biggest_installer="$(ls -S "${installers[@]}" | head -n 1)"
    info_msg "Multiple executables found. Running largest: $biggest_installer"
    "$biggest_installer"
  fi
}

handle_dmg() {
  local dmg_file="$1"
  info_msg "Detected DMG file. Mounting..."
  local mount_point
  mount_point="$(hdiutil attach "$dmg_file" -nobrowse | grep "/Volumes" | awk '{print $3}')"

  if [[ -z "$mount_point" ]]; then
    error_msg "Could not mount DMG: $dmg_file"
    exit 1
  fi

  local dmg_app
  dmg_app="$(find "$mount_point" -maxdepth 1 -type d -name "*.app" | head -n 1)"
  local dmg_pkg
  dmg_pkg="$(find "$mount_point" -maxdepth 1 -type f -name "*.pkg" | head -n 1)"

  if [[ -n "$dmg_app" ]]; then
    info_msg "Installing .app from DMG"
    install_app "$dmg_app"
  elif [[ -n "$dmg_pkg" ]]; then
    info_msg "Installing .pkg from DMG"
    install_pkg "$dmg_pkg"
  else
    error_msg "No .app or .pkg found in DMG"
    hdiutil detach "$mount_point"
    exit 1
  fi

  info_msg "Detaching DMG..."
  hdiutil detach "$mount_point"
}

handle_zip() {
  local zip_file="$1"
  local tmp_dir="$2"

  info_msg "Detected ZIP file. Extracting..."
  unzip -q "$zip_file" -d "$tmp_dir"

  local found_app
  found_app="$(find "$tmp_dir" -type d -name "*.app" | head -n 1)"
  local found_pkg
  found_pkg="$(find "$tmp_dir" -type f -name "*.pkg" | head -n 1)"
  local found_dmg
  found_dmg="$(find "$tmp_dir" -type f -name "*.dmg" | head -n 1)"

  if [[ -n "$found_app" ]]; then
    info_msg "Found .app in ZIP"
    run_app_installer "$found_app"
  elif [[ -n "$found_pkg" ]]; then
    info_msg "Found .pkg in ZIP"
    install_pkg "$found_pkg"
  elif [[ -n "$found_dmg" ]]; then
    info_msg "Found .dmg in ZIP"
    handle_dmg "$found_dmg"
  else
    error_msg "No .app, .pkg, or .dmg found in the ZIP."
    exit 1
  fi
}

################################################################################
# 4) MAIN LOGIC
################################################################################

# 4A) Create temporary directory & download
TMP_DIR="$(mktemp -d)"
FILE_PATH="$TMP_DIR/$(basename "$APP_URL")"

info_msg "Downloading $APP_NAME from $APP_URL ..."
curl -fSL "$APP_URL" -o "$FILE_PATH"

# 4B) Decide how to handle based on extension
EXT="${FILE_PATH##*.}"
EXT_LOWER="$(echo "$EXT" | tr '[:upper:]' '[:lower:]')"

case "$EXT_LOWER" in
  dmg)
    handle_dmg "$FILE_PATH"
    ;;
  pkg)
    info_msg "Detected PKG file"
    install_pkg "$FILE_PATH"
    ;;
  zip)
    handle_zip "$FILE_PATH" "$TMP_DIR"
    ;;
  app)
    info_msg "Detected .app file"
    run_app_installer "$FILE_PATH"
    ;;
  *)
    warn_msg "Unrecognized file extension: $EXT_LOWER. Trying MIME detection..."
    FILE_TYPE="$(file --mime-type -b "$FILE_PATH")"
    case "$FILE_TYPE" in
      application/x-apple-diskimage)
        handle_dmg "$FILE_PATH"
        ;;
      application/zip)
        handle_zip "$FILE_PATH" "$TMP_DIR"
        ;;
      application/x-xar|application/octet-stream)
        info_msg "Treating as PKG"
        install_pkg "$FILE_PATH"
        ;;
      *)
        error_msg "Unsupported file type: $FILE_TYPE"
        exit 1
        ;;
    esac
    ;;
esac

info_msg "$APP_NAME installation completed successfully!"

