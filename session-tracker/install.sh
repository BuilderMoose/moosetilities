#!/bin/bash
set -e

# Get the absolute path of the directory containing this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create directories
mkdir -p "$HOME/.config/mooseware/logs"
mkdir -p "$HOME/.config/mooseware/bin"

if [ "$(uname)" = "Darwin" ]; then
    echo "Detected macOS. Installing LaunchAgent..."
    
    # Paths
    PLIST_TEMPLATE="$DIR/mac/com.user.sessiontracker.plist"
    PLIST_DEST="$HOME/Library/LaunchAgents/com.user.sessiontracker.plist"
    SWIFT_SOURCE="$DIR/mac/SessionTracker.swift"
    BINARY_DEST="$HOME/.config/mooseware/bin/SessionTracker"
    
    # Ensure LaunchAgents directory exists
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # Unload existing service before rebuilding binary
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    
    echo "Compiling SessionTracker.swift..."
    swiftc "$SWIFT_SOURCE" -O -o "$BINARY_DEST"
    chmod +x "$BINARY_DEST"
    
    # Generate the plist with the compiled binary path
    sed "s|{{BINARY_PATH}}|$BINARY_DEST|g" "$PLIST_TEMPLATE" > "$PLIST_DEST"
    
    # Start the service
    launchctl load "$PLIST_DEST"
    
    echo "macOS Session Tracker compiled, installed, and running!"
    echo "Logs are being written to ~/.config/mooseware/logs/"
    
elif [ "$(uname)" = "Linux" ]; then
    echo "Detected Linux. Installing systemd user service..."
    
    # Paths
    SCRIPT_SOURCE="$DIR/linux/time_tracker.sh"
    SCRIPT_DEST="$HOME/.config/mooseware/bin/time_tracker.sh"
    SERVICE_SOURCE="$DIR/linux/session-tracker.service"
    SERVICE_DIR="$HOME/.config/systemd/user"
    SERVICE_DEST="$SERVICE_DIR/session-tracker.service"
    
    mkdir -p "$SERVICE_DIR"
    
    # Install tracking script
    cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
    chmod +x "$SCRIPT_DEST"
    
    # Install and start systemd user service
    cp "$SERVICE_SOURCE" "$SERVICE_DEST"
    systemctl --user daemon-reload
    systemctl --user enable --now session-tracker.service
    systemctl --user restart session-tracker.service
    
    echo "Linux Session Tracker installed and running!"
    echo "Logs are being written to ~/.config/mooseware/logs/"
else
    echo "Unsupported Operating System."
fi
