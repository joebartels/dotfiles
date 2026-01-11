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

if [ ! -f "$DOTFILES_DIR/config/gh/hosts.yml" ]; then
    echo "GitHub CLI config not found"
    echo "  → Run 'gh auth login' after installation to set up GitHub CLI"
    echo "  → Or copy config/gh/hosts.yml.example to config/gh/hosts.yml and edit"
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
        mv "$target" "$BACKUP_DIR/"
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

# Install zsh configs
echo -e "\n=== Installing zsh configuration ==="
append_source_if_needed "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" "[ -f \"$DOTFILES_DIR/zsh/.zshrc\" ] && source \"$DOTFILES_DIR/zsh/.zshrc\""
append_source_if_needed "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile" "[ -f \"$DOTFILES_DIR/zsh/.zprofile\" ] && source \"$DOTFILES_DIR/zsh/.zprofile\""
append_source_if_needed "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv" "[ -f \"$DOTFILES_DIR/zsh/.zshenv\" ] && source \"$DOTFILES_DIR/zsh/.zshenv\""

# Install git configs
echo -e "\n=== Installing git configuration ==="
backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/config/git/ignore" "$HOME/.config/git/ignore"

# Install SSH config
echo -e "\n=== Installing SSH configuration ==="
backup_and_link "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# Install GitHub CLI config
echo -e "\n=== Installing GitHub CLI configuration ==="
backup_and_link "$DOTFILES_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml"
backup_and_link "$DOTFILES_DIR/config/gh/hosts.yml" "$HOME/.config/gh/hosts.yml"

# Install uv config
echo -e "\n=== Installing uv configuration ==="
backup_and_link "$DOTFILES_DIR/config/uv/uv-receipt.json" "$HOME/.config/uv/uv-receipt.json"

echo -e "\n=== Installation complete! ==="
echo "Backups are stored in: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Review any backed up files in $BACKUP_DIR"
