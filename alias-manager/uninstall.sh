#!/usr/bin/env bash
set -e

TARGET_DIR="$HOME/.config/bash"
TARGET_ALIASES_DIR="$TARGET_DIR/aliases.d"

echo "🦌 Uninstalling Moosetilities Alias Manager..."

# Remove symlinks
if [ -d "$TARGET_ALIASES_DIR" ]; then
    echo "Removing linked alias groups..."
    rm -f "$TARGET_ALIASES_DIR"/*.sh
    # Optionally remove directory if empty
    rmdir "$TARGET_ALIASES_DIR" 2>/dev/null || true
fi

if [ -f "$TARGET_DIR/alias-manager.sh" ]; then
    echo "Removing alias-manager.sh link..."
    rm -f "$TARGET_DIR/alias-manager.sh"
    rmdir "$TARGET_DIR" 2>/dev/null || true
fi

echo ""
echo "✨ Uninstallation complete! ✨"
echo "Don't forget to remove the autoload snippet from your ~/.bashrc or ~/.zshrc."
