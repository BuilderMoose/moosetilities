#!/usr/bin/env bash
set -e

TARGET_DIR="$HOME/.config/mooseware"
TARGET_BIN_DIR="$TARGET_DIR/bin"
TARGET_ALIASES_DIR="$TARGET_DIR/aliases.d"

echo "🦌 Uninstalling Moosetilities Timewarrior Integrations..."

if [ -f "$TARGET_BIN_DIR/tw_sync.py" ] || [ -L "$TARGET_BIN_DIR/tw_sync.py" ]; then
    rm -f "$TARGET_BIN_DIR/tw_sync.py"
    echo "Removed $TARGET_BIN_DIR/tw_sync.py"
fi

if [ -d "$TARGET_ALIASES_DIR" ]; then
    echo "Notice: Leaving your personal alias files intact in $TARGET_ALIASES_DIR"
fi

echo "✨ Timewarrior uninstallation complete! ✨"
