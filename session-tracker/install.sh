#!/bin/bash
set -e

# Get the absolute path of the directory containing this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create directories
mkdir -p "$HOME/.config/mooseware/logs"
mkdir -p "$HOME/.config/mooseware/bin"

# Install helper scripts
echo "Installing helper scripts to $HOME/.config/mooseware/bin/..."
cp "$DIR/scripts/tw_sync.py" "$HOME/.config/mooseware/bin/tw_sync.py"
chmod +x "$HOME/.config/mooseware/bin/tw_sync.py"

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
    echo "Linux installation not yet implemented in this repository."
    # TODO: Add Linux systemd setup here
else
    echo "Unsupported Operating System."
fi
