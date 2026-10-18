#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/mooseware"
TARGET_BIN_DIR="$TARGET_DIR/bin"
TARGET_ALIASES_DIR="$TARGET_DIR/aliases.d"

USE_LINKS=false
for arg in "$@"; do
    if [ "$arg" == "--use-links" ]; then
        USE_LINKS=true
    fi
done

if [ "$USE_LINKS" = false ] && [ -L "$TARGET_DIR/alias-manager.sh" ]; then
    USE_LINKS=true
    echo "🦌 Detected previous symlink installation. Auto-enabling --use-links..."
fi

echo "🦌 Installing Moosetilities Timewarrior Integrations..."

mkdir -p "$TARGET_BIN_DIR"
mkdir -p "$TARGET_ALIASES_DIR"

# 1. Install helper scripts to ~/.config/mooseware/bin/
echo "Processing Timewarrior scripts..."
for script in "$REPO_DIR/scripts"/*; do
    if [ -f "$script" ]; then
        base=$(basename "$script")
        dest="$TARGET_BIN_DIR/$base"
        if [ "$USE_LINKS" = true ]; then
            ln -sf "$script" "$dest"
            echo "  -> $base (linked)"
        else
            [ -L "$dest" ] && rm -f "$dest"
            cp "$script" "$dest"
            chmod +x "$dest"
            echo "  -> $base (copied)"
        fi
    fi
done

# 2. Install alias files to ~/.config/mooseware/aliases.d/
echo "Processing Timewarrior aliases..."
for f in "$REPO_DIR/aliases"/*.sh; do
    if [ -f "$f" ]; then
        base=$(basename "$f")
        dest="$TARGET_ALIASES_DIR/$base"
        if [ "$USE_LINKS" = true ]; then
            if [ -L "$dest" ]; then
                current_target=$(readlink "$dest")
                if [ "$current_target" == "$f" ]; then
                    echo "  -> $base (already correctly linked)"
                else
                    echo "  -> $base (skipped, symlink points to a different location)"
                fi
            elif [ -e "$dest" ]; then
                echo "  -> $base (skipped, physical file already exists)"
            else
                ln -sf "$f" "$dest"
                echo "  -> $base (linked)"
            fi
        else
            if [ -L "$dest" ]; then
                current_target=$(readlink "$dest")
                if [ "$current_target" == "$f" ]; then
                    rm -f "$dest"
                    cp "$f" "$dest"
                    echo "  -> $base (replaced symlink with copy)"
                else
                    echo "  -> $base (skipped, symlink points to a different location)"
                fi
            elif [ -e "$dest" ]; then
                echo "  -> $base (skipped, physical file already exists)"
            else
                cp "$f" "$dest"
                echo "  -> $base (copied)"
            fi
        fi
    fi
done

echo ""
echo "✨ Timewarrior integrations installed! ✨"
