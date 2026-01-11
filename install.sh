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

# Function to backup and symlink
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

# Install zsh configs
echo -e "\n=== Installing zsh configuration ==="
backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
backup_and_link "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"

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

# Install iTerm2 config
echo -e "\n=== Installing iTerm2 configuration ==="
if [ -f "$DOTFILES_DIR/config/iterm2/com.googlecode.iterm2.plist" ]; then
    # Convert XML plist back to binary and install
    echo "Converting iTerm2 plist to binary format"
    plutil -convert binary1 "$DOTFILES_DIR/config/iterm2/com.googlecode.iterm2.plist" -o /tmp/com.googlecode.iterm2.plist

    if [ -f "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]; then
        echo "Backing up existing iTerm2 preferences"
        cp "$HOME/Library/Preferences/com.googlecode.iterm2.plist" "$BACKUP_DIR/"
    fi

    cp /tmp/com.googlecode.iterm2.plist "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    rm /tmp/com.googlecode.iterm2.plist
    echo "iTerm2 preferences installed (restart iTerm2 to apply)"
fi

# Install uv config
echo -e "\n=== Installing uv configuration ==="
backup_and_link "$DOTFILES_DIR/config/uv/uv-receipt.json" "$HOME/.config/uv/uv-receipt.json"

echo -e "\n=== Installation complete! ==="
echo "Backups are stored in: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Restart iTerm2 if you use it"
echo "  3. Review any backed up files in $BACKUP_DIR"
