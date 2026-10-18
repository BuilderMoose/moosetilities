#!/usr/bin/env bash
set -e

# ==============================================================================
# DESIGN PHILOSOPHY & INSTALLATION MODES
# ==============================================================================
# This installer operates safely to protect the user's custom environment, 
# while still allowing developers to keep their aliases version-controlled.
#
# 1. Copy Mode (Default): 
#    Copies the repository files into ~/.config/mooseware/aliases.d/ so the user can
#    edit them freely without accidentally committing changes to the git repo.
#    - SAFETY: Will NOT overwrite existing physical files (protects user edits).
#    - UPGRADE: Will safely replace existing symlinks with physical copies.
#
# 2. Symlink Mode (--use-links or auto-detected):
#    Creates symlinks pointing back to this repository, ideal for forks.
#    - AUTO-DETECT: If the core script is already a symlink, it assumes this mode.
#    - SAFETY: Will NOT overwrite a symlink that points to an unknown location.
#    - SAFETY: Will NOT overwrite a user's physical file with a symlink.
# ==============================================================================

# Resolve the absolute path to this script's directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config/mooseware"
TARGET_ALIASES_DIR="$TARGET_DIR/aliases.d"

# Parse arguments and detect past state
USE_LINKS=false
for arg in "$@"; do
    if [ "$arg" == "--use-links" ]; then
        USE_LINKS=true
    fi
done

# Auto-detect symlink mode from previous installs
if [ "$USE_LINKS" = false ] && [ -L "$TARGET_DIR/alias-manager.sh" ]; then
    USE_LINKS=true
    echo "🦌 Detected previous symlink installation. Auto-enabling --use-links..."
fi

echo "🦌 Installing Moosetilities Alias Manager..."

# Create the target directory structure
mkdir -p "$TARGET_ALIASES_DIR"

if [ "$USE_LINKS" = true ]; then
    echo "Mode: Symlinking (for development/forks)"
    
    # Handle the core engine
    echo "Processing alias-manager.sh..."
    if [ -L "$TARGET_DIR/alias-manager.sh" ]; then
        current_target=$(readlink "$TARGET_DIR/alias-manager.sh")
        if [ "$current_target" != "$REPO_DIR/alias-manager.sh" ]; then
            echo "  -> alias-manager.sh (WARNING: Existing symlink points elsewhere. Replacing it with our repo link.)"
            rm -f "$TARGET_DIR/alias-manager.sh"
            ln -sf "$REPO_DIR/alias-manager.sh" "$TARGET_DIR/alias-manager.sh"
        else
            echo "  -> alias-manager.sh (already correctly linked)"
        fi
    elif [ -e "$TARGET_DIR/alias-manager.sh" ]; then
        echo "  -> alias-manager.sh (WARNING: Existing file found. Replacing it with a symlink.)"
        rm -f "$TARGET_DIR/alias-manager.sh"
        ln -sf "$REPO_DIR/alias-manager.sh" "$TARGET_DIR/alias-manager.sh"
    else
        ln -sf "$REPO_DIR/alias-manager.sh" "$TARGET_DIR/alias-manager.sh"
        echo "  -> alias-manager.sh (linked)"
    fi

    echo "Processing alias groups..."
    for f in "$REPO_DIR/aliases.d"/*.sh; do
        if [ -f "$f" ]; then
            base=$(basename "$f")
            dest="$TARGET_ALIASES_DIR/$base"
            
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
        fi
    done
else
    echo "Mode: Copying (safe edits in $TARGET_ALIASES_DIR)"
    
    echo "Processing alias-manager.sh..."
    # If it's a symlink from a weird state, remove it
    [ -L "$TARGET_DIR/alias-manager.sh" ] && rm -f "$TARGET_DIR/alias-manager.sh"
    cp "$REPO_DIR/alias-manager.sh" "$TARGET_DIR/alias-manager.sh"
    echo "  -> alias-manager.sh (copied)"

    echo "Processing alias groups..."
    for f in "$REPO_DIR/aliases.d"/*.sh; do
        if [ -f "$f" ]; then
            base=$(basename "$f")
            dest="$TARGET_ALIASES_DIR/$base"
            
            if [ -L "$dest" ]; then
                current_target=$(readlink "$dest")
                if [ "$current_target" == "$f" ]; then
                    # It's an old symlink pointing to us, safe to replace with copy
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
    done
fi

echo ""
echo "✨ Installation complete! ✨"
echo "Make sure to add the autoload snippet to your ~/.bashrc or ~/.zshrc."
