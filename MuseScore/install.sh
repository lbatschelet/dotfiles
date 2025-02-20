#!/bin/bash

# URL zur DMG-Datei
APP_URL="https://muse-cdn.com/Muse_Hub.dmg"
APP_NAME="Muse Hub"

# Temporäres Verzeichnis für Download
TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/Muse_Hub.dmg"

# Herunterladen der DMG-Datei
curl -L "$APP_URL" -o "$DMG_PATH"

# DMG mounten
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse | grep "/Volumes" | awk '{print $3}')

# App in den Applications-Ordner kopieren
cp -R "$MOUNT_POINT/$APP_NAME.app" /Applications/

# DMG unmounten und aufräumen
hdiutil detach "$MOUNT_POINT"
rm -rf "$TMP_DIR"

echo "$APP_NAME wurde erfolgreich installiert."

