#!/usr/bin/env bash
set -e

TARGET_DIR="$HOME/.config/mooseware"
TARGET_ALIASES_DIR="$TARGET_DIR/aliases.d"

echo "🦌 Uninstalling Moosetilities Alias Manager..."

if [ -f "$TARGET_DIR/alias-manager.sh" ] || [ -L "$TARGET_DIR/alias-manager.sh" ]; then
    echo "Removing alias-manager.sh core engine..."
    rm -f "$TARGET_DIR/alias-manager.sh"
fi

if [ -d "$TARGET_ALIASES_DIR" ]; then
    echo "Notice: Leaving your personal alias files safely intact in $TARGET_ALIASES_DIR"
fi

echo ""
echo "✨ Uninstallation complete! ✨"
echo "Don't forget to remove the autoload snippet from your ~/.bashrc or ~/.zshrc."
