#!/bin/bash

# Check if 'mas' is installed
if ! command -v mas &> /dev/null; then
    echo "'mas' is not installed. Please install it first via 'brew install mas'."
    exit 1
fi

# List of Mac App Store applications
APPS=(
    "1118136179  AutoMute"
    "1532597159  mp3tag"
    "1475387142  Tailscale"
    "1503446680  PastePal"
    "937984704   Amphetamine"
    "1534275760  LanguageTool"
    "363738376   ForScore"
    "985367838   Outlook"
    "462054704   Word"
    "462058435   Excel"
    "462062816   PowerPoint"
    "823766827   OneDrive"
    "1355679052  Dropover"
    "497799835   Xcode"
)

# Track whether at least one app needs installation
INSTALL_NEEDED=false

# Iterate through the app list
for APP in "${APPS[@]}"; do
    APP_ID=$(echo "$APP" | awk '{print $1}')
    APP_NAME=$(echo "$APP" | cut -d' ' -f2-)

    # Check if the app is already installed
    if mas list | awk '{print $1}' | grep -q "^$APP_ID$"; then
        continue  # Skip already installed apps
    fi

    # If at least one app needs installation, set flag
    INSTALL_NEEDED=true

    # Install the app
    echo "Installing $APP_NAME..."
    mas install "$APP_ID"
done

# Print final message
if [ "$INSTALL_NEEDED" = false ]; then
    echo "All listed Mac App Store apps are already installed. Nothing to do."
fi

