#!/bin/bash

# Configuration: Application name and download URL
APP_NAME="Logi Options+"
APP_URL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
APP_PATH="/Applications/$APP_NAME.app"

# Check if the application is already installed
if [ -d "$APP_PATH" ]; then
    echo "$APP_NAME is already installed. Skipping installation."
    exit 0
fi

# Create a temporary directory for downloading and extracting
TMP_DIR=$(mktemp -d)
FILE_PATH="$TMP_DIR/$(basename "$APP_URL")"

# Download the file
echo "Downloading $APP_NAME..."
curl -L "$APP_URL" -o "$FILE_PATH"

# Determine file type
FILE_TYPE=$(file --mime-type -b "$FILE_PATH")

case "$FILE_TYPE" in
    application/x-apple-diskimage)
        echo "Detected DMG file. Processing..."
        MOUNT_POINT=$(hdiutil attach "$FILE_PATH" -nobrowse | grep "/Volumes" | awk '{print $3}')
        APP_FOUND=$(find "$MOUNT_POINT" -maxdepth 1 -name "*.app" | head -n 1)
        if [ -n "$APP_FOUND" ]; then
            echo "Installing application..."
            cp -R "$APP_FOUND" /Applications/
        else
            echo "Error: No .app file found in DMG."
        fi
        hdiutil detach "$MOUNT_POINT"
        ;;
    
    application/zip)
        echo "Detected ZIP file. Extracting..."
        unzip -q "$FILE_PATH" -d "$TMP_DIR"
        APP_FOUND=$(find "$TMP_DIR" -name "*.app" | head -n 1)
        PKG_FOUND=$(find "$TMP_DIR" -name "*.pkg" | head -n 1)
        
        if [ -n "$APP_FOUND" ]; then
            echo "Installing application..."
            cp -R "$APP_FOUND" /Applications/
        elif [ -n "$PKG_FOUND" ]; then
            echo "Installing package..."
            sudo installer -pkg "$PKG_FOUND" -target /
        else
            echo "Error: No .app or .pkg file found in ZIP."
        fi
        ;;
    
    application/x-xar | application/octet-stream)
        echo "Detected PKG file. Installing..."
        sudo installer -pkg "$FILE_PATH" -target /
        ;;
    
    *)
        echo "Unsupported file type: $FILE_TYPE"
        ;;
esac

# Clean up temporary files
rm -rf "$TMP_DIR"
echo "$APP_NAME installation completed."

