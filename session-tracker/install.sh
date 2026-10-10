#!/bin/bash

# Get the absolute path of the directory containing this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create logs directory
mkdir -p "$HOME/scripts/logs"

if [ "$(uname)" = "Darwin" ]; then
    echo "Detected macOS. Installing LaunchAgent..."
    
    # Paths
    PLIST_TEMPLATE="$DIR/mac/com.user.sessiontracker.plist"
    PLIST_DEST="$HOME/Library/LaunchAgents/com.user.sessiontracker.plist"
    SWIFT_SCRIPT="$DIR/mac/SessionTracker.swift"
    
    # Ensure LaunchAgents directory exists
    mkdir -p "$HOME/Library/LaunchAgents"
    
    # Generate the plist with the correct absolute path
    # We use sed to replace the placeholder with the actual $SWIFT_SCRIPT path
    cat "$PLIST_TEMPLATE" | sed "s|{{SCRIPT_PATH}}|$SWIFT_SCRIPT|g" > "$PLIST_DEST"
    
    # Reload the service
    launchctl unload "$PLIST_DEST" 2>/dev/null
    launchctl load "$PLIST_DEST"
    
    echo "macOS Session Tracker installed and running!"
    echo "Logs are being written to ~/scripts/logs/"
    
elif [ "$(uname)" = "Linux" ]; then
    echo "Linux installation not yet implemented in this repository."
    # TODO: Add Linux systemd setup here
else
    echo "Unsupported Operating System."
fi
