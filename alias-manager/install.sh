#!/usr/bin/env bash
set -e

# Resolve the absolute path to this script's directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/bash"
TARGET_ALIASES_DIR="$TARGET_DIR/aliases.d"

echo "🦌 Installing Moosetilities Alias Manager..."

# Create the target directory structure
mkdir -p "$TARGET_ALIASES_DIR"

# Clean existing symlinks/files in the target aliases directory to remove dead links
echo "Cleaning old aliases in $TARGET_ALIASES_DIR..."
rm -f "$TARGET_ALIASES_DIR"/*.sh

# Symlink the core alias-manager.sh script
echo "Linking alias-manager.sh..."
ln -sf "$REPO_DIR/alias-manager.sh" "$TARGET_DIR/alias-manager.sh"

# Symlink all alias files
echo "Linking alias groups..."
for f in "$REPO_DIR/aliases.d"/*.sh; do
    if [ -f "$f" ]; then
        ln -sf "$f" "$TARGET_ALIASES_DIR/$(basename "$f")"
        echo "  -> $(basename "$f")"
    fi
done

echo ""
echo "✨ Installation complete! ✨"
echo "Make sure to add the autoload snippet to your ~/.bashrc or ~/.zshrc."
