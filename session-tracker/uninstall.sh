#!/bin/bash

if [ "$(uname)" = "Darwin" ]; then
    echo "Detected macOS. Uninstalling LaunchAgent..."
    
    PLIST_DEST="$HOME/Library/LaunchAgents/com.user.sessiontracker.plist"
    
    if [ -f "$PLIST_DEST" ]; then
        # Unload the service
        launchctl unload "$PLIST_DEST" 2>/dev/null
        
        # Remove the plist
        rm "$PLIST_DEST"
        echo "macOS Session Tracker uninstalled successfully."
    else
        echo "Service plist not found at $PLIST_DEST. Is it already uninstalled?"
    fi
    
elif [ "$(uname)" = "Linux" ]; then
    echo "Linux uninstallation not yet implemented."
else
    echo "Unsupported Operating System."
fi
