#!/bin/bash

if [ "$(uname)" = "Darwin" ]; then
    echo "Detected macOS. Uninstalling LaunchAgent..."
    
    PLIST_DEST="$HOME/Library/LaunchAgents/com.user.sessiontracker.plist"
    
    if [ -f "$PLIST_DEST" ]; then
        # Unload the service
        launchctl unload "$PLIST_DEST" 2>/dev/null
        
        # Remove the plist and compiled binary
        rm -f "$PLIST_DEST"
        rm -f "$HOME/.config/mooseware/bin/SessionTracker"
        echo "macOS Session Tracker uninstalled successfully."
    else
        echo "Service plist not found at $PLIST_DEST. Is it already uninstalled?"
    fi
    
elif [ "$(uname)" = "Linux" ]; then
    echo "Detected Linux. Uninstalling systemd user service..."
    
    SERVICE_DEST="$HOME/.config/systemd/user/session-tracker.service"
    
    if [ -f "$SERVICE_DEST" ]; then
        systemctl --user disable --now session-tracker.service 2>/dev/null || true
        rm -f "$SERVICE_DEST"
        systemctl --user daemon-reload
        rm -f "$HOME/.config/mooseware/bin/time_tracker.sh"
        echo "Linux Session Tracker uninstalled successfully."
    else
        echo "Service file not found at $SERVICE_DEST. Is it already uninstalled?"
    fi
else
    echo "Unsupported Operating System."
fi
