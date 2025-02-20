#!/bin/bash

# Application name and path
APP_NAME="Logi Options+"
APP_PATH="/Applications/Logi Options+.app"
ZIP_URL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"

# Check if the application is already installed
if [ -d "$APP_PATH" ]; then
    echo "$APP_NAME is already installed. Skipping installation."
    exit 0
fi

# Create a temporary directory
TMP_DIR=$(mktemp -d)
ZIP_PATH="$TMP_DIR/logioptionsplus_installer.zip"

# Download the ZIP file
echo "Downloading $APP_NAME..."
curl -L "$ZIP_URL" -o "$ZIP_PATH"

# Unzip the installer
echo "Extracting installer..."
unzip -q "$ZIP_PATH" -d "$TMP_DIR"

# Find the .pkg file
PKG_FILE=$(find "$TMP_DIR" -name "*.pkg" | head -n 1)

if [ -z "$PKG_FILE" ]; then
    echo "Error: No .pkg file found in the extracted ZIP."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Install the package
echo "Installing $APP_NAME..."
sudo installer -pkg "$PKG_FILE" -target /

# Clean up
rm -rf "$TMP_DIR"

echo "$APP_NAME has been successfully installed."

