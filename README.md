# Dotfiles

Personal dotfiles configuration for consistent development environment across machines.

## Contents

This repository contains configuration files for:

- **Zsh**: Shell configuration with aliases, functions, and environment variables
  - `.zshrc` - Main zsh configuration
  - `.zprofile` - Login shell configuration
  - `.zshenv` - Environment variables

- **Git**: Version control configuration
  - `.gitconfig` - Git global configuration
  - `config/git/ignore` - Global gitignore patterns

- **SSH**: Secure shell configuration
  - `ssh/config` - SSH host configurations

- **GitHub CLI**: GitHub command-line tool settings
  - `config/gh/config.yml` - GitHub CLI preferences
  - `config/gh/hosts.yml` - GitHub hosts configuration

- **uv**: Python package manager configuration
  - `config/uv/uv-receipt.json` - uv installation receipt

## Installation

### Quick Install

Clone this repository and run the installation script:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The script will:
1. Backup your existing dotfiles to `~/.dotfiles_backup_TIMESTAMP`
2. Create local configuration files from templates (`.zshrc.local`, `.gitconfig.local`)
3. Create symlinks from your home directory to the dotfiles in this repo

### Required: Configure Personal Information

After installation, you **must** edit these files with your personal information:

1. **Git configuration**: Edit `~/.dotfiles/git/.gitconfig.local`
   ```bash
   # Replace with your actual name and email
   [user]
       name = Your Name
       email = your.email@example.com
   ```

2. **GitHub CLI** (optional): Either run `gh auth login` or copy and edit `config/gh/hosts.yml.example`

3. **Machine-specific settings** (optional): Edit `~/.dotfiles/zsh/.zshrc.local` for custom aliases or environment variables

### Manual Installation

If you prefer to install specific configurations manually:

```bash
# Zsh
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/.dotfiles/zsh/.zprofile ~/.zprofile
ln -s ~/.dotfiles/zsh/.zshenv ~/.zshenv

# Git
ln -s ~/.dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/config/git/ignore ~/.config/git/ignore

# SSH
ln -s ~/.dotfiles/ssh/config ~/.ssh/config

# GitHub CLI
ln -s ~/.dotfiles/config/gh/config.yml ~/.config/gh/config.yml
ln -s ~/.dotfiles/config/gh/hosts.yml ~/.config/gh/hosts.yml

# uv
ln -s ~/.dotfiles/config/uv/uv-receipt.json ~/.config/uv/uv-receipt.json
```

## Updating

To update your dotfiles:

```bash
cd ~/.dotfiles
git pull origin main
```

Since the files are symlinked, changes will take effect immediately.

## Customization

### Adding New Dotfiles

1. Copy the config file to the appropriate directory in this repo
2. Update `install.sh` to symlink the new file
3. Update this README with information about the new config
4. Commit and push changes

### Local Configuration Files

This repository uses local configuration files for sensitive/machine-specific information:

- **`zsh/.zshrc.local`**: Machine-specific shell configuration (gitignored)
- **`git/.gitconfig.local`**: Personal git user info (gitignored)
- **`config/gh/hosts.yml`**: GitHub CLI authentication (gitignored)

These files are automatically created from `.example` templates during installation. They remain in the dotfiles directory but are excluded from git commits.

### Keeping Secrets Safe

The following patterns are gitignored to protect sensitive information:
- All `.local` configuration files
- SSH private keys (`*_rsa`, `*_ed25519`, etc.)
- Environment files (`.env`, `.env.local`)
- GitHub CLI authentication (`config/gh/hosts.yml`)

Never commit API keys, tokens, or passwords to this repository.

## Repository Structure

```
dotfiles/
├── config/
│   ├── gh/              # GitHub CLI configuration
│   ├── git/             # Git extended configuration
│   └── uv/              # uv Python package manager
├── git/
│   └── .gitconfig       # Git global configuration
├── ssh/
│   └── config           # SSH client configuration
├── zsh/
│   ├── .zshrc           # Zsh configuration
│   ├── .zprofile        # Zsh login shell config
│   └── .zshenv          # Zsh environment variables
├── install.sh           # Installation script
└── README.md            # This file
```

## Syncing Dotfiles Across Machines

### Initial Setup on New Machine

1. Install prerequisites (git, zsh, etc.)
2. Clone this repository
3. Run `./install.sh`
4. Restart your terminal

### Pushing Changes from One Machine

When you make changes to your dotfiles on one machine:

```bash
cd ~/.dotfiles
git add -A
git commit -m "Update configuration"
git push origin main
```

### Pulling Changes on Other Machines

On your other machines:

```bash
cd ~/.dotfiles
git pull origin main
source ~/.zshrc  # Reload shell config
```

## Uninstallation

To remove symlinks and restore backups:

```bash
# Find your backup directory
ls -d ~/.dotfiles_backup_*

# Remove symlinks and restore from backup
rm ~/.zshrc ~/.zprofile ~/.zshenv ~/.gitconfig
cp ~/.dotfiles_backup_TIMESTAMP/* ~/
```

## License

Free to use and modify for personal use.
