#!/usr/bin/env bash

# Dotfiles Installation Script
# This script creates symlinks from your home directory to the dotfiles in this repo

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo "Backups will be stored in $BACKUP_DIR"

# Copy local configuration examples if they don't exist
echo -e "\n=== Setting up local configuration files ==="

if [ ! -f "$DOTFILES_DIR/zsh/.zshrc.local" ]; then
    echo "Creating zsh/.zshrc.local from example"
    cp "$DOTFILES_DIR/zsh/.zshrc.local.example" "$DOTFILES_DIR/zsh/.zshrc.local"
    echo "  → Edit $DOTFILES_DIR/zsh/.zshrc.local to add machine-specific configuration"
else
    echo "  → zsh/.zshrc.local already exists, skipping"
fi

if [ ! -f "$DOTFILES_DIR/git/.gitconfig.local" ]; then
    echo "Creating git/.gitconfig.local from example"
    cp "$DOTFILES_DIR/git/.gitconfig.local.example" "$DOTFILES_DIR/git/.gitconfig.local"
    echo "  → IMPORTANT: Edit $DOTFILES_DIR/git/.gitconfig.local with your name and email"
else
    echo "  → git/.gitconfig.local already exists, skipping"
fi

# Function to backup and symlink (for config files)
backup_and_link() {
    local source="$1"
    local target="$2"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"

    # Backup existing file/directory if it exists and is not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Backing up existing $target"
        backup_path="$BACKUP_DIR$(dirname "$target")"
        mkdir -p "$backup_path"
        mv "$target" "$backup_path/"
    fi

    # Remove existing symlink if present
    if [ -L "$target" ]; then
        rm "$target"
    fi

    # Create symlink
    echo "Linking $source -> $target"
    ln -s "$source" "$target"
}

# Function to append source line if not already present (for shell configs)
append_source_if_needed() {
    local source_file="$1"
    local target_file="$2"
    local source_line="$3"

    # Create target file if it doesn't exist
    if [ ! -f "$target_file" ]; then
        echo "Creating $target_file"
        touch "$target_file"
    fi

    # Check if source line already exists
    if grep -Fq "$source_line" "$target_file"; then
        echo "  → $target_file already sources dotfiles, skipping"
    else
        echo "Adding source line to $target_file"
        echo "" >> "$target_file"
        echo "# Source dotfiles configuration" >> "$target_file"
        echo "$source_line" >> "$target_file"
    fi
}

# Function to append Include directive for SSH config
append_include_if_needed() {
    local include_file="$1"
    local target_file="$2"
    local include_line="$3"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target_file")"

    # Set correct permissions on ~/.ssh directory
    # SSH requires 700 (drwx------) or it will ignore configs
    chmod 700 "$(dirname "$target_file")" 2>/dev/null || true

    # Create target file if it doesn't exist
    if [ ! -f "$target_file" ]; then
        echo "Creating $target_file"
        touch "$target_file"
    fi

    # Check if Include line already exists
    if grep -Fq "$include_line" "$target_file"; then
        echo "  → $target_file already includes dotfiles, skipping"
    else
        echo "Adding Include directive to $target_file"
        echo "" >> "$target_file"
        echo "# Include dotfiles SSH configuration (defaults)" >> "$target_file"
        echo "$include_line" >> "$target_file"
    fi

    # Set correct permissions on SSH config file
    # SSH requires 600 (or at least not group/world writable) or it will ignore the file
    chmod 600 "$target_file" 2>/dev/null || true
}

# Install zsh configs
echo -e "\n=== Installing zsh configuration ==="
append_source_if_needed "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" "[ -f \"$DOTFILES_DIR/zsh/.zshrc\" ] && source \"$DOTFILES_DIR/zsh/.zshrc\""
append_source_if_needed "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv" "[ -f \"$DOTFILES_DIR/zsh/.zshenv\" ] && source \"$DOTFILES_DIR/zsh/.zshenv\""

# Install git configs
echo -e "\n=== Installing git configuration ==="

# For .gitconfig, we append an include directive rather than replacing the file
# This preserves any existing git configuration the user may have
if [ ! -f "$HOME/.gitconfig" ]; then
    echo "Creating $HOME/.gitconfig"
    touch "$HOME/.gitconfig"
fi

# Check if our dotfiles are already included
if git config -f "$HOME/.gitconfig" --get-regexp 'include\.path' | grep -q "$DOTFILES_DIR/git/.gitconfig"; then
    echo "  → $HOME/.gitconfig already includes dotfiles, skipping"
else
    echo "Adding dotfiles include to $HOME/.gitconfig"
    echo "" >> "$HOME/.gitconfig"
    echo "# Include dotfiles git configuration" >> "$HOME/.gitconfig"
    echo "[include]" >> "$HOME/.gitconfig"
    echo "	path = \"$DOTFILES_DIR/git/.gitconfig\"" >> "$HOME/.gitconfig"
fi

backup_and_link "$DOTFILES_DIR/config/git/ignore" "$HOME/.config/git/ignore"

# Install SSH config
echo -e "\n=== Installing SSH configuration ==="
# Note: SSH Include directive does not support quoted paths, so dotfiles directory must not contain spaces
append_include_if_needed "$DOTFILES_DIR/ssh/defaults" "$HOME/.ssh/config" "Include $DOTFILES_DIR/ssh/defaults"

# Install GitHub CLI config
echo -e "\n=== Installing GitHub CLI configuration ==="
backup_and_link "$DOTFILES_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml"
echo "  → Run 'gh auth login' to set up GitHub CLI authentication"

echo -e "\n=== Installation complete! ==="
echo "Backups are stored in: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Review any backed up files in $BACKUP_DIR"
