#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/mooseware"
BIN_DIR="$CONFIG_DIR/bin"

echo "🦌 Welcome to the Moosetilities Setup!"
echo "Initializing master configuration directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$BIN_DIR"

# Run sub-installers
echo ""
echo "--- Installing Alias Manager ---"
if [ -x "$REPO_DIR/alias-manager/install.sh" ]; then
    "$REPO_DIR/alias-manager/install.sh" "$@"
else
    echo "Warning: Alias Manager installer not found or not executable."
fi

echo ""
echo "--- Installing Session Tracker ---"
if [ -x "$REPO_DIR/session-tracker/install.sh" ]; then
    "$REPO_DIR/session-tracker/install.sh" "$@"
else
    echo "Warning: Session Tracker installer not found or not executable."
fi

echo ""
echo "--- Installing Timewarrior Integrations ---"
if [ -x "$REPO_DIR/timewarrior/install.sh" ]; then
    "$REPO_DIR/timewarrior/install.sh" "$@"
else
    echo "Warning: Timewarrior installer not found or not executable."
fi

echo ""
echo "🎉 Moosetilities setup complete!"
echo "Drop your personal scripts into $CONFIG_DIR to customize your experience."
echo "Tip: You can add the bin directory to your PATH for easy command access:"
echo "     export PATH=\"\$HOME/.config/mooseware/bin:\$PATH\""
