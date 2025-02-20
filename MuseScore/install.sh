#!/bin/bash

# Application name and path
APP_NAME="Muse Hub"
APP_PATH="/Applications/$APP_NAME.app"
APP_URL="https://muse-cdn.com/Muse_Hub.dmg"

# Check if the application is already installed
if [ -d "$APP_PATH" ]; then
    echo "$APP_NAME is already installed. Skipping installation."
    exit 0
fi

# Temporary directory for download
TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/Muse_Hub.dmg"

# Download the DMG file
echo "Downloading $APP_NAME..."
curl -L "$APP_URL" -o "$DMG_PATH"

# Mount the DMG
echo "Mounting DMG..."
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse | grep "/Volumes" | awk '{print $3}')

# Copy the application to the Applications folder
echo "Installing $APP_NAME..."
cp -R "$MOUNT_POINT/$APP_NAME.app" /Applications/

# Unmount the DMG and clean up
echo "Unmounting DMG..."
hdiutil detach "$MOUNT_POINT"
rm -rf "$TMP_DIR"

echo "$APP_NAME has been successfully installed."

